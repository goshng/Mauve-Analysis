# Author: Sang Chul Choi
# Date  : Wed Apr 20 21:04:54 EDT 2011

# Prepare the 2nd stage of clonal origin analysis
# -----------------------------------------------
# 
function prepare-run-clonalorigin2-simulation {
  Clonal2ndPhase=$1
  PS3="Choose a menu of simulation with clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ]; then
      echo -e "You need to enter something\n"
      continue
    else
      SPECIESFILE=species/$SPECIES
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE

      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"

      echo -n "  Reading SPECIESTREE from $SPECIESFILE..."
      SPECIESTREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      echo " $SPECIESTREE"

      echo -n "  Reading THETA per site from $SPECIESFILE..."
      MEDIAN_THETA=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $MEDIAN_THETA"

      echo -n "  Reading DELTA from $SPECIESFILE..."
      MEDIAN_DELTA=$(grep Delta $SPECIESFILE | cut -d":" -f2)
      echo " $MEDIAN_DELTA"

      echo -n "  Reading RHO per site from $SPECIESFILE..."
      MEDIAN_RHO=$(grep RhoPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $MEDIAN_RHO"


      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do 
        echo -n "$g "
        NUMBERDIR=$OUTPUTDIR/$SPECIES/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALFRAME=$NUMBERDIR/run-clonalframe
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        mkdir -p $RUNCLONALORIGIN/output/${REPLICATE}
        mkdir -p $RUNCLONALORIGIN/output2/${REPLICATE}
        mkdir -p $RUNCLONALORIGIN/input/${REPLICATE}
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_DATADIR=$CAC_NUMBERDIR/data
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
        ssh -x $CAC_USERHOST \
          mkdir -p $CAC_RUNCLONALORIGIN/input/${REPLICATE}

        # I already have the tree.
        cp simulation/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE

        #echo "  Splitting alignment into files per block... ($g)"
        CORE_ALIGNMENT=${SPECIES}_${g}_core_alignment.xmfa
        rm -f $DATADIR/$CORE_ALIGNMENT.*
        perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT

        #echo "  Copying the split alignments... ($g)"
        scp -q $DATADIR/$CORE_ALIGNMENT.* \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/data

        #echo "  Copying the input species tree... ($g)"
        scp -q $RUNCLONALORIGIN/input/${REPLICATE}/$SPECIESTREE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/run-clonalorigin/input/${REPLICATE}

        #echo "  Making command options for clonal origin... ($g)"
        make-run-list-repeat $g \
          $OUTPUTDIR/$SPECIES \
          $REPLICATE \
          $SPECIESTREE $Clonal2ndPhase \
          > $RUNCLONALORIGIN/jobidfile
        scp -q $RUNCLONALORIGIN/jobidfile $CAC_USERHOST:$CAC_RUNCLONALORIGIN
        copy-batch-sh-run-clonalorigin \
          $g \
          $OUTPUTDIR/$SPECIES \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES \
          $SPECIES \
          $SPECIESTREE \
          $REPLICATE
      done
      echo ""
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
      break
    fi
  done
}

