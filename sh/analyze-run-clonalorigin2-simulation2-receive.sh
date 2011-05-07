# Author: Sang Chul Choi
# Date  : Fri May  6 00:47:41 EDT 2011

# Receives simulation2
function analyze-run-clonalorigin2-simulation2-receive {
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
        for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          scp -rq $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/output2/ri-$REPLICATE \
            $BASEDIR/$REPETITION/run-clonalorigin/output2/
        done
      done
      break
    fi 
  done
}

