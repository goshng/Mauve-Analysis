# Author: Sang Chul Choi
# Date  : Tue Apr 19 14:45:36 EDT 2011

# Plots the three main scalar parameters of clonal origin model.
# --------------------------------------------------------------
# The first stage of clonal origin run sample the three main parameters
# including mutation rate, recombination rate, and average recombinant tract
# legnth. I parse XML output files of clonal origin to find values of the
# parameters. The values are plotted for all blocks.
function scatter-plot-parameter {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of output files? (e.g., 1) "
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      perl pl/extractClonalOriginParameter6.pl \
        -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2 \
        -out $RUNANALYSIS/scatter-plot-parameter-$SPECIES-$REPLICATE.out
      echo "$RUNANALYSIS/scatter-plot-parameter-$SPECIES-$REPLICATE.out"

      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"
      break 
      # NUMBER_BLOCK=`wc -l < simulation/$INBLOCK`
      NUMBER_BLOCK=71
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      NUMBER_SAMPLE=101 
      echo -e "  The sample size per block is $NUMBER_BLOCK."

      analyze-run-clonalorigin-scatter-plot-parameter-rscript \
        $RUNANALYSIS/scatter-plot-parameter-$SPECIES-$REPLICATE.out \
        $NUMBER_BLOCK \
        $NUMBER_SAMPLE 
 
      #cat $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

function analyze-run-clonalorigin-scatter-plot-parameter-rscript {
  S2OUT=$1
  BATCH_R=$1.R
  NUMBER_BLOCK=$2
  NUMBER_SAMPLE=$3
  NUMBER_NUMBER=$(( NUMBER_BLOCK * NUMBER_SAMPLE ))
cat>$BATCH_R<<EOF
plotThreeParameter <- function (f, xlab, ylab, m, logscale) {
  x.filename <- paste (f, ".ps", sep="")
  x <- read.table (f);

  postscript(file=x.filename)
  if (logscale == TRUE) {
    plot(x\$V1, log(x\$V2), cex=.2, xlab=xlab, ylab=ylab, bty="n")
    abline (h=log(m), col="red", lty="dashed")
  } else {
    plot(x\$V1, x\$V2, cex=.2, xlab=xlab, ylab=ylab, bty="n")
    abline (h=m, col="red", lty="dashed")
  }
  dev.off()
}
plotThreeParameter ("$S2OUT.theta", "", "Mutation rate per site", 0.0749323036174269, FALSE)
plotThreeParameter ("$S2OUT.rho", "", "Recombination rate per site", 0.0137842770601471, FALSE)
plotThreeParameter ("$S2OUT.delta", "", "Log average tract length", 614.149554455445, TRUE)
EOF
  Rscript $BATCH_R > $BATCH_R.out 
}
