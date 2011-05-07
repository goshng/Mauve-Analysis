# Author: Sang Chul Choi
# Date  : Fri May  6 20:34:17 EDT 2011

function convert-gff-ingene {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      GFF=$(grep REPETITION${REPETITION}-GFF $SPECIESFILE | cut -d":" -f2)
      GFF=$GENOMEDATADIR/$GFF
      OUT=$RUNANALYSIS/in.gene
      echo "Coverting $GFF to $OUT ..."
      perl pl/$FUNCNAME.pl \
        -gff $GFF \
        -out $OUT
      echo "File $OUT is created!"
      break
    fi
  done
}


