# Author: Sang Chul Choi
# Date  : Wed Apr 27 16:45:56 EDT 2011

function map-tree-topology {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) " 
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      echo -e "  The number of blocks is $NUMBER_BLOCK."

      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1|wc -l`)
      echo -e "  The posterior sample size is $NUMBER_SAMPLE."

      # For each XML result for a block
      #  -d $RUNCLONALORIGIN/output2/${REPLICATE}
      #  output/cornellf/8/run-clonalorigin/output2/2/core_co.phase3.xml.1
      #  REPETITION=8, REPLICATE=2, BLOCK=1
      #  Split the XML file into as many XML files as iterations.
      #  output/cornellf/8/run-clonalorigin/output2/ri-2/core_co.phase3.xml.1.xxx
      # WARGSIM would read in each of the XML file to generate a local gene
      # tree.
      # $RUNCLONALORIGIN/output2/$REPLICATE
      echo -n "Do you want to skip splitting xml output (y/n)? "
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
        echo "  Skipping downloading clonalorigin xml output files..."
      else
        echo -n "  Splitting clonalorigin xml output files..."
        mkdir -p $RUNCLONALORIGIN/output2/ri-$REPLICATE
        echo perl pl/splitCOXMLPerIteration.pl \
          -d $RUNCLONALORIGIN/output2/$REPLICATE \
          -outdir $RUNCLONALORIGIN/output2/ri-$REPLICATE \
          -numberblock $NUMBER_BLOCK 
        echo " done."
      fi

      # Find the local gene trees along each of block alignments.
      # WARGSIM=src/clonalorigin/b/wargsim
      echo -n "Do you want to skip generating local trees (y/n)? "
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
        echo -e "  Skipping generating local trees..." 
      else
        echo -e "  Generating local trees..." 
        mkdir -p $RUNCLONALORIGIN/output2/ri-$REPLICATE-out
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for g in $(eval echo {1..$NUMBER_SAMPLE}); do
            BLOCKSIZE=$(echo `perl pl/get-block-length.pl $RUNCLONALORIGIN/output2/ri-$REPLICATE/core_co.phase3.xml.$b.$g`) 
            $WARGSIM --xml-file $RUNCLONALORIGIN/output2/ri-$REPLICATE/core_co.phase3.xml.$b.$g \
              --gene-tree \
              --out-file $RUNCLONALORIGIN/output2/ri-$REPLICATE-out/core_co.phase3.xml.$b.$g \
              --block-length $BLOCKSIZE
            echo -ne " done - block $b - $g\r"
          done
          echo -ne "                                           \r"
        done
      fi
      # Combine ri-2-out's files for a block.
      # Analyze those files with a perl script.

      echo -e "  Combining ri-$REPLICATE-out ..." 
      RIBLOCKFILES="" 
      for b in $(eval echo {1..$NUMBER_BLOCK}); do
        RIFILES=""
        RIBLOCKFILE="$RUNCLONALORIGIN/output2/ri-$REPLICATE-out/$b"
        for g in $(eval echo {1..$NUMBER_SAMPLE}); do
          if [ "$g" != "211" ] && [ "$g" != "212" ] && [ "$g" != "719" ] && [ "$g" != "720" ]; then
            RIFILES="$RIFILES $RUNCLONALORIGIN/output2/ri-$REPLICATE-out/core_co.phase3.xml.$b.$g"
          else
            echo -en "$b $g not used\r"
          fi
        done
        RIBLOCKFILES="$RIBLOCKFILES $RIBLOCKFILE"
        cat $RIFILES > $RIBLOCKFILE
        rm $RIFILES
        echo -en "Block $b\r"
      done
      paste $RIBLOCKFILES > $RUNANALYSIS/$FUNCNAME-${REPLICATE}.txt
      rm $RIBLOCKFILES
      echo "Check file $RUNANALYSIS/$FUNCNAME-${REPLICATE}.txt"


break
      echo -e "  Combining ri-$REPLICATE-out ..." 
      for b in $(eval echo {1..$NUMBER_BLOCK}); do
        for g in $(eval echo {1..$NUMBER_SAMPLE}); do
          BLOCKSIZE=$(echo `perl pl/get-block-length.pl $RUNCLONALORIGIN/output2/ri-$REPLICATE/core_co.phase3.xml.$b.$g`) 
          NUM=$(wc $RUNCLONALORIGIN/output2/ri-$REPLICATE-out/core_co.phase3.xml.$b.$g|awk {'print $2'})
          if [ "$NUM" != "$BLOCKSIZE" ]; then
            echo "$b $g not okay"
          fi
        done
        echo -en "Block $b\r"
      done
 
break

      break

      # 
      perl pl/$FUNCNAME.pl \
        -d $RUNCLONALORIGIN/output2/${REPLICATE} \
        -xmfa $DATADIR/core_alignment.xmfa \
        -speciesfile species/$SPECIES \
        -genomedir $GENOMEDATADIR \
        -r 1 \
        -verbose \
        -numberblock $NUMBER_BLOCK \
        > $RUNANALYSIS/$FUNCNAME-${REPLICATE}.txt
      echo "Check file $RUNANALYSIS/$FUNCNAME-${REPLICATE}.txt"
      break
    fi
  done
}

