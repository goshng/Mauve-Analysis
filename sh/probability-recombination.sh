# Author: Sang Chul Choi
# Date  : Wed Apr 27 12:48:53 EDT 2011

function probability-recombination {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in `ls species`; do 
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

      echo perl pl/recombination-intensity3.pl \
        -d $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
        -xmfa $DATADIR/core_alignment.xmfa \
        -r 1 \
        -coords simulation/sde1.coords.txt \
        $RUNANALYSIS/recombination-intensity.txt
        #> $RUNANALYSIS/recombination-intensity.txt
      break
    fi
  done
}

