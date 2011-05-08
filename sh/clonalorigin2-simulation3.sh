# Author: Sang Chul Choi
# Date  : Wed May  4 14:06:18 EDT 2011

# Simulation of map tree topology
# --------------------------------------------------
# 
function clonalorigin2-simulation3 {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "sxx" ]; then
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
 
      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis

      echo -n 'Do you wish to skip extracting recombination intensity? (y/n) '
      read SKIP
      if [ "$SKIP" == "y" ]; then
        echo "  Skipping copy of the output files because I've already copied them ..."
      else
        echo "Extracting the recombination events from ${HOW_MANY_REPETITION} XML files"
        echo "  of replicate ${REPLICATE}..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            if [ "$g" == 1 ] && [ "$REPLICATE" == 1 ]; then
              perl pl/$FUNCNAME.pl \
                -d $RUNCLONALORIGIN/output2/$REPLICATE \
                -xmfa $DATADIR/core_alignment.$REPLICATE.xmfa \
                -genelength $GENELENGTH \
                -inblock simulation/$INBLOCK \
                -endblockid \
                > $BASERUNANALYSIS/ri.txt
              echo -ne "Creating $BASERUNANALYSIS/ri.txt "
            else
              perl pl/$FUNCNAME.pl \
                -d $RUNCLONALORIGIN/output2/$REPLICATE \
                -xmfa $DATADIR/core_alignment.$REPLICATE.xmfa \
                -genelength $GENELENGTH \
                -inblock simulation/$INBLOCK \
                -endblockid \
                >> $BASERUNANALYSIS/ri.txt
              echo -ne "Appending $BASERUNANALYSIS/ri.txt "
            fi
            echo -ne "Repeition $g - $REPLICATE\r"
          done
        done
      fi

      echo -n 'Do you wish to skip dividing true recombination? (y/n) '
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
        echo "  Skipping ..."
      else
        echo "  Dividing the true value of recombination..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          perl pl/extractClonalOriginParameter9.pl \
            -xml $DATADIR/core_alignment.xml
        done
      fi 

      extract_ri \
        yes \
        $REPLICATE \
        $HOW_MANY_REPETITION \
        core_alignment
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}

function extract_ri {
  ISTRUE=$1
  REPLICATE=$2
  HOW_MANY_REPETITION=$3
  WHATXMLFILEBASE=$4

  echo "Extracting the recombination events from ${HOW_MANY_REPETITION} XML files"
  echo "  of replicate ${REPLICATE}..."
  for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=$BASEDIR/$g
    DATADIR=$NUMBERDIR/data
    RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
    RUNANALYSIS=$NUMBERDIR/run-analysis
    CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
    CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

    if [ "$ISTRUE" == "yes" ]; then
      XMLBASE=$DATADIR
      XMLFILEBASE=$WHATXMLFILEBASE
      XMLFILE=$XMLBASE/$XMLFILEBASE.xml.1
      HEATFILE=$XMLBASE/${SPECIES}_${g}_heatmap-1.txt
    else
      XMLBASE=$RUNCLONALORIGIN/output2/$REPLICATE
      XMLFILEBASE=$WHATXMLFILEBASE
      XMLFILE=$XMLBASE/$XMLFILEBASE.1.xml
      HEATFILE=$XMLBASE/heatmap-1.txt
    fi

    # Files that we need to compare.
    if [ "$g" == 1 ]; then
      perl pl/analyze-run-clonalorigin2-simulation2.pl \
        -d $XMLBASE \
        -xmfa $DATADIR/core_alignment.1.xmfa \
        -genelength $GENELENGTH \
        -inblock simulation/$INBLOCK \
        -endblockid \
        -xmlbasename $XMLFILEBASE \
        > $BASERUNANALYSIS/ri-$ISTRUE.txt
    else
      perl pl/analyze-run-clonalorigin2-simulation2.pl \
        -d $XMLBASE \
        -xmfa $DATADIR/core_alignment.1.xmfa \
        -genelength $GENELENGTH \
        -inblock simulation/$INBLOCK \
        -endblockid \
        -xmlbasename $XMLFILEBASE \
        >> $BASERUNANALYSIS/ri-$ISTRUE.txt
      fi
    echo "Repeition $g"
  done
}
