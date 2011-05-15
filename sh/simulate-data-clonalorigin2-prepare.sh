# Author: Sang Chul Choi
# Date  : Wed Apr 20 21:04:54 EDT 2011

# Prepare the 2nd stage of clonal origin analysis
# -----------------------------------------------
# REPETITION and REPLICATE are used as indices of repeated experiments.
function simulate-data-clonalorigin2-prepare {
  Clonal2ndPhase=$1
  PS3="Choose a menu of simulation for $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ]; then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do 
        echo -n "$g "
        NUMBERDIR=$OUTPUTDIR/$SPECIES/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALFRAME=$NUMBERDIR/run-clonalframe
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_DATADIR=$CAC_NUMBERDIR/data
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        ssh -x $CAC_USERHOST \
          rm -rf $CAC_RUNCLONALORIGIN/input
        for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do 
          mkdir -p $RUNCLONALORIGIN/output2/${REPLICATE}
          mkdir -p $RUNCLONALORIGIN/input/${REPLICATE}
          ssh -x $CAC_USERHOST \
            mkdir -p $CAC_RUNCLONALORIGIN/input/${REPLICATE}

          cp data/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE

          CORE_ALIGNMENT=core_alignment.$REPLICATE.xmfa
          rm -f $DATADIR/$CORE_ALIGNMENT.*
          perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT

          scp -q $DATADIR/$CORE_ALIGNMENT.* \
            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/data

          scp -q $RUNCLONALORIGIN/input/${REPLICATE}/$SPECIESTREE \
            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/run-clonalorigin/input/${REPLICATE}
        done
        echo -ne "Copied!\r"
      done

      echo "  Make a script for submitting jobs for all the repetitions."
      make-run-list $HOW_MANY_REPETITION \
        $OUTPUTDIR/$SPECIES \
        $REPLICATE \
        $SPECIESTREE $Clonal2ndPhase \
        > $OUTPUTDIR/$SPECIES/jobidfile
      scp -q $OUTPUTDIR/$SPECIES/jobidfile $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES
      copy-run-sh $OUTPUTDIR/$SPECIES \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES \
        $SPECIES \
        $HOW_MANY_REPETITION \
        $SPECIESTREE $Clonal2ndPhase 
      echo "Go to ~/$CAC_OUTPUTDIR/$SPECIES at the cluster and submit jobs:"
      echo "$ bash run.sh"
      break
    fi
  done
}
