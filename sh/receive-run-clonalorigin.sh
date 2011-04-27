# Author: Sang Chul Choi
# Date  : Mon Apr 25 15:02:19 EDT 2011

# 7. Receive clonalorigin-analysis.
# ---------------------------------
# Note that we can have multiple replicates of clonal origin. 
# I might want to just compute global median estimates of the first stage of
# ClonalOrigin.
#
# NOTE: Some of jobs were not finished within reasonable time. It would be
# better to have all jobs finished. Sometimes it is not possible partly because
# I would not wait for those to be finished. It is desirable to handle partial
# output of Clonal Origin. 
function receive-run-clonalorigin {
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

      echo -n 'Have you already downloaded and do you want to skip the downloading? (y/n) '
      read WANTSKIPDOWNLOAD
      if [ "$WANTSKIPDOWNLOAD" == "y" ]; then
        echo "  Skipping copy of the output files because I've already copied them ..."
      else
        echo -e "  Receiving 1st stage of clonalorigin-output..."
        mkdir -p $RUNCLONALORIGIN/output/${REPLICATE}
        scp -q $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output/${REPLICATE}/* \
          $RUNCLONALORIGIN/output/${REPLICATE}/
      fi

      echo -n 'Do you want to skip deleting unfinished XML files? (y/n) '
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
        echo "  Skipping deleting unfinished XML files..."
      else
        echo "  Reporting status of jobs ..."
        perl pl/report-clonalorigin-job.pl \
          -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml \
          -database $DATADIR/core_alignment.xmfa \
          > $RUNCLONALORIGIN/summary/${REPLICATE}/unfinished
      fi

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

