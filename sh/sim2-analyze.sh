# Author: Sang Chul Choi
# Date  : Wed Apr 20 21:50:15 EDT 2011

# Analyzes the 2nd stage of clonal origin simulation
# --------------------------------------------------
# 1. The number of recombinant edges.
# 2. The count for heat map.
# 3. The recombination intensity.
# I need to come back here because I need to change wargsim to simulate data
# given recombinant edges.

function sim2-analyze {
  PS3="Choose the simulation result of clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s12" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis

      echo -n 'Do you wish to skip extracting recombination from inferred ones? (y/n) '
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
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

            # Files that we need to compare.
            if [ "$g" == 1 ] && [ "$REPLICATE" == 1 ]; then
              #perl pl/extractClonalOriginParameter10.pl \
              perl pl/compute-heatmap-recedge.pl \
                -d $RUNCLONALORIGIN/output2/$REPLICATE \
                -n $NUMBER_BLOCK \
                -s $NUMBER_SPECIES \
                -obsonly \
                -endblockid \
                > $BASERUNANALYSIS/$SPECIES-heatmap.txt # obsonly?
              echo "Creating $BASERUNANALYSIS/$SPECIES-heatmap.txt"
            else
              perl pl/compute-heatmap-recedge.pl \
                -d $RUNCLONALORIGIN/output2/$REPLICATE \
                -n $NUMBER_BLOCK \
                -s $NUMBER_SPECIES \
                -obsonly \
                -endblockid \
                >> $BASERUNANALYSIS/$SPECIES-heatmap.txt # obsonly?
              echo "Appending $BASERUNANALYSIS/$SPECIES-heatmap.txt"
            fi
            echo "Repeition $g - $REPLICATE"
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

      extract_heatmap \
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

function extract_heatmap {
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
      #perl pl/extractClonalOriginParameter10.pl \
      perl pl/compute-heatmap-recedge.pl \
        -d $XMLBASE \
        -n $NUMBER_BLOCK \
        -s $NUMBER_SPECIES \
        -endblockid \
        -obsonly \
        -xmlbasename $XMLFILEBASE \
        > $BASERUNANALYSIS/$SPECIES-$ISTRUE-heatmap.txt
    else
      #perl pl/extractClonalOriginParameter10.pl \
      perl pl/compute-heatmap-recedge.pl \
        -d $XMLBASE \
        -n $NUMBER_BLOCK \
        -s $NUMBER_SPECIES \
        -endblockid \
        -obsonly \
        -xmlbasename $XMLFILEBASE \
        >> $BASERUNANALYSIS/$SPECIES-$ISTRUE-heatmap.txt
      fi
    echo "Repeition $g"
  done
}
