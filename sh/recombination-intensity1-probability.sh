# Author: Sang Chul Choi
# Date  : Wed May 25 22:14:43 EDT 2011

function recombination-intensity1-probability {
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

      echo -n "  Reading of REFGENOME of REPETITION$REPETITION from $SPECIESFILE..."
      REFGENOME=$(grep REPETITION$REPETITION-REFGENOME $SPECIESFILE | cut -d":" -f2)
      echo " $REFGENOME"

      echo -n "Do you wish to draw a graph of recombination probability (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo perl pl/$FUNCNAME.pl \
          -ri1map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -ingene $RUNANALYSIS/in.gene \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map
        echo "Check file $RUNANALYSIS/ri1-refgenome$REFGENOME-map.gene"
      else
        echo -e "  Skipping counting number of gene tree topology changes..." 
      fi
      break
    fi
  done
}

