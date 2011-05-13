
# 11. Prepare the first stage of clonalorigin for simulation.
# -----------------------------------------------------------
# This may change depending on what simulation setup I would go with.
# The first simulation set is called c1 at
# /Users/goshng/Documents/Projects/mauve/noweb/output/c1
# where there is an input directory. I want to have an output directory for
# that. I am not following the directory structure in the real data analysis.
# Instead, I will use the output directory. Replicates are stored in the output
# directory. I am concerned about that some duplicates of code can be generated.
# I think that that might be necessary. Why is this the case?
#
# mkdir-simulation: a run of a simulation study is stored in a directory,
# BASEDIR=$MAUVEANALYSISDIR/noweb/output/$CHOICE/output/${REPLICATE}
# The $CHOICE is c1, and $REPLICATE goes from 1 to as many replicates as you
# want. The same directories are created at the output directory in the cluster.
# 
# At the directory of 
# BASECHOICEDIR=$MAUVEANALYSISDIR/noweb/output/$CHOICE
# there is an input directory. A file with extension of fa is the alignment
# file: e.g., input/c1_1.fa 
# A file with extension of tre is the clonal tree. I need these two files to run
# ClonalOrigin. So, clonaltree.nwk is replaced by input/c1_1.tre 
# and core_alignment.xmfa is replaced by input/c1_1.fa.
# The core alignment needs to be split into blocks. Each block and the clonal
# tree are the input of a ClonalOrigin run. I have an arbitrary number of
# alignments. A batch script would read in the list to execute ClonalOrigin.
#
# I might have to simulate the setting of the real data set of the 5 genomes.
# Not only mutation rate, recombination rate, and tract length but also the
# number of blocks and their lengths. I might have to remove more blocks based
# on the proportion of gaps in alignments. 
#
# How can I submit jobs in the repetitions?
#
# First copy data and script to the login node of the cluster.
# Then, copy data and script to the computing node thereof.
#
# The cluster is not down now. I have to check the script.
# Let's check the code from beginning to the end.
#
# s1 is the first simulation study. I simulate a single block of 10k base pairs
# under ClonalOrigin model. I need multiple replicates to check convergence.
# CHOICE and HOW_MANY_REPETITION could be determined using directories and file
# in species, and output directories. 
# Later I need a way to check convergence of replicates.
# 
# BASEDIR:
# mauve/output/cornell
# NUMBERDIR:
# mauve/output/cornell/1/data
# DATADIR:
# mauve/output/cornell/1/data
# RUNMAUVE:
# mauve/output/cornell/1/run-mauve
# 
# For each repeat I do the following:
# 1. Split the core alignment.
# 2. Copy the split alignments to CAC cluster.
# 3. Copy the species tree to CAC cluster.
# 4. Make a list of jobs. A job is specified by command line
#    options of warg.
# 5. Create a batch file for each repeat.
#
# Finishing the above I make a list of jobs over all the repeats. I also create
# the main batch script for the jobs of all the repeats.
function simulate-data-clonalorigin1-prepare {
  PS3="Choose a menu of simulation with clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ]; then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE

      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do   
        NUMBERDIR=$OUTPUTDIR/$SPECIES/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALFRAME=$NUMBERDIR/run-clonalframe
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        mkdir -p $RUNCLONALORIGIN/output/${REPLICATE}
        mkdir -p $RUNCLONALORIGIN/output2/${REPLICATE}
        mkdir -p $RUNCLONALORIGIN/input/${REPLICATE}
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_DATADIR=$CAC_NUMBERDIR/data
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        ssh -x $CAC_USERHOST \
          mkdir -p $CAC_RUNCLONALORIGIN/input/${REPLICATE}

        # I already have the tree.
        cp data/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE

        #echo "  Splitting alignment into files per block..."
        CORE_ALIGNMENT=core_alignment.$REPLICATE.xmfa
        #rm -f $DATADIR/$CORE_ALIGNMENT.*
        #perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT

        #send-clonalorigin-input-to-cac
        echo "  Copying the split alignments..."
        scp -q $DATADIR/$CORE_ALIGNMENT.* \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/data

        echo "  Copying the input species tree..."
        scp -q $RUNCLONALORIGIN/input/${REPLICATE}/$SPECIESTREE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/run-clonalorigin/input/${REPLICATE}

      done

      echo "  Make a script for submitting jobs for all the repetitions."
      make-run-list $HOW_MANY_REPETITION \
        $OUTPUTDIR/$SPECIES \
        $REPLICATE \
        $SPECIESTREE \
        > $OUTPUTDIR/$SPECIES/jobidfile
      scp -q $OUTPUTDIR/$SPECIES/jobidfile $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES
      copy-run-sh $OUTPUTDIR/$SPECIES \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES \
        $SPECIES \
        $HOW_MANY_REPETITION \
        $SPECIESTREE
 
      break
    fi
  done
}

