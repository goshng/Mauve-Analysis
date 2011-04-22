# Author: Sang Chul Choi
# Date  : Wed Apr 20 21:50:15 EDT 2011

# Divides a clonal origin XML file into as many as blocks.
# --------------------------------------------------------
# A simulation with clonal origin generates an alignment and a clonal frame with
# recombinant edges attatched to it. The alignment was easily divided into
# blocks. The XML file that contains recombinant edges is somewhat complicated.
# A full-fledged clonal origin XML parser is needed.
# 
# Two exemplary output files are:
# s9/1/data/s9_1_core_alignment.xml
# s9/1/data/s9_1_core_alignment.xmfa
# 
function divide-simulated-xml-data {
  PS3="Choose the simulation result of clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s8" ]; then
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE
      #set-more-global-variable $SPECIES $REPETITION

      SPECIESFILE=species/$SPECIES
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

        XMLFILE=${SPECIES}_${REPLICATE}_core_alignment.xml

        # Compute prior expected number of recedges.
        if [ -f "$RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.1.xml" ]; then
          $GUI -b \
            -o $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.1.xml \
            -H 3 \
            > $RUNCLONALORIGIN/output2/${REPLICATE}/heatmap-1.txt
        else
          echo "Block: $i was not used" 1>&2
        fi

        # Files that we need to compare.
        if [ "$g" == 1 ]; then
          perl pl/extractClonalOriginParameter8.pl \
            -d $RUNCLONALORIGIN/output2/$REPLICATE \
            -e $RUNCLONALORIGIN/output2/$REPLICATE \
            -n $NUMBER_BLOCK \
            -s $NUMBER_SPECIES \
            > $RUNANALYSIS/$SPECIES-heatmap.txt
        else
          perl pl/extractClonalOriginParameter8.pl \
            -d $RUNCLONALORIGIN/output2/$REPLICATE \
            -e $RUNCLONALORIGIN/output2/$REPLICATE \
            -n $NUMBER_BLOCK \
            -s $NUMBER_SPECIES \
            >> $RUNANALYSIS/$SPECIES-heatmap.txt
        fi
        echo "Repeition $g"

        #perl $PERLGUIPERL -in $RUNCLONALORIGIN/output2/heatmap-$i.txt
        # Use the phase 3 xml file to count the number of recombination
        # events. For all possible pairs of 9 (5*2 - 1) find the number of
        # recedges, and divide it by the number of sample size or number
        # of <Iteration> tags. I need total length of the blocks and each
        # block length to weight the odd ratio of the averge observed number
        # of recedges and the prior expected number of recedges.
        # ECOP2 and PERLGUIPERL can be merged.  PERLGUIPERL is rather simple.
        # ECOP2 can be extened. Let's make ECOP4.
      done

      echo "Summarizing the three parameters..."
      #analyze-run-clonalorigin-simulation-s1-rscript \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      echo "Refer to the file for median values of the three parameters."

      # output/s8/1/data/s8_1_core_alignment.xml
      # output/s9/1/data/s9_1_core_alignment.xml
      #perl pl/extractClonalOriginParameter9.pl \
      
      break
    elif [ "$SPECIES" == "s2" ] \
         || [ "$SPECIES" == "s3" ] \
         || [ "$SPECIES" == "s4" ] \
         || [ "$SPECIES" == "s5" ] \
         || [ "$SPECIES" == "s6" ] \
         || [ "$SPECIES" == "s7" ]; then
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE
      SPECIESFILE=species/$SPECIES
      echo "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)

      echo -n "  Reading INBLOCK from $SPECIESFILE..."
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      echo " $INBLOCK"
      # NUMBER_BLOCK=411
      NUMBER_BLOCK=`wc -l < simulation/$INBLOCK`
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      NUMBER_SAMPLE=101 

      echo "Extracting the 3 parameters from ${HOW_MANY_REPETITION} XML files"
      echo "  of replicate ${REPLICATE}..."
      BASEDIR=$OUTPUTDIR/$SPECIES

      #echo "Summarizing the three parameters..."
      #analyze-run-clonalorigin-simulation-s2-rscript \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      #echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      #echo "Refer to the file for median values of the three parameters."
      #break

      #BLOCK_ALLREPETITION=()
      #for b in `$SEQ $NUMBER_BLOCK`; do
        #NOTALLREPETITION=0
        #for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
          #NUMBERDIR=$BASEDIR/$g
          #DATADIR=$NUMBERDIR/data
          #RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          #RUNANALYSIS=$NUMBERDIR/run-analysis
          #CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          #CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          #FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml)
          #if [[ "$FINISHED" =~ "outputFile" ]]; then
            ## NOTALLREPETITION=1
            #NOTALLREPETITION=1 # This should be something else.
          #else 
            #NOTALLREPETITION=1
          #fi
        #done
        #if [ "$NOTALLREPETITION" == 0 ]; then
          ## Add the block to the analysis
          #BLOCK_ALLREPETITION=("${BLOCK_ALLREPETITION[@]}" $b)
        #fi 
      #done

      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        NUMBERDIR=$BASEDIR/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        RUNANALYSIS=$NUMBERDIR/run-analysis
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        # Files that we need to compare.
        #for b in ${BLOCK_ALLREPETITION[@]}; do
        for b in `$SEQ $NUMBER_BLOCK`; do
          ECOP="pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml \
            -out $BASEDIR/run-analysis/out"
          FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml)
          if [[ "$FINISHED" =~ "outputFile" ]]; then
            if [ "$g" == 1 ] && [ "$b" == 1 ]; then
              ECOP="$ECOP -nonewline"
              #echo perl $ECOP
              #continue
            else
              if [ "$b" == $NUMBER_BLOCK ]; then
                ECOP="$ECOP -firsttab -append"
              elif [ "$b" != 1 ]; then
                ECOP="$ECOP -firsttab -nonewline -append" 
              elif [ "$b" == 1 ]; then
                ECOP="$ECOP -nonewline -append" 
              else
                echo "Not possible block $b"
                exit
              fi
            fi
            perl $ECOP
          else
            LENGTHBLOCK=$(perl pl/compute-block-length.pl \
              -base $DATADIR/${SPECIES}_${g}_core_alignment.xmfa \
              -block $b)
            echo "NOTYETFINISHED $g $b $LENGTHBLOCK" >> 1
          fi
        done
      done

      #break
      echo "Summarizing the three parameters..."
      analyze-run-clonalorigin-simulation-s2-rscript \
        $BASEDIR/run-analysis/out \
        $BASEDIR/run-analysis/out.R \
        $HOW_MANY_REPETITION \
        $NUMBER_BLOCK \
        $NUMBER_SAMPLE 
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R \
      echo "  $BASEDIR/run-analysis/out.R.out is created!"
      echo "Refer to the file for median values of the three parameters."
      cat $BASEDIR/run-analysis/out.R.out
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}


