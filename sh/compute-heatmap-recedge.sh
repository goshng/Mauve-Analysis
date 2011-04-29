# Author: Sang Chul Choi
# Date  : Fri Apr 29 14:38:20 EDT 2011

#trim() { echo $1; }

# Computes the heatmap of recombinant edge counts.
# -------------------------------------------------------
# 
function compute-heatmap-recedge {
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
      NUMBER_SPECIES=$(echo `grep gbk SPECIESFILE|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo -e "The number of species is $NUMBER_SPECIES."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"

      perl pl/extractClonalOriginParameter12.pl \
        -d $RUNCLONALORIGIN/output2/${REPLICATE} \
        -e $RUNCLONALORIGIN/output2/priorcount-${REPLICATE} \
        -endblockid \
        -n $NUMBER_BLOCK \
        -s $NUMBER_SPECIES
      break
    fi
  done
}
