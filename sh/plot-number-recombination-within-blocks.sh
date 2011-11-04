# Author: Sang Chul Choi
# Date  : Tue Apr 19 16:53:05 EDT 2011

source sh/weighted-median-rscript.sh

# Plots number of recombination boundaries per site.
# --------------------------------------------------
# I parse XML output files of clonal origin to find values of the
# parameters. The values are plotted for all blocks.
# 101 + 1 (sample of 101 for each block and the block length).
# 
function plot-number-recombination-within-blocks {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      set-more-global-variable $SPECIES $REPETITION
      REPLICATE=$(grep ^REPETITION${REPETITION}-CO2-CO1ID $SPECIESFILE | cut -d":" -f2)

      perl pl/$FUNCNAME.pl \
        -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2 \
        -xmfabase $DATADIR/core_alignment.xmfa \
        -thin 1 \
        -out $RUNANALYSIS/$FUNCNAME-$REPLICATE.out
      echo "$RUNANALYSIS/$FUNCNAME-$REPLICATE.out"

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      NUMBER_SPECIES=$(echo `grep gbk data/$SPECIES|wc -l`)
      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.1.xml|wc -l`)
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      echo -e "  The sample size per block is $NUMBER_SAMPLE."
      echo -e "  The number of species is $NUMBER_SPECIES."

      rscript-plot-number-recombination-within-blocks \
        $RUNANALYSIS/$FUNCNAME-$REPLICATE.out 
        #$NUMBER_BLOCK \
        #$NUMBER_SAMPLE 
 
      #cat $RUNANALYSIS/$FUNCNAME-$SPECIES-$REPLICATE.out.R.out
      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

function rscript-plot-number-recombination-within-blocks {
  S2OUT=$1
  BATCH_R=$1.R

  NUMBER_BLOCK=2
  NUMBER_SAMPLE=3
  NUMBER_NUMBER=$(( NUMBER_BLOCK * NUMBER_SAMPLE ))

  rm -f $BATCH_R

weighted-median-rscript $BATCH_R

cat>>$BATCH_R<<EOF
library("geneplotter")  ## from BioConductor
require("RColorBrewer") ## from CRAN

medianParameter <- function (f) {
  blockLen <- $NUMBER_SAMPLE + 1
  positionGenome <- $NUMBER_SAMPLE + 3
  l <- $NUMBER_SAMPLE + 3
  x <- scan (f, quiet=TRUE)
  x <- matrix (x, ncol=l, byrow=TRUE)

  y <- c() 
  for (i in 1:$NUMBER_BLOCK) {
    y <- c(y, mean(x[i,1:$NUMBER_SAMPLE]) / x[i,blockLen])
  }

  weighted.median(y, x[,l])

  #cat (wm);
  #cat ("\n")
}

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

# wm <- medianParameter ("$S2OUT.recomb") 
plotThreeParameter ("$S2OUT.recomb", "Genomic position on S. dysgalactiae ssp. equisimilis ATCC 12394", "Recombination event boundaries per site", 0.00459635384193331, FALSE)
EOF
  Rscript $BATCH_R > $BATCH_R.out 
}
