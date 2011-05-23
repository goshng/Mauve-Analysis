# Author: Sang Chul Choi
# Date  : Sat May  7 23:44:27 EDT 2011

# function clonalorigin2-simulation3-receive {
function sim4-receive {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES

      PROCESSEDTIME=0
      TOTALITEM=$(( $HOW_MANY_REPETITION * $HOW_MANY_REPLICATE ));
      ITEM=0
      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          STARTTIME=$(date +%s)
          scp -rq \
            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE-out \
            $BASEDIR/$REPETITION/run-clonalorigin/output2/
          ENDTIME=$(date +%s)
          ITEM=$(( $ITEM + 1 ))
          ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
          PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
          REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
          REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
          echo -ne "$REPETITION/$HOW_MANY_REPETITION - $REPLICATE/$HOW_MANY_REPLICATE - more $REMAINEDTIME min to go\r"
        done
      done
      echo "$FUNCNAME done!"
      break
    fi 
  done
}

