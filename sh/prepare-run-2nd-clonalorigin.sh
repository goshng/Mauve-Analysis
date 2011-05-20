
# 8. Check the convergence
# ------------------------
# A multiple runs of the first stage of ClonalOrigin are checked for their
# convergence.
# FIXME: we need a bash function.

# 9. Prepare 2nd clonalorigin-analysis.
# -------------------------------------
# I use one of replicates of the first stage of ClonalOrigin. I do not combine
# the replicates.
function prepare-run-2nd-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -e "Which replicate set of ClonalOrigin output files?"
      echo -n "ClonalOrigin REPLICATE ID: " 
      read REPLICATE
      echo -e "Which replicate set of ClonalOrigin's 1st stage output files?"
      echo -n "ClonalOrigin1 REPLICATE ID: " 
      read REPLICATECLONALORIGIN1
      echo -n "Brunin: "
      read BURNIN 
      echo -n "ChainLength: "
      read CHAINLENGTH 
      echo -n "Thin: "
      read THIN
      set-more-global-variable $SPECIES $REPETITION
      if [ -f "$RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt" ]; then
        MEDIAN_THETA=$(grep "Median theta" $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt | cut -d ":" -f 2)
        MEDIAN_DELTA=$(grep "Median delta" $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt | cut -d ":" -f 2)
        MEDIAN_RHO=$(grep "Median rho" $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt | cut -d ":" -f 2)
        echo -e "  Preparing 2nd clonalorigin ... "

        SPECIESTREE=clonaltree.nwk
        echo "  Creating job files..."
        make-run-list-repeat $g \
          $OUTPUTDIR/$SPECIES \
          $REPLICATE \
          $SPECIESTREE Clonal2ndPhase \
          > $RUNCLONALORIGIN/jobidfile
        scp -q $OUTPUTDIR/$SPECIES/$g/run-clonalorigin/jobidfile \
          $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES/$g/run-clonalorigin

        copy-batch-sh-run-clonalorigin $g \
          $OUTPUTDIR/$SPECIES \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES \
          $SPECIES \
          $SPECIESTREE \
          $REPLICATE Clonal2ndPhase
   
        echo -e "Submit a job using the following command:"
        echo -e "$ bash batch.sh 3"
        echo -e "to use three computing nodes!"
      else
        echo "No summary file called $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt" 1>&2
      fi
      break
    fi
  done
}

