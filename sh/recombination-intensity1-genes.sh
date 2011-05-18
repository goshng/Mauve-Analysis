# Author: Sang Chul Choi
# Date  : Sat May 14 21:33:31 EDT 2011

function recombination-intensity1-genes {
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

      echo -n "Do you wish to skip counting number of gene tree topology changes (y/n)? "
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
        echo -e "  Skipping counting number of gene tree topology changes..." 
      else
        echo perl pl/$FUNCNAME.pl \
          -ri1map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -ingene $RUNANALYSIS/in.gene \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map.gene
        echo "Check file $RUNANALYSIS/ri1-refgenome$REFGENOME-map.gene"
      fi
      break
    fi
  done
}

