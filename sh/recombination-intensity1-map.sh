# Author: Sang Chul Choi
# Date  : Wed Apr 27 16:45:56 EDT 2011

function recombination-intensity1-map {
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

      NUMBER_BLOCK=$(trim $(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`))
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      echo "-------------------------------------"
      cat data/$SPECIES
      echo "-------------------------------------"
      echo -n "What is the reference genome? (e.g., 1) " 
      read REFGENOME
      echo -n "What is the length of the reference genome? " 
      read REFGENOMELENGTH

      echo -n "Do you wish to generate ri-map.txt? (e.g., y/n) "
      RIMAP=$RUNANALYSIS/rimap.txt
      read WISH
      if [ "$WISH" == "y" ]; then
        echo perl pl/$FUNCNAME.pl \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -numberblock $NUMBER_BLOCK \
          -verbose \
          -out $RIMAP
      else
        echo "  Skipping generating $RIMAP"
      fi
      exit
      
      echo -n "Do you wish to generate ri1-refgenome$REFGENOME-map.txt? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME.pl \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -refgenomelength $REFGENOMELENGTH \
          -numberblock $NUMBER_BLOCK \
          -verbose \
          > $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt
      else
        echo "  Skipping generating $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt"
      fi

      echo -n "Do you wish to generate ri1-refgenome$REFGENOME-map.wig? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME-wiggle.pl \
          -map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map.wig
        echo "  Generating $RUNANALYSIS/ri1-refgenome$REFGENOME.wig"
      else
        echo "  Skipping generating $RUNANALYSIS/ri1-refgenome$REFGENOME.wig"
      fi
      
      break
    fi
  done
}

