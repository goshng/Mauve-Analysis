# Author: Sang Chul Choi
# Date  : Mon Apr 25 10:25:22 EDT 2011

# Divides a clonal origin XML file into as many as blocks.
# --------------------------------------------------------
# A simulation with clonal origin generates an alignment and a clonal frame with
# recombinant edges attatched to it. The alignment was easily divided into
# blocks. The XML file that contains recombinant edges is somewhat complicated.
# A full-fledged clonal origin XML parser is needed.
# 
# Two exemplary output files are:
# s10/1/data/core_alignment.xml
# s10/1/data/core_alignment.1.xmfa
# 
# SPECIES/REPETITION/core_alignment.xml
# SPECIES/REPETITION/core_alignment.REPLICATE.xmfa
# 
# SPECIES/REPETITION/core_alignment.REPLICATE.xmfa.BLOCKID
#
function divide-simulated-xmfa-data {
  PS3="Choose the simulation result of clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      SPECIESFILE=species/$SPECIES

      echo -n "  Reading REPLICATE from $SPECIESFILE..."
      HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
      if [ "$HOW_MANY_REPLICATE" == "" ]; then
        HOW_MANY_REPLICATE=0
        echo " $HOW_MANY_REPLICATE"
        echo "  No Replicate is specified at $SPECIESFILE!" 
        echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
        read REPLICATE
      else
        echo " $HOW_MANY_REPLICATE"
      fi

      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"

      echo -n "  Reading INBLOCK from $SPECIESFILE..."
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      echo " $INBLOCK"
     
      echo -n "  Counting blocks from $INBLOCK..."
      NUMBER_BLOCK=$(echo `cat simulation/$INBLOCK | wc -l`)
      echo " $NUMBER_BLOCK"

      echo -n "  Reading NUMBER_SPECIES from $SPECIESFILE..."
      NUMBER_SPECIES=$(grep NumberSpecies $SPECIESFILE | cut -d":" -f2)
      echo " $NUMBER_SPECIES"

      echo "  Dividing XML files of replicate ${REPLICATE}..."
      BASEDIR=$OUTPUTDIR/$SPECIES
      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
        NUMBERDIR=$BASEDIR/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        RUNANALYSIS=$NUMBERDIR/run-analysis
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
        for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          CORE_ALIGNMENT=core_alignment.$h.xmfa
          rm -f $DATADIR/$CORE_ALIGNMENT.*
          perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT
        done
      done
      break
    fi
  done
}

