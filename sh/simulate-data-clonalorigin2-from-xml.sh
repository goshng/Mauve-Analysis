# Author: Sang Chul Choi
# Date  : Tue Apr 26 15:44:57 EDT 2011

# Simulates data with Clonal Origin model.
# ----------------------------------------
# simulate-data-clonalorigin2 simulates the model with the 3 main parameters. It
# samples recombinant edges for a clonal frame. Given a set of recombinant edges
# a number of replicate data sets are generated. Here, I wish to use recombinant
# edges that were sampled from Clonal Origin inference with a real data set. For
# each iteration a clonal frame and its recombinant edges are sampled. Given the
# clonal frame and its recombinant edges I wish to simulate data. 
#
# Note: Gij is a set of recombinant edges of iteration i and block j. I combine
# Gij's of a particular iteration i over all the blocks. An XML file would be
# generated to contain Gij's for iteration i. This Gi is used to generate a
# number of replicate data sets. I used to divide an XML file with multiple
# blocks in some simulation (e.g., s11). Now, I need to combine multiple XML
# files.
#
# Note: An iteration becomes a repetition. A subsample of iterations are done.
# Each iteration becomes a repetition. I need to take REPETITIONS.
function simulate-data-clonalorigin2-from-xml {
  PS3="Choose a simulation (e.g., s1): "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      SPECIESFILE=species/$SPECIES

      echo -n "  Reading CLONALORIGINOUTPUT from $SPECIESFILE..."
      CLONALORIGINOUTPUT=$(grep ClonalOriginOutput2 $SPECIESFILE | cut -d":" -f2)
      echo " $CLONALORIGINOUTPUT"
 
      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"
      
      echo -n "  Reading REPLICATE from $SPECIESFILE..."
      HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPLICATE"

      echo -n "  Reading SPECIESTREE from $SPECIESFILE..."
      SPECIESTREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      echo " $SPECIESTREE - in.tree is used"
      SPECIESTREE=in.tree

      echo -n "  Reading INBLOCK from $SPECIESFILE..."
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      echo " $INBLOCK - in.block is used"
      INBLOCK=in.block

      echo -n "  Reading from $SPECIESFILE..."
      THETA_PER_SITE=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $THETA_PER_SITE"

      echo -n "  Reading from $SPECIESFILE..."
      RHO_PER_SITE=$(grep RhoPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $RHO_PER_SITE - not used"

      echo -n "  Reading from $SPECIESFILE..."
      DELTA=$(grep Delta $SPECIESFILE | cut -d":" -f2)
      echo " $DELTA - not used"

      BASEDIR=$OUTPUTDIR/$SPECIES
      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
      done

      echo "  Creating core_alignment.xml and in.block"
      echo "  Need to create tree file: in.tree"
      #perl pl/extractClonalOriginParameter11.pl \
        #-d $CLONALORIGINOUTPUT \
        #-speciesDir $BASEDIR \
        #-n $HOW_MANY_REPETITION

      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        echo -e "  Simulating data under the ClonalOrigin model ..." 
        echo -n "  delta and rho are not used ..." 
        $WARGSIM --xml-file $DATADIR/core_alignment.xml \
          --block-file $DATADIR/$INBLOCK \
          --out-file $DATADIR/core_alignment \
          --number-data $HOW_MANY_REPLICATE \
          -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE
        echo -e " done - repetition $g"
      done
      break
    fi
  done
}

