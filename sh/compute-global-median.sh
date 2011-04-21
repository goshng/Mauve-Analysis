# Author: Sang Chul Choi
# Date  : Wed Apr 20 10:23:47 EDT 2011

# Compute the global median of the 3 main parameters.
# ---------------------------------------------------
# This function must be called in the main run.sh. Variables would make sense
# only in that situtiaon. The funciton alone would not work.
function compute-global-median {
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
      mkdir -p $RUNCLONALORIGIN/summary/${REPLICATE}

      echo -e "  Computing the global medians of theta, rho, and delta ..."
      perl pl/computeMedians.pl \
        $RUNCLONALORIGIN/output/${REPLICATE}/core_co.phase2.*.xml \
        | grep ^Median > $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      echo -e "This is the summary of the first stage of clonal origin run:"
      cat $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}


