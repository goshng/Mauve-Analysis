
function copy-mauve-alignment {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -n "From which repetition do you wish to copy? (e.g., 1) "
      read SOURCE_REPETITION
      echo -e "  Copying mauve-output..."
      echo -e "    from $BASEDIR/$SOURCE_REPETITION/run-mauve"
      echo -e "    to $RUNMAUVE/output"
      set-more-global-variable $SPECIES $REPETITION
      cp -r $BASEDIR/$SOURCE_REPETITION/run-mauve/output $RUNMAUVE
      echo -e "Now, find core blocks of the alignment.\n"
      break
    fi
  done
}

