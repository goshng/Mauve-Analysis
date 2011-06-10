# Author: Sang Chul Choi
# Date  : Tue Apr 19 14:45:36 EDT 2011

# Plots the three main scalar parameters of clonal origin model.
# --------------------------------------------------------------
# The first stage of clonal origin run sample the three main parameters
# including mutation rate, recombination rate, and average recombinant tract
# legnth. I parse XML output files of clonal origin to find values of the
# parameters. The values are plotted for all blocks.
function scatter-plot-parameter {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
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

      perl pl/$FUNCNAME.pl \
        -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2 \
        -xmfabase $DATADIR/core_alignment.xmfa \
        -out $RUNANALYSIS/$FUNCNAME-$REPLICATE.out
      echo "$RUNANALYSIS/$FUNCNAME-$REPLICATE.out"

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      NUMBER_SPECIES=$(echo `grep gbk $SPECIESFILE|wc -l`)
      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.1|wc -l`)
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      echo -e "  The sample size per block is $NUMBER_SAMPLE."
      echo -e "  The number of species is $NUMBER_SPECIES."

      MEDIAN_THETA=$(grep "Median theta" $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt | cut -d ":" -f 2)
      MEDIAN_DELTA=$(grep "Median delta" $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt | cut -d ":" -f 2)
      MEDIAN_RHO=$(grep "Median rho" $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt | cut -d ":" -f 2)

      analyze-run-clonalorigin-scatter-plot-parameter-rscript \
        $RUNANALYSIS/$FUNCNAME-$REPLICATE.out 
 
      #cat $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

function analyze-run-clonalorigin-scatter-plot-parameter-rscript {
  S2OUT=$1
  BATCH_R=$1.R
cat>$BATCH_R<<EOF
library("geneplotter")  ## from BioConductor
require("RColorBrewer") ## from CRAN

plotThreeParameter <- function (f, xlab, ylab, m, logscale) {
  x.filename <- paste (f, ".ps", sep="")
  x <- read.table (f);

  pos.median <- c() 
  pos <- unique (x\$V1)
  for (i in pos)
  {
    pos.median <- c(pos.median, median(x\$V2[x\$V1 == i]))
  }

  postscript (file=x.filename, width=10, height=5, horizontal = FALSE, onefile = FALSE, paper = "special")
  if (logscale == TRUE) {
    smoothScatter(x\$V1, log(x\$V2), nrpoints=0, colramp = colorRampPalette(c("white", "black")), xlab=xlab, ylab=ylab)
    points (pos, log(pos.median), pch=43)
    abline (h=log(m), col="red", lty="dashed")
  } else {
    smoothScatter(x\$V1, x\$V2, nrpoints=0, colramp = colorRampPalette(c("white", "black")), xlab=xlab, ylab=ylab)
    points (pos, pos.median, pch=43)
    abline (h=m, col="red", lty="dashed")
  }
  dev.off()
}
plotThreeParameter ("$S2OUT.theta", "Genomic position on S. dysgalactiae ssp. equisimilis ATCC 12394", "Mutation rate per site", $MEDIAN_THETA, FALSE)
plotThreeParameter ("$S2OUT.rho", "Genomic position on S. dysgalactiae ssp. equisimilis ATCC 12394", "Recombination rate per site", $MEDIAN_RHO, FALSE)
plotThreeParameter ("$S2OUT.delta", "Genomic position on S. dysgalactiae ssp. equisimilis ATCC 12394", "Log average tract length", $MEDIAN_DELTA, TRUE)
EOF
  Rscript $BATCH_R > $BATCH_R.out 
}
