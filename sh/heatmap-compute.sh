# Author: Sang Chul Choi
# Date  : Wed Apr 20 10:23:47 EDT 2011

#trim() { echo $1; }

# Compute the prior expected number of recombinant edges.
# -------------------------------------------------------
# This function must be called in the main run.sh. Variables would make sense
# only in that situtiaon. The funciton alone would not work.
function heatmap-compute {
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
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"

      echo -e "Computing heat map for the blocks ...\n"
      for i in $(eval echo {1..$NUMBER_BLOCK}); do
        if [ -f "$RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.$i.xml" ]; then
          # Compute prior expected number of recedges.
          $GUI -b \
            -o $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.$i.xml \
            -H 3 \
            > $RUNCLONALORIGIN/output2/heatmap-$i.txt
        else
          echo "Block: $i was not used" 1>&2
        fi
      done 
      break
    fi
  done
}