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

      echo -n "Do you wish to compute recombination intensity on genes with (y/n)? "
      RIMAPGENE=$RUNANALYSIS/rimap.gene
      read WISH
      if [ "$WISH" == "y" ]; then
        echo perl pl/$FUNCNAME.pl \
          rimap \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -ri1map $RUNANALYSIS/rimap.txt \
          -ingene $RUNANALYSIS/in.gene.$REFGENOME.block \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RIMAPGENE.all
        echo "Check file $RIMAPGENE.all"
        echo perl pl/$FUNCNAME.pl \
          rimap \
          -pairm topology \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -ri1map $RUNANALYSIS/rimap.txt \
          -ingene $RUNANALYSIS/in.gene.$REFGENOME.block \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RIMAPGENE.topology
        echo "Check file $RIMAPGENE.topology"
        echo perl pl/$FUNCNAME.pl \
          rimap \
          -pairm notopology \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -ri1map $RUNANALYSIS/rimap.txt \
          -ingene $RUNANALYSIS/in.gene.$REFGENOME.block \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RIMAPGENE.notopology
        echo "Check file $RIMAPGENE.notopology"
        echo perl pl/$FUNCNAME.pl \
          rimap \
          -pairm pair \
          -pairs 0,3:0,4:1,3:1,4 \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -ri1map $RUNANALYSIS/rimap.txt \
          -ingene $RUNANALYSIS/in.gene.$REFGENOME.block \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RIMAPGENE.sde2spy
        echo "Check file $RIMAPGENE.sde2spy"
        echo perl pl/$FUNCNAME.pl \
          rimap \
          -pairm pair \
          -pairs 3,0:4,0:3,1:4,1 \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -ri1map $RUNANALYSIS/rimap.txt \
          -ingene $RUNANALYSIS/in.gene.$REFGENOME.block \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RIMAPGENE.spy2sde
        echo "Check file $RIMAPGENE.spy2sde"
      else
        echo -e "  Skipping counting number of gene tree topology changes..." 
      fi
      break

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

