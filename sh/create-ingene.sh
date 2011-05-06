# Author: Sang Chul Choi
# Date  : Thu May  5 16:05:45 EDT 2011

# Create
# ---------------------------------------------------
# This function must be called in the main run.sh. Variables would make sense
# only in that situtiaon. The funciton alone would not work.
function create-ingene {
  PS3="Choose the simulation for $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      read-species
      echo -n "What is the length of a genome? "
      read GENOMELENGTH
      echo -n "What is the equal length of a gene? "
      read GENELENGTH
      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      perl pl/create-ingene.pl \
        -genelength $GENELENGTH \
        -genomelength $GENOMELENGTH \
        > $BASERUNANALYSIS/in.gene
      echo "File $BASERUNANALYSIS/in.gene is created!"
      break
    fi
  done
}


