# Author: Sang Chul Choi
# Date  : Thu May 19 20:23:04 EDT 2011

function summarize-clonalorigin1 {
  PS3="Choose the species to analyze real data for clonalorigin1: "
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
      mkdir -p $RUNCLONALORIGIN/summary/${REPLICATE}

      echo "  Reporting status of jobs ..."
      perl pl/report-clonalorigin-job.pl \
        -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml \
        -database $DATADIR/core_alignment.xmfa \
        > $RUNCLONALORIGIN/summary/${REPLICATE}/unfinished

      echo -e "  Computing the global medians of theta, rho, and delta ..."
      perl pl/computeMedians.pl \
        $RUNCLONALORIGIN/output/${REPLICATE}/core_co.phase2.xml.* \
        | grep ^Median > $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      echo -e "This is the summary of the first stage of clonal origin run:"
      cat $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt

      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

