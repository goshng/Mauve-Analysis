
function simulate-data-clonalorigin2 {
  PS3="Choose a simulation (e.g., s1): "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      SPECIESFILE=species/$SPECIES

      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"
      
      echo -n "  Reading REPLICATE from $SPECIESFILE..."
      HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPLICATE"

      echo -n "  Reading SPECIESTREE from $SPECIESFILE..."
      SPECIESTREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      echo " $SPECIESTREE"

      echo -n "  Reading INBLOCK from $SPECIESFILE..."
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      echo " $INBLOCK"

      echo -n "  Reading from $SPECIESFILE..."
      THETA_PER_SITE=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $THETA_PER_SITE"

      echo -n "  Reading from $SPECIESFILE..."
      RHO_PER_SITE=$(grep RhoPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $RHO_PER_SITE"

      echo -n "  Reading from $SPECIESFILE..."
      DELTA=$(grep Delta $SPECIESFILE | cut -d":" -f2)
      echo " $DELTA"

      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
        BASEDIR=$OUTPUTDIR/$SPECIES
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
        cp simulation/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE
        cp simulation/$INBLOCK $DATADIR
        echo -n "  Simulating data under the ClonalOrigin model ..." 
        $WARGSIM --tree-file $RUNCLONALORIGIN/input/$REPLICATE/$SPECIESTREE \
          --block-file $DATADIR/$INBLOCK \
          --out-file $DATADIR/core_alignment \
          --number-data $HOW_MANY_REPLICATE \
          -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE
        echo -e " done - repetition $g"
      done
      break
    fi
  done
}

