# Simulates data under ClonalOrigin model or ancestral recombination graph.
# -------------------------------------------------------------------------
# The run-lcb contains a list of core_alignment.xmfa.[NUMBER] files.
# Two kinds of data are generated. I could simulate the ClonalOrigin model to
# generate a single-block data set or a multiple-block data set. It would be
# better to use the same bash script structure as that of real data sets. I need
# an additional analysis step of comparing simulated results and their true
# values. I would use the same file structure as real data analysis. Is there a
# problem with that? I remember that there were some issues about this. There
# was a subtle issue of file structure of the main output directory. I would
# have a REPETITION under the SPECIES directory. REPETITION and REPLICATE would
# be confusing. I did not have REPETITON, but I used it: e.g., cornell5 and
# cornell5-1. Both of them use the same data set. One of them uses 419 or 415
# blocks, and another uses 411. Their filtering steps were different. From the
# view point of ClonalOrigin their data sets are different. Replicates are the
# same analyses but different in time or random seeds. Repetitions are similar
# analyses with differnt data.
# 
# After thinking over REPETITION and REPLICATE I decide to use a different
# output file structure. The main output directory still contains SPECIES
# directories. A SPECIES directory would contain directories named as numbers:
# i.e., 1, 2, 3 and so on. A numbered directory would contain directories such
# as run-mauve, run-clonalframe, run-clonalorigin, etc. This could change many
# parts of this main run.sh script. One issue that I was concerned about was how
# I could run multiple repeated analyses in a single batch script.
#
# Each sub-directory of a species directory contains shell scripts, one of which
# is called batch.sh. I used to execute it to submit jobs. Now, I wish to
# control jobs in multiple repetitions. Shell scripts may well be placed at the
# SPECIES directory. Doing so a batch script can let you submit jobs in REPETITON
# directories. The SPECIES directory would contain numbered directories, a shell
# script called run.sh, and a directory called sh that contains more scripts.
# The run.sh is the main shell script that would select one of commands
# available. The scripts in ``sh'' directory are for various specific scripts:
# e.g., run-mauve, run-clonalframe, run-clonalorigin. I will keep the batch scripts
# in these directories. I will have two levels of batch scripts: one at the
# SPECIES directory level, and the other at each run-xxx level.
# 
# Let's start with simulated data.
# 1. choose-species is the starting point of a real data analysis. For 
# simulation studies I might have a similar one for setting up directories. How
# about choose-simulation.
# 
# This function could be more generalized.
#
# REPLICATE in simulation might not make sense. I use it for copying a species
# tree. I may need to pick a tree somewhere else. The s1 or s2 text file in
# species directory might contain more specific information about their
# simulation setup.
#
function simulate-data-clonalorigin1 {
  PS3="Choose a simulation (e.g., s1): "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      #echo -e "Which replicate set of output files?"
      #echo -n "REPLICATE ID: " 
      #read REPLICATE

      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do 
        BASEDIR=$OUTPUTDIR/$SPECIES
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
        cp data/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE
        cp data/$INBLOCK $DATADIR

        echo -ne "  Simulating data under the ClonalOrigin model ..." 
        $WARGSIM --tree-file $RUNCLONALORIGIN/input/$REPLICATE/$SPECIESTREE \
          --block-file $DATADIR/$INBLOCK \
          --out-file $DATADIR/core_alignment \
          -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE

        perl pl/extractClonalOriginParameter9.pl \
          -xml $DATADIR/core_alignment.xml

        for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          CORE_ALIGNMENT=core_alignment.$h.xmfa
          rm -f $DATADIR/$CORE_ALIGNMENT.*
          perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT
        done

        echo -ne " done - repetition $g/$HOW_MANY_REPETITION\r"
      done
      break
    fi
  done
}
