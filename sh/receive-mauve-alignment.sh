# 2. Receive mauve-analysis.
# --------------------------
# I simply copy the alignment. 
# I could copy alignment from other repetition.
function receive-mauve-alignment {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Receiving mauve-output...\n"
      set-more-global-variable $SPECIES $REPETITION
      scp -r $CAC_USERHOST:$CAC_RUNMAUVE/output $RUNMAUVE/
      echo -e "Now, find core blocks of the alignment.\n"
      break
    fi
  done
}
