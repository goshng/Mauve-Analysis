# Author: Sang Choi Choi
# Date  : Sat May 14 13:41:47 EDT 2011
function simulate-data-clonalorigin2 {
  PS3="Choose a simulation (e.g., s1): "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      read-species
      
      PROCESSEDTIME=0
      TOTALITEM=$HOW_MANY_REPETITION
      ITEM=0
      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
        STARTTIME=$(date +%s)
        BASEDIR=$OUTPUTDIR/$SPECIES
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
        cp data/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE
        cp data/$INBLOCK $DATADIR
        echo $WARGSIM --tree-file $RUNCLONALORIGIN/input/$REPLICATE/$SPECIESTREE \
          --block-file $DATADIR/$INBLOCK \
          --out-file $DATADIR/core_alignment \
          --number-data $HOW_MANY_REPLICATE \
          -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE >> 1

        ENDTIME=$(date +%s)
        ITEM=$(( $ITEM + 1 ))
        ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
        PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
        REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
        REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
        echo -ne "$g/$HOW_MANY_REPETITION - $REMAINEDTIME min more to go\r"
      done

      break
    fi
  done
}
