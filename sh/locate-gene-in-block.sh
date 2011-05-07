# Author: Sang Chul Choi
# Date  : Fri May  6 23:14:34 EDT 2011

function locate-gene-in-block {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      INGENE=$RUNANALYSIS/in.gene
      COREALIGNMENT=$(grep COREALIGNMENT conf/README | cut -d":" -f2)
      REFGENOME=$(grep REPETITION${REPETITION}-REFGENOME $SPECIESFILE | cut -d":" -f2)

      echo "Locating genes of $INGENE in the $REFGENOME ..."
      perl pl/$FUNCNAME.pl \
        -ingene $INGENE \
        -xmfa $DATADIR/$COREALIGNMENT \
        -refgenome $REFGENOME \
        -printseq
      echo "File $INGENE is appended!"
      break
    fi
  done
}


