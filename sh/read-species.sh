function read-species {
  SPECIESFILE=species/$SPECIES

  echo -n "  Reading REPETITION from $SPECIESFILE..."
  HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
  echo " $HOW_MANY_REPETITION"

  echo -n "  Reading REPLICATE from $SPECIESFILE..."
  HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
  if [ "$HOW_MANY_REPLICATE" == "" ]; then
    HOW_MANY_REPLICATE=0
    echo " $HOW_MANY_REPLICATE"
    echo "  No Replicate is specified at $SPECIESFILE!" 
    echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
    read REPLICATE
    REPLICATES=($REPLICATE)
  else
    echo " $HOW_MANY_REPLICATE"
    eval "REPLICATES=({1..${HOW_MANY_REPLICATE}})"
  fi

  echo -n "  Reading INBLOCK from $SPECIESFILE..."
  INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
  echo " $INBLOCK"
 
  echo -n "  Counting blocks from $INBLOCK..."
  NUMBER_BLOCK=$(echo `cat simulation/$INBLOCK | wc -l`)
  echo " $NUMBER_BLOCK"

  echo -n "  Reading NUMBER_SPECIES from $SPECIESFILE..."
  NUMBER_SPECIES=$(grep NumberSpecies $SPECIESFILE | cut -d":" -f2)
  echo " $NUMBER_SPECIES"

  echo -n "  Reading GENELENGHT from $SPECIESFILE..."
  GENELENGTH=$(grep GeneLength $SPECIESFILE | cut -d":" -f2)
  echo " $GENELENGTH"

  echo -n "  Reading WALLTIME from $SPECIESFILE..."
  WALLTIME=$(grep Walltime $SPECIESFILE | cut -d":" -f2)
  echo " $WALLTIME"
}
