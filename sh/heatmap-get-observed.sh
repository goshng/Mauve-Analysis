# Author: Sang Chul Choi
# Date  : Wed Apr 20 11:09:22 EDT 2011

#trim() { echo $1; }

# Get the observed number of recombinant edges.
# -------------------------------------------------------
# This function must be called in the main run.sh. Variables would make sense
# only in that situtiaon. The funciton alone would not work.
function heatmap-get-observed {
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

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      NUMBER_SPECIES=$(echo `grep gbk data/$SPECIES|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo -e "The number of species is $NUMBER_SPECIES."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"

      #perl pl/extractClonalOriginParameter12.pl \
      perl pl/compute-heatmap-recedge.pl \
        -d $RUNCLONALORIGIN/output2/${REPLICATE} \
        -endblockid \
        -obsonly \
        -n $NUMBER_BLOCK \
        -s $NUMBER_SPECIES \
        > $RUNANALYSIS/obsonly-recedge-$REPLICATE.txt
      echo "Check file $RUNANALYSIS/obsonly-recedge-$REPLICATE.txt"
      break
    fi
  done
}
