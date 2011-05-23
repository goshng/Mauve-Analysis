#!/bin/bash

function sim4-each-block {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species
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
      TREE=$BASEDIR/$REPETITION/run-clonalorigin/input/$REPLICATE/$SPECIESTREE
      XMFA=$BASEDIR/$REPETITION/data/core_alignment.$REPLICATE.xmfa.$BLOCK
      XML=$BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCK
      XMLMTDIR=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE
      XMLMT=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE/core_co.phase3.xml.$BLOCK
      XMLMTOUT=$BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE-out/core_co.phase3.xml.$BLOCK
      NUMBER_SAMPLE=$(echo `grep number $XML|wc -l`)

      warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
        -x $BURNIN -y $CHAINLENGTH -z $THIN \
        -T s$THETA_PER_SITE -D $DELTA \
        -R s$RHO_PER_SITE $TREE $XMFA $XML

      mkdir $XMLMTDIR
      perl pl/sim4-prepare.pl -xml $XML -out $XMLMT

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

