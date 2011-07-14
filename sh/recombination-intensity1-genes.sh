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

      NUMBER_SAMPLE=$(trim $(echo `grep number $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1|wc -l`))
      REFGENOME=$(grep REPETITION$REPETITION-REFGENOME $SPECIESFILE | cut -d":" -f2)
      NUMBERSPECIES=$(grep REPETITION$REPETITION-NumberSpecies $SPECIESFILE | cut -d":" -f2)

      echo -n "Do you wish to compute recombination intensity on genes (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo perl pl/$FUNCNAME.pl \
          -ri1map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -ingene $RUNANALYSIS/in.gene \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -NUMBERSPECIES=$(grep REPETITION$REPETITION-NumberSpecies $SPECIESFILE | cut -d":" -f2)
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map.gene
        echo "Check file $RUNANALYSIS/ri1-refgenome$REFGENOME-map.gene"
      else
        echo -e "  Skipping counting number of gene tree topology changes..." 
      fi
      break
    fi
  done
}

