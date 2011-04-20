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

      perl pl/extractClonalOriginParameter7.pl \
        -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2 \
        -xmfabase $DATADIR/core_alignment.xmfa \
        -out $RUNANALYSIS/$FUNCNAME-$SPECIES-$REPLICATE.out
      echo "$RUNANALYSIS/$FUNCNAME-$SPECIES-$REPLICATE.out"

      #echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"
      #break 
      # NUMBER_BLOCK=`wc -l < simulation/$INBLOCK`
      NUMBER_BLOCK=71
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      NUMBER_SAMPLE=101 
      echo -e "  The sample size per block is $NUMBER_BLOCK."

      rscript-plot-number-recombination-within-blocks \
        $RUNANALYSIS/$FUNCNAME-$SPECIES-$REPLICATE.out \
        $NUMBER_BLOCK \
        $NUMBER_SAMPLE 
 
      #cat $RUNANALYSIS/$FUNCNAME-$SPECIES-$REPLICATE.out.R.out
      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

function rscript-plot-number-recombination-within-blocks {
  S2OUT=$1
  BATCH_R=$1.R
  NUMBER_BLOCK=$2
  NUMBER_SAMPLE=$3
  NUMBER_NUMBER=$(( NUMBER_BLOCK * NUMBER_SAMPLE ))

  rm -f $BATCH_R

weighted-median-rscript $BATCH_R

cat>>$BATCH_R<<EOF
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
  blockLen <- $NUMBER_SAMPLE + 1
  positionGenome <- $NUMBER_SAMPLE + 3
  l <- $NUMBER_SAMPLE + 3
  x <- scan (f, quiet=TRUE)
  x <- matrix (x, ncol=l, byrow=TRUE)

  col1 <- c()
  col2 <- c()
  for (i in 1:$NUMBER_BLOCK) {
    for (j in 1:$NUMBER_SAMPLE) {
      col1 <- c(col1, x[i, positionGenome]) 
      col2 <- c(col2, x[i,j] <- x[i,j] / x[i,blockLen])
    }
  }

  t1 <- matrix(c(col1,col2), ncol=2)
  colnames(t1) <- c("position", "v")
  
  x.filename <- paste (f, ".ps", sep="")
  x <- read.table (f);

  postscript(file=x.filename)
  if (logscale == TRUE) {
    plot(t1[,"position"], log(t1[,"v"]), cex=.2, xlab=xlab, ylab=ylab, bty="n")
    abline (h=log(m), col="red", lty="dashed")
  } else {
    plot(t1[,"position"], t1[,"v"], cex=.2, xlab=xlab, ylab=ylab, bty="n")
    abline (h=m, col="red", lty="dashed")
  }
  dev.off()
}

wm <- medianParameter ("$S2OUT.recomb") 
plotThreeParameter ("$S2OUT.recomb", "", "Recombination event boundaries per site", wm, FALSE)
EOF
  Rscript $BATCH_R > $BATCH_R.out 
}
