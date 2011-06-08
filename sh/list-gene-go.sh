# Author: Sang Chul Choi
# Date  : Wed Jun  8 09:48:51 EDT 2011

function list-gene-go {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
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

      # Put these in the config or cornellf
      if [ "$SPECIES" != "cornellf" ]; then
        echo "SPECIES must be cornellf"
        break
      fi

      echo -n "What is the gene ontology term (use double quotations if spaces are needed)? (e.g., \"rRNA binding\") "
      read GODESC

      DESC2GO=data/SpyMGAS315_go_category_names.txt
      GO2GENE=data/SpyMGAS315_go_bacteria.txt
      GENE2PRODUCT=data/NC_004070.gbk

      echo "Locating genes of $INGENE in the $REFGENOME ..."
      echo perl pl/$FUNCNAME.pl \
        -godesc $GODESC \
        -desc2go $DESC2GO \
        -go2gene $GO2GENE \
        -gene2product $GENE2PRODUCT 
      break
    fi
  done
}


