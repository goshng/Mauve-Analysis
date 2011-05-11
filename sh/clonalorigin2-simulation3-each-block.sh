#!/bin/bash

function clonalorigin2-simulation3-each-block {
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
      SPECIESFILE=species/$SPECIES
      echo -n "What is REPETITION? "
      read REPETITION
      echo -n "What is REPLICATE? "
      read REPLICATE
      echo -n "What is BLOCK? "
      read BLOCK
      echo -n "What is BLOCK SIZE? "
      read BLOCKSIZE

      BASEDIR=output/$SPECIES
      TREE=$BASEDIR/$REPETITION/run-clonalorigin/input/$REPLICATE/cornellf-8.tree
      XMFA=$BASEDIR/$REPETITION/data/core_alignment.$REPLICATE.xmfa.$BLOCK
      XML=$BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCK
      XMLMTDIR=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE
      XMLMT=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE/core_co.phase3.xml.$BLOCK
      XMLMTOUT=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE-out/core_co.phase3.xml.$BLOCK
      NUMBER_SAMPLE=$(echo `grep number $XML|wc -l`)

      warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
        -x 1000000 -y 1000000 -z 10000 \
        -T s0.0749323036174269 -D 614.149554455445 \
        -R s0.0137842770601471 $TREE $XMFA $XML

      mkdir $XMLMTDIR
      perl pl/clonalorigin2-simulation3-prepare.pl -xml $XML -out $XMLMT

      for g in $(eval echo {1..$NUMBER_SAMPLE}); do
        $WARGSIM --xml-file $XMLMT.$g --gene-tree --out-file $XMLMTOUT.$g --block-length $BLOCKSIZE

        NUMBERSITE=$(echo `cat $XMLMTOUT.$g|wc -w`)
        if [ "$NUMBERSITE" != "$BLOCKSIZE" ]; then
          echo "Problem in $XMLMTOUT.$g blocksize must be $BLOCKSIZE $NUMBERSITE"
        fi
        echo -ne "$g/$NUMBER_SAMPLE\r"
      done
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}

