## ----global_options, include=FALSE---------------------------------------
knitr::opts_chunk$set(fig.pos="h")

## ----structure_pdf,fig.cap="Main function to estimate channel capacity", ,echo=FALSE, fig.pos="!h"----
# All defaults
knitr::include_graphics("plot_scheme.pdf")

## ----data_pdf, fig.cap="Conceptual representation of a generic experimental dataset needed for quantifying information transmission of a channel", ,echo=FALSE, fig.pos="!h"----
# All defaults
knitr::include_graphics("table_data.pdf")

## ----init, include=FALSE-------------------------------------------------
library(grid)
library(ggplot2)
library(gridExtra)
library(stringr)
library(reshape2)
display_plots=TRUE

## ----nfkb1, include=FALSE------------------------------------------------
library(SLEMI)
tempdata=data_nfkb[,1:4]
tempdata=tempdata[!apply(tempdata,1,function(x) any(is.na(x))),]
row.names(tempdata)<-NULL

## ----nfkb2, results="asis",echo=FALSE------------------------------------
knitr::kable(rbind(tempdata[1:3,],tempdata[10001:10003,],tail(tempdata,3)))

## ----mwe1,include=FALSE--------------------------------------------------
xs=c(0,0.1,1,10) # concentration of input.
tempdata = data.frame(input = factor(c(t(replicate(1000,xs))),
                      levels=xs),
                      output =  c(matrix(rnorm(4000, mean=10*(xs/(1+xs)),sd=c(1,1,1,1)),
                                            ncol=4,byrow=TRUE) ))
tempoutput  <- capacity_logreg_main(dataRaw=tempdata, 
                                    signal="input", response="output")

## ----MWE15, results="asis",echo=FALSE------------------------------------
knitr::kable(rbind(tempdata[1:2,],tempdata[2001:2002,],tail(tempdata,2)))

## ----data_pdf2, fig.cap="Standard output graph of the minimal working example", echo=FALSE, fig.pos="h"----
# All defaults
knitr::include_graphics("plot_1.pdf")

## ----mwe4,include=FALSE--------------------------------------------------
tempoutput_mi  <- mi_logreg_main(dataRaw=tempdata, 
                                    signal="input", response="output",
                                    pinput=rep(1/4,4))


## ----mwe4b,include=TRUE--------------------------------------------------
print(paste("Mutual Information:", tempoutput_mi$mi,"; ",
            "Channel Capacity:", tempoutput$cc, sep=" "))

## ----mwe4_2,include=FALSE------------------------------------------------
tempoutput_mi  <- mi_logreg_main(dataRaw=tempdata, 
                                    signal="input", response="output",
                                    pinput=c(0.4,0.1,0.4,0.1))


## ----mwe4b_2,include=TRUE------------------------------------------------
print(paste("Mutual Information:", tempoutput_mi$mi,"; ",
            "Channel Capacity:", tempoutput$cc, sep=" "))

## ----mwe5,include=FALSE--------------------------------------------------
tempoutput_probs  <- prob_discr_pairwise(dataRaw=tempdata, 
                                    signal="input", response="output")

## ----mwe5b,include=FALSE-------------------------------------------------
for (i in 1:4){
  tempoutput_probs$prob_matr[i,i]=1
}

## ----data_pdf3, fig.cap="Standard output graph presenting probabilities of correct discrimination between each pair of input values.", ,echo=FALSE, fig.pos="h",out.height="9cm"----
# All defaults
knitr::include_graphics("plot_2.pdf")

## ----diag2, include=FALSE------------------------------------------------
library(SLEMI)
library(ggplot2)
library(gridExtra)

## ----data_pdf4, fig.cap="Standard output graph of the diagnostic procedures. P-values (PV) are based on empirical test either left- or right- sided. In the top axis, black dot represents the estimate of the channel capacity that involves the  compete dataset, red dot is the mean of bootstrap procedures, while the bars are mean +/- sd. The remaining panels are histograms of all repetitions of a specific diagnostic procedure.", ,echo=FALSE, fig.pos="h"----
# All defaults
knitr::include_graphics("plot_3.pdf")

## ----session-------------------------------------------------------------
sessionInfo()

