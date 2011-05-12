# Author: Sang Chul Choi
# Date  : Wed May 11 21:44:34 EDT 2011

# Computes lengths of blocks.
# ---------------------------
# The run-lcb contains a list of core_alignment.xmfa.[NUMBER] files.
function compute-block-length {
  PS3="Choose the species to compute block lengths: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      perl pl/compute-block-length.pl \
        -base=$DATADIR/core_alignment.xmfa \
        > data/$SPECIES-$REPETITION-in.block
      echo "Check data/$SPECIES-$REPETITION-in.block"
      break
    fi
  done

}
