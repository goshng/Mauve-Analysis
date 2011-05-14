# Author: Sang Chul Choi
# Date  : Wed Apr 20 21:15:46 EDT 2011

# Receives result of clonal origin runs for simulation 
# ----------------------------------------------------
# Let's just receive the results.
function simulate-data-clonalorigin1-receive {
  CLONAL2ndPHASE=$1 
  PS3="Choose the simulation to receive with $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      echo "  Receiving clonal origin analysis..."
      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
        NUMBERDIR=$OUTPUTDIR/$SPECIES/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        for REPLICATE in ${REPLICATES[@]}; do
          if [[ -z $CLONAL2ndPHASE ]]; then
            rm -rf $RUNCLONALORIGIN/output/$REPLICATE
            mkdir -p $RUNCLONALORIGIN/output/$REPLICATE
            scp -q $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.* \
              $RUNCLONALORIGIN/output/$REPLICATE
          else
            rm -rf $RUNCLONALORIGIN/output2/$REPLICATE
            mkdir -p $RUNCLONALORIGIN/output2/$REPLICATE
            scp -q $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.* \
              $RUNCLONALORIGIN/output2/$REPLICATE
          fi
        done
        echo -ne "REPETITION $g has been downloaded\r" 
      done
      echo "$g REPETITION have been downloaded!"
      break
    fi
  done
}

