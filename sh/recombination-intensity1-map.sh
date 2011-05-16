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

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      echo -e "  The number of blocks is $NUMBER_BLOCK."
      echo "-------------------------------------"
      cat data/$SPECIES
      echo "-------------------------------------"
      echo -n "What is the reference genome? (e.g., 1) " 
      read REFGENOME
      echo -n "What is the length of the reference genome? " 
      read REFGENOMELENGTH
       
      echo perl pl/$FUNCNAME.pl \
        -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
        -xmfa $DATADIR/core_alignment.xmfa \
        -refgenome $REFGENOME \
        -refgenomelength $REFGENOMELENGTH \
        -numberblock $NUMBER_BLOCK \
        -verbose \
        $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt
        #> $RUNANALYSIS/ri1-map.txt
      break
    fi
  done
}

