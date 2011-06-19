# Author: Sang Chul Choi
# Date  : Sun Jun 19 17:50:19 EDT 2011

function summary-core-alignment {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION

      echo "  Summarizing the core_alignment.xmfa"
      echo perl pl/$FUNCNAME.pl \
        -in $DATADIR/core_alignment.xmfa \
        -out $RUNANALYSIS/$FUNCNAME.txt
  
      break
    fi
  done
}

