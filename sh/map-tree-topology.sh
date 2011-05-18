# Author: Sang Chul Choi
# Date  : Wed Apr 27 16:45:56 EDT 2011

function map-tree-topology {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
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

      echo -n "  Reading TREETOPOLOGY of REPETITION$REPETITION from $SPECIESFILE..."
      TREETOPOLOGY=$(grep REPETITION$REPETITION-TREETOPOLOGY $SPECIESFILE | cut -d":" -f2)
      echo " $TREETOPOLOGY"

      echo -n "Do you wish to split xml output (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -n "  Splitting clonalorigin xml output files..."
        mkdir -p $RUNCLONALORIGIN/output2/ri-$REPLICATE
        perl pl/splitCOXMLPerIteration.pl \
          -d $RUNCLONALORIGIN/output2/$REPLICATE \
          -outdir $RUNCLONALORIGIN/output2/ri-$REPLICATE \
          -numberblock $NUMBER_BLOCK \
          -endblockid
        echo " done."
      else
        echo "  Skipping splitting ClonalOrigin xml output files..."
      fi


      # Find the local gene trees along each of block alignments.
      # WARGSIM=src/clonalorigin/b/wargsim
      echo -n "Do you wish to generate local trees (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Generating local trees..." 
        mkdir -p $RUNCLONALORIGIN/output2/ri-$REPLICATE-out
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for g in $(eval echo {1..$NUMBER_SAMPLE}); do
            BLOCKSIZE=$(echo `perl pl/get-block-length.pl $RUNCLONALORIGIN/output2/ri-$REPLICATE/core_co.phase3.xml.$b.$g`) 
            $WARGSIM --xml-file $RUNCLONALORIGIN/output2/ri-$REPLICATE/core_co.phase3.xml.$b.$g \
              --gene-tree \
              --out-file $RUNCLONALORIGIN/output2/ri-$REPLICATE-out/core_co.phase3.xml.$b.$g \
              --block-length $BLOCKSIZE
            echo -ne "block $b - $g\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping generating local trees..." 
      fi
      # Combine ri-2-out's files for a block.
      # Analyze those files with a perl script.

      echo -n "Do you wish to check topology map files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
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
      else
        echo -e "  Skipping checking topology map files ..." 
      fi 

      echo -n "Do you wish to combine topology map files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Combining ri-$REPLICATE-out ..." 
        mkdir -p $RUNCLONALORIGIN/output2/ri-$REPLICATE-combined
        RIBLOCKFILES="" 
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          RIFILES=""
          RIBLOCKFILE="$RUNCLONALORIGIN/output2/ri-$REPLICATE-combined/$b"
          for g in $(eval echo {1..$NUMBER_SAMPLE}); do
            #if [ "$g" != "211" ] && [ "$g" != "212" ] && [ "$g" != "719" ] && [ "$g" != "720" ]; then
              RIFILES="$RIFILES $RUNCLONALORIGIN/output2/ri-$REPLICATE-out/core_co.phase3.xml.$b.$g"
            #else
              #echo -en "$b $g not used\r"
            #fi
          done
          RIBLOCKFILES="$RIBLOCKFILES $RIBLOCKFILE"
          cat $RIFILES > $RIBLOCKFILE
          echo -en "Block $b\r"
        done
        #paste $RIBLOCKFILES > $RUNANALYSIS/$FUNCNAME-${REPLICATE}.txt
        echo "Check files in $RUNCLONALORIGIN/output2/ri-$REPLICATE-combined"
      else
        echo -e "  Skipping combining topology map files ..." 
      fi

      echo -n "Do you wish to count gene tree topology changes (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME.pl \
          -ricombined $RUNCLONALORIGIN/output2/ri-$REPLICATE-combined \
          -ingene $RUNANALYSIS/in.gene \
          -treetopology $TREETOPOLOGY 
        echo "Check file $RUNANALYSIS/in.gene"
      else
        echo -e "  Skipping counting number of gene tree topology changes..." 
      fi

      break
    fi
  done
}

