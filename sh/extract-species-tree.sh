# Author: Sang Chul Choi
# Date  : Wed May 11 21:44:34 EDT 2011

function extract-species-tree {
  PS3="Choose the species to compute block lengths: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -n "What replicate do you wish to use? (e.g., 1) "
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION
      perl pl/$FUNCNAME.pl \
        -xml $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1 \
        -out $RUNANALYSIS/species-tree-$REPLICATE.tree
      echo "Check $RUNANALYSIS/species-tree-$REPLICATE.tree"
      break
    fi
  done
}
