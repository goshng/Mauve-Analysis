# Author: Sang Chul Choi
# Date  : Thu May  5 13:45:53 EDT 2011

# Analyzes the 2nd stage of clonal origin simulation
# --------------------------------------------------
#
function analyze-run-clonalorigin2-simulation2-analyze {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES

      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        RIFILES="" 
        RTFILE=$BASEDIR/$REPETITION/run-clonalorigin/output2/$REPETITION.rt
        for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          RIS="" 
          RIFILE=$BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE.ri
          for i in $(eval echo {1..$NUMBER_BLOCK}); do
            RIS="$RIS $BASEDIR/$REPETITION/run-clonalorigin/output2/ri-$REPLICATE/$i" 
          done
          paste $RIS > $RIFILE
          RIFILES="$RIFILES $RIFILE"
        done
        cat $RIFILES > $RTFILE
      done
    fi
    break
  done
}

