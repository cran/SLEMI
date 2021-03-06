#' Estimate mutual information between discrete input and continuous output
#'
#' The main wrapping function for basic usage of SLEMI package for estimation of mutual information. Firstly, data is pre-processed
#' (all arguments are checked, observation with NAs are removed, variables are scaled and centered (if scale=TRUE)). Then basic estimation is carried out
#' and (if testing=TRUE) diagnostic tests are computed. If output directory path is given (output_path is not NULL), graphs visualising the data and the analysis
#' are saved there, together with a compressed output object (as .rds file) with full estimation results.
#'
#' In a typical experiment aimed to quantify information flow a given signaling system, input values \eqn{x_1\leq x_2 \ldots... \leq x_m}, ranging from 0 to saturation are considered.
#' Then, for each input level, \eqn{x_i}, \eqn{n_i} observations are collected, which are represented as vectors 
#' \deqn{y^i_j \sim P(Y|X = x_i)}
#' Within information theory the degree of information transmission is measured as the mutual information
#' \deqn{MI(X,Y) = \sum_{i=1}^{m} P(x_i)\int_{R^k} P(y|X = x_i)log_2\frac{P(y|X = x_i)}{P(y)}dy,}
#' where \eqn{P(y)} is the marginal distribution of the output. MI is expressed in bits and \eqn{2^{MI}} can be interpreted as the number of 
#' inputs that the system can resolve on average.
#'
#' In contrast to existing approaches, instead of estimating, possibly highly dimensional, conditional output distributions \eqn{P(Y|X =x_i)}, we propose to estimate the discrete, conditional input distribution, 
#' \eqn{P(x_i |Y = y)}, which is known to be a simpler problem. Estimation of the MI using estimates of \eqn{P(x_i |Y = y)}, denoted here as \eqn{\hat{P}(x_i|Y = y)}, is possible as the MI, can be
#' alternatively written as
#' \deqn{MI(X,Y) = \sum_{i=1}^{m} P(x_i)\int_{R^k} P(y|X = x_i)log_2\frac{P(x_i|Y = y)}{P(x_i)}dy}
#' The expected value (as in above expression) with respect to distribution \eqn{P(Y|X = x_i)} can be approximated by the average with respect to data
#' \deqn{MI(X,Y) \approx \sum_{i=1}^{m} P(x_i)\frac{1}{n_i} \sum_{j=1}^{n_i} P(y|X = x_i)log_2\frac{\hat{P}(x_i|Y = y^i_j)}{P(x_i)}dy}
#' Here, we propose to use logistic regression as \eqn{\hat{P}(x_i|Y = y^i_j)}. Specifically,
#' \deqn{log\frac{P(x_i |Y = y)}{P(x_m|Y = y)} \approx \alpha_i +\beta_iy}
#'
#' Additional parameters: lr_maxit and maxNWts are the same as in definition of multinom function from nnet package. An alternative
#' model formula (using formula_string arguments) should be provided if  data are not suitable for description by logistic regression
#' (recommended only for advanced users). Preliminary scaling of  data (argument scale) should be used similarly as in other 
#' data-driven approaches, e.g. if response variables are comparable, scaling (scale=FALSE) can be omitted, while if they represent 
#' different phenomenon (varying by units and/or magnitude) scaling is recommended.
#'
#' @section References:
#' [1] Jetka T, Nienaltowski K, Winarski T, Blonski S, Komorowski M,  
#' Information-theoretic analysis of multivariate single-cell signaling responses using SLEMI,
#' \emph{PLoS Comput Biol}, 15(7): e1007132, 2019, https://doi.org/10.1371/journal.pcbi.1007132.
#'
#'
#' @param dataRaw must be a data.frame object
#' @param signal is a character object with names of columns of dataRaw to be treated as channel's input.
#' @param response is a character vector with names of columns of dataRaw  to be treated as channel's output
#' @param output_path is the directory in which output will be saved
#' @param side_variables (optional) is a character vector that indicates side variables' columns of data, if NULL no side variables are included
#' @param pinput is a numeric vector with prior probabilities of the input values. Uniform distribution is assumed as default (pinput=NULL).
#' @param formula_string (optional) is a character object that includes a formula syntax to use in logistic regression model. 
#' If NULL, a standard additive model of response variables is assumed. Only for advanced users.
#' @param lr_maxit is a maximum number of iteration of fitting algorithm of logistic regression. Default is 1000.
#' @param MaxNWts is a maximum acceptable number of weights in logistic regression algorithm. Default is 5000.
#' @param plot_height -  basic dimensions (height) of plots, in inches
#' @param plot_width -  basic dimensions (width) of plots, in inches
#' @param model_out is the logical indicating if the calculated logistic regression model should be included in output list
#' @param data_out  is the logical indicating if the data should be included in output list
#' @param scale is a logical indicating if the response variables should be scaled and centered before fitting logistic regression
#' @param testing is the logical indicating if the testing procedures should be executed
#' @param TestingSeed is the seed for random number generator used in testing procedures
#' @param boot_num is the number of bootstrap tests to be performed. Default is 10, but it is recommended to use at least 50 for reliable estimates.
#' @param boot_prob is the proportion of initial size of data to be used in bootstrap
#' @param testing_cores - number of cores to be used in parallel computing (via doParallel package)
#' @param sidevar_num is the number of re-shuffling tests of side variables to be performed. Default is 10, but it is recommended to use at least 50 for reliable estimates.
#' @param traintest_num is the number of overfitting tests to be performed. Default is 10, but it is recommended to use at least 50 for reliable estimates.
#' @param partition_trainfrac is the fraction of data to be used as a training dataset
#'
#' @return a list with several elements:
#' \itemize{
#' \item output$regression - confusion matrix of logistic regression predictions
#' \item output$mi         - mutual information in bits
#' \item output$model      - nnet object describing logistic regression model (if model_out=TRUE)
#' \item output$params     - parameters used in algorithm
#' \item output$time       - computation time of calculations
#' \item output$testing    - a 2- or 4-element output list of testing procedures (if testing=TRUE)
#' \item output$testing_pv - one-sided p-values of testing procedures (if testing=TRUE)
#' \item output$data       - raw data used in analysis
#' }
#' @export
#' @examples 
#' tempdata=data_example1
#' outputCLR1=mi_logreg_main(dataRaw=tempdata, signal="signal", response="response")
#' 
#' tempdata=data_example2
#' outputCLR2=mi_logreg_main(dataRaw=tempdata, signal="signal", response=c("X1","X2","X3")) 
#' 
#' #For further details see vignette
mi_logreg_main<-function(dataRaw, signal="input", response=NULL,output_path=NULL,
  side_variables=NULL,pinput=NULL, formula_string=NULL,
                                          lr_maxit=1000, MaxNWts = 5000, 
                                          testing=FALSE, model_out=TRUE,scale=TRUE,
                                          TestingSeed=1234,testing_cores=1,
                                          boot_num=10,boot_prob=0.8,
                                          sidevar_num=10,
                                          traintest_num=10,partition_trainfrac=0.6,
                                          plot_width=6,plot_height=4,
                                          data_out=FALSE){
  
 if(!is.null(output_path)){
    dir.create(output_path,recursive=TRUE)
 }

  #Debugging:
  message("Estimating mutual information ...")
  
  time_start=proc.time()
  dataRaw=as.data.frame(dataRaw)
  
  #
  if (is.null(response)){
    response=paste0("output_",1:(ncol(dataRaw)-1) )  
  }
  
  # checking assumptions
  if (is.null(output_path)) { 
    message('Output Path is not defined. Graphs and RDS file will not be saved.')
    }
  if (!is.data.frame(dataRaw)) {
    stop('data is not in data.frame format')
  }
  if ( sum(colnames(dataRaw)==signal)==0 ) {
    stop('There is no column described as signal in data')
  }
  if (!sum(colnames(dataRaw) %in% response)==length(response) ) {
    stop('There is no column described as response in data')
  }
  if (!is.null(side_variables)){
    if ( !sum(colnames(dataRaw) %in% side_variables)==length(side_variables) ) {
    stop('There is no column described as side_variables in data')
    }
  }

  
   data0=dataRaw[,c(signal,response,side_variables)]
   if ( any(apply(data0,1,function(x) any(is.na(x)) )) ) {
     message(" There are NA in observations - removing ")
     data0=data0[!apply(data0,1,function(x) any(is.na(x)) ),]
   }
  
   data0=func_signal_transform(data0,signal)
   tempcolnames=colnames(data0)
   tempsignal=data.frame(data0[,(tempcolnames%in%c(signal,paste(signal,"_RAW",sep="") ) )])
   colnames(tempsignal)<-tempcolnames[(tempcolnames%in%c(signal,paste(signal,"_RAW",sep="") ) )]
   data0=data.frame(data0[,!(tempcolnames%in%c(signal,paste(signal,"_RAW",sep="") ) )])
   colnames(data0)<-tempcolnames[!(tempcolnames%in%c(signal,paste(signal,"_RAW",sep="") ) )]
   

  
  #PreProcessing
  temp_idnumeric=sapply(data0,is.numeric)
  if (scale&sum(temp_idnumeric)==1) {
    data0[,temp_idnumeric]<-(data0[,temp_idnumeric]-mean(data0[,temp_idnumeric]))/stats::sd(data0[,temp_idnumeric])
    data <- cbind(data0,tempsignal)
  } else if (scale) {
    preProcValues <- caret::preProcess(data0, method = c("center", "scale"))
    data <- cbind(stats::predict(preProcValues, data0),tempsignal)
  } else {
    data <- cbind(data0,tempsignal)
  }
  rm(temp_idnumeric)

  #Debugging:
  #cat("... completed")
  
  output<-mi_logreg_algorithm(data=data,signal=signal,response=response,side_variables=side_variables,
                              pinput=pinput,formula_string=formula_string, model_out = model_out,
                                              lr_maxit=lr_maxit,MaxNWts =MaxNWts) 


  
  if (testing){
      output$testing<-mi_logreg_testing(data,signal=signal,response=response,side_variables=side_variables,
                                                      lr_maxit=lr_maxit,MaxNWts =MaxNWts,pinput=pinput,
                                                      formula_string=formula_string,
                                                      TestingSeed=TestingSeed,testing_cores=testing_cores,
                                                      boot_num=boot_num,boot_prob=boot_prob,
                                                      sidevar_num=sidevar_num,
                                                      traintest_num=traintest_num,partition_trainfrac=partition_trainfrac)

      
      output$testing_pv<-lapply(output$testing,function(x){
        tmp_boot_cc=sapply(x,function(xx) xx$mi)
        c(mean(tmp_boot_cc<output$mi),mean(tmp_boot_cc>output$mi))
      })
  }
  
  output$time   <- proc.time() - time_start
  output$params <- c(lr_maxit=lr_maxit,MaxNWts =MaxNWts)
  
  if (data_out){
    output$data   <- dataRaw
  }
  
  if(!is.null(output_path)){
    dir.create(output_path,recursive=TRUE)

    message("Drawing graphs and saving objects...")
    temp_logGraphs=try(output_graphs_main(data=dataRaw,signal=signal,response=response,side_variables=side_variables,cc_output=output,
                                output_path=output_path,height=plot_height,width=plot_width),silent=FALSE)
    rm(temp_logGraphs)
    #Debugging:
    #cat("... finished")

    saveRDS(output,file=paste(output_path,'output.rds',sep=""))
    message(paste0("Estimation finished. Results saved in ",output_path,""))

    } else {
      message(paste0("Estimation finished."))
    }
  
  output
}
