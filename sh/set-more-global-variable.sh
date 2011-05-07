###############################################################################
# Functions: naming more global variables
###############################################################################

# Structure directories.
# ----------------------
# Subdirectory names are stored in bash
# variables for convenient access to the names. This run.sh is placed in a
# subdirectory named sh. The main directory is $MAUVEANALYSISDIR. This
# run.sh file is executed at the main directory. Let's list directory variables
# and their usages. Refer to each variable in the following.
function set-more-global-variable {
  SPECIES=$1
  REPETITION_DIR=$2

  # SPECIES must be set before the call of this bash function. $SPECIESFILE
  # contains a list of Genbank formatted genome file names.
  SPECIESFILE=$MAUVEANALYSISDIR/species/$SPECIES

  # Number of species in the analysis. The species file can contain comment
  # lines starting with # character at the 1st column.
  NUMBER_SPECIES=$(grep -v "^#" data/$SPECIES | wc -l)

  # The subdirectory output contains directories named after the species file.
  # The output species directory would contain all of the results from the
  # analysis.
  # The output species directory would contain 5 subdirectories. 
  # run-mauve contains genome alignments.
  # run-lcb contains alignment blocks that are generated by the genome
  # alignment.
  # run-clonalframe contains the reference species tree estimated by ClonalFrame.
  # run-clonalorigin contains the result from ClonalOrigin.
  # run-analysis should contain all the results. The final results must be from
  # this directory. A manuscript in the subdirectory doc/README will have
  # special words that will be replaced by values from files in run-analysis.
  # Whenever I change the analysis, values must be changed accordingly.
  OUTPUTDIR=$MAUVEANALYSISDIR/output
  BASEDIR=$OUTPUTDIR/$SPECIES
  BASERUNANALYSIS=$BASEDIR/run-analysis
  NUMBERDIR=$BASEDIR/$REPETITION_DIR
  DATADIR=$NUMBERDIR/data
  RUNMAUVE=$NUMBERDIR/run-mauve
  RUNLCBDIR=$NUMBERDIR/run-lcb
  RUNCLONALFRAME=$NUMBERDIR/run-clonalframe
  RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
  RUNANALYSIS=$NUMBERDIR/run-analysis

  # Mauve alignments are stored in output directory. 
  RUNMAUVEOUTPUTDIR=$RUNMAUVE/output

  # The cluster has almost the same file system. I used to used Samba client to
  # use the file system of the cluster. This stopped working. I did not know the
  # reason, which I did not want to know. Since then, I use scp command.
  # Note that the cluster base directory does not contain run-analysis. The
  # basic analysis is done in the local machine.
  CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES
  CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$REPETITION_DIR
  CAC_DATADIR=$CAC_NUMBERDIR/data
  CAC_RUNMAUVE=$CAC_NUMBERDIR/run-mauve
  CAC_RUNCLONALFRAME=$CAC_NUMBERDIR/run-clonalframe
  CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
  CAC_RUNANALYSIS=$CAC_NUMBERDIR/run-analysis

  X11_BASEDIR=$X11_OUTPUTDIR/$SPECIES
  X11_NUMBERDIR=$X11_OUTPUTDIR/$SPECIES/$REPETITION_DIR
  X11_DATADIR=$X11_NUMBERDIR/data
  X11_RUNMAUVE=$X11_NUMBERDIR/run-mauve
  X11_RUNCLONALFRAME=$X11_NUMBERDIR/run-clonalframe
  X11_RUNCLONALORIGIN=$X11_NUMBERDIR/run-clonalorigin
  X11_RUNANALYSIS=$X11_NUMBERDIR/run-analysis

  # Jobs are submitted using a batch script. Their names are a batch.sh. This is
  # for simplifying submission of jobs. Just execute
  # nsub batch.sh
  # to submit jobs. This would work usually when submitting a job that uses a
  # single computing node. ClonalOrigin analysis should be done with multiple
  # computing nodes. Then, execute
  # bash batch.sh 8
  # to submit a job that would use 8 computing nodes. In CAC cluster each
  # computing node is equipped with 8 CPUs. The above command would use 64 CPUs
  # at the same time. Note that you have to change many parts of the codes if
  # the cluster's submission system is different from Cornell CAC Linux cluster.
  BATCH_SH_RUN_MAUVE=$RUNMAUVE/batch.sh
  BATCH_SH_RUN_CLONALFRAME=$RUNCLONALFRAME/batch.sh
  BATCH_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch.sh
  BATCH_BODY_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_body.sh
  BATCH_TASK_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_task.sh
  BATCH_REMAIN_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_remain.sh
  BATCH_REMAIN_BODY_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_remain_body.sh

  # Some of ClonalOrigin analysis uses file system that were used in the
  # previous analysis such as Mauve alignment.  This may be a little long story,
  # but I have to comment on it. The alignment file from Mauve lists the actual
  # Genbank file names in its header. This information is used when finding core
  # alignment blocks. See run-lcb and filter-blocks for detail. Finding core
  # blocks is done in the local computer whereas the alignment is done in the
  # cluster. To let run-lcb to work in the local computer I have to make the
  # same temp directory in the local computer as in the cluster. When a job is
  # submitted in the cluster in CAC cluster, the job creates a temporary
  # directory where it can save the input and output files. JOBID is the CAC job
  # id for run-mauve. This job ID should be found in the Mauve alignment file.
  TMPDIR=/tmp/$JOBID.scheduler.v4linux
  TMPINPUTDIR=$TMPDIR/input

}

