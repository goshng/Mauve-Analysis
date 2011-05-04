# Author: Sang Chul Choi
# Date  : Wed Apr 27 16:45:56 EDT 2011

function recombination-intensity {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) " 
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      echo -e "  The number of blocks is $NUMBER_BLOCK."
       
      perl pl/recombination-intensity4.pl \
        -d $RUNCLONALORIGIN/output2/${REPLICATE} \
        -xmfa $DATADIR/core_alignment.xmfa \
        -speciesfile species/$SPECIES \
        -genomedir $GENOMEDATADIR \
        -r 1 \
        -verbose \
        -numberblock $NUMBER_BLOCK \
        > $RUNANALYSIS/recombination-intensity-${REPLICATE}.txt
      break
    fi
  done
}

