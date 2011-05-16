
# 5. Receive clonalframe-analysis.
# --------------------------------
# A few replicates of ClonalFrame could be created.
function receive-run-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Receiving clonalframe-output...\n"
      set-more-global-variable $SPECIES $REPETITION
      echo -e "Which replicate set of ClonalFrame output files?"
      echo -n "ClonalFrame REPLICATE ID: " 
      read CLONALFRAMEREPLICATE
      mkdir -p $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE
      scp $CAC_USERHOST:$CAC_RUNCLONALFRAME/output/* $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE/
      echo -e "  Sending clonalframe-output to swiftgen...\n"
      ssh -x $X11_USERHOST \
        mkdir -p $CAC_RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE
      scp $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE/* \
        $X11_USERHOST:$X11_RUNCLONALFRAME
      echo -e "Now, prepare clonalorigin.\n"
      break
    fi
  done
}

