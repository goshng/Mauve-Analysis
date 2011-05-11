# Author: Sang Chul Choi
# Date  : Tue May 10 11:12:48 EDT 2011

function clonalorigin2-simulation3-analyze {
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
          MTTRUE=$BASEDIR/$REPETITION/data/mt-yes
          MTOUTTRUE=$BASEDIR/$REPETITION/run-analysis/mt-yes-out
          mkdir -p $MTTRUE
          mkdir -p $MTOUTTRUE
          for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
            perl pl/clonalorigin2-simulation3-prepare.pl \
              -xml $BASEDIR/$REPETITION/data/core_alignment.xml.$BLOCKID \
              -out $MTTRUE/core_alignment.xml.$BLOCKID 

            BLOCKSIZE=$(echo `perl pl/get-block-length.pl $BASEDIR/$REPETITION/data/core_alignment.xml.$BLOCKID`)
            NUMBER_SAMPLE=1
            for g in $(eval echo {1..$NUMBER_SAMPLE}); do
              $WARGSIM \
                --xml-file $MTTRUE/core_alignment.xml.$BLOCKID.$g \
                --gene-tree \
                --out-file $MTOUTTRUE/core_alignment.xml.$BLOCKID.$g \
                --block-length $BLOCKSIZE
            done
            echo -ne "$REPETITION/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK\r"
          done
        done
        echo "Find files at $BASEDIR/REPETITION#/run-analysis/mt-yes-out"
      else
        echo "Skipping generating true XML..."
      fi

      echo -n "Do you wish to check the XML? (e.g., y/n) "
      read WANT
      if [ "$WANT" == "y" ]; then
        echo "Checking XML..."
        for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
          for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            # MTTRUE=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE
            MTOUTTRUE=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE-out
            for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
              BLOCKSIZE=$(echo `perl pl/get-block-length.pl $BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID`)
              NUMBER_SAMPLE=$(echo `grep number $BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID|wc -l`)
              for g in $(eval echo {1..$NUMBER_SAMPLE}); do
                NUMBERSITE=$(echo `cat $MTOUTTRUE/core_co.phase3.xml.$BLOCKID.$g|wc -w`)
                if [ "$NUMBERSITE" != "$BLOCKSIZE" ]; then
                  echo "Problem in $MTOUTTRUE/core_co.phase3.xml.$BLOCKID.$g blocksize must be $BLOCKSIZE $NUMBERSITE"
                fi

                echo -ne "$REPETITION/$HOW_MANY_REPETITION - $REPLICATE/$HOW_MANY_REPLICATE - $BLOCKID/$NUMBER_BLOCK - $g/$NUMBER_SAMPLE\r"
              done
            done
          done
        done
      else
        echo "Skipping checking XML..."
      fi

      echo "Generating a table for plotting..."
      NUMBER_SAMPLE=$(echo `grep number $BASEDIR/1/run-clonalorigin/output2/1/core_co.phase3.xml.1|wc -l`)

      OUTFILE=$BASERUNANALYSIS/mt.txt
      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        MTOUTTRUE=$BASEDIR/$REPETITION/run-analysis/mt-yes-out
        for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do

          BLOCKSIZE=$(echo `perl pl/get-block-length.pl $BASEDIR/$REPETITION/data/core_alignment.xml.$BLOCKID`)

          PERLCOMMAND="perl pl/clonalorigin2-simulation3-analyze.pl \
            -true $MTOUTTRUE/core_alignment.xml.$BLOCKID \
            -estimate $BASEDIR/$REPETITION/run-clonalorigin/output2/mt \
            -numberreplicate $HOW_MANY_REPLICATE \
            -numbersample $NUMBER_SAMPLE \
            -block $BLOCKID \
            -blocklength $BLOCKSIZE \
            -ingene $BASERUNANALYSIS/in.gene \
            -treetopology 89 \
            -out $OUTFILE"
          if [ "$REPETITION" != 1 ] || [ "$BLOCKID" != 1 ]; then
            PERLCOMMAND="$PERLCOMMAND -append"
          fi
          $PERLCOMMAND
          echo -ne "$REPETITION/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK\r"
        done
      done
      echo "Check $OUTFILE"
    fi
    break
  done
}

