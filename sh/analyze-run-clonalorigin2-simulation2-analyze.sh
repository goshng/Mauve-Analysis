# Author: Sang Chul Choi
# Date  : Thu May  5 13:45:53 EDT 2011

# Analyzes the 2nd stage of clonal origin simulation
# --------------------------------------------------
#
function analyze-run-clonalorigin2-simulation2-analyze {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES

      echo -n "Do you wish to generate the true XML? (e.g., y/n) "
      read WANT
      if [ "$WANT" == "y" ]; then
        echo "Generating true XML..."
        for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
          RITRUE=$BASEDIR/$REPETITION/run-analysis/ri-yes
          mkdir -p $RITRUE
          for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
            perl pl/analyze-run-clonalorigin2-simulation2-prepare.pl \
              -xml $BASEDIR/$REPETITION/data/core_alignment.xml.$BLOCKID \
              -ingene $BASERUNANALYSIS/in.gene \
              -blockid $BLOCKID \
              -out $RITRUE/$BLOCKID
            echo -ne "$REPETITION/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK\r"
          done
        done
        echo "Find files at $BASEDIR/REPETITION#/run-analysis/ri-yes"
      else
        echo "Skipping generating true XML..."
      fi

      echo "Generating a table for plotting..."
      OUTFILE=$BASERUNANALYSIS/ri.txt
      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        RITRUE=$BASEDIR/$REPETITION/run-analysis/ri-yes
        for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
          PERLCOMMAND="perl pl/analyze-run-clonalorigin2-simulation2-analyze.pl \
            -true $RITRUE/$BLOCKID \
            -estimate $BASEDIR/$REPETITION/run-clonalorigin/output2/ri \
            -numberreplicate $HOW_MANY_REPLICATE \
            -block $BLOCKID \
            -out $OUTFILE"
          if [ "$REPETITION" != 1 ] || [ "$BLOCKID" != 1 ]; then
            PERLCOMMAND="$PERLCOMMAND -append"
          fi
          $PERLCOMMAND
          echo -ne "$REPETITION/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK\r"
        done
      done
      echo "Check $OUTFILE"
      
exit 

      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        RIFILES="" 
        RTFILE=$BASEDIR/$REPETITION/run-clonalorigin/output2/$REPETITION.rt
        for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          RIS="" 
          RIFILE=$BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE.ri
          for i in $(eval echo {1..$NUMBER_BLOCK}); do
            RIS="$RIS $BASEDIR/$REPETITION/run-clonalorigin/output2/ri-$REPLICATE/$i" 
          done
          paste $RIS > $RIFILE
          RIFILES="$RIFILES $RIFILE"
        done
        cat $RIFILES > $RTFILE
      done
    fi
    break
  done
}

