#!/bin/bash
# File  : run.sh
# Author: Sang Chul Choi
# Date  : Wed Mar 16 16:59:42 EDT 2011

# This is the key run file to analyze bacterial genome data sets using ClonalOrigin.
# A menu is displayed so that a user can choose an operation that she or he want
# to execute. Some commands do their job on their own right, and others require
# users to go to a cluster to submit a job. Each menu is executed by its
# corresponding bash function. Locate the bash function to understand what it
# does.

# Menus:
#   - choose-species: makes file system for a species, and make it ready to run
#   mauve.
#   - receive-run-mauve: gets the result of mauve alignment from the cluster
#   - prepare-run-clonalframe: finds blocks and makes a script to run
#   clonalframe.
#   - compute-watterson-estimate-for-clonalframe: (optional)
#   - receive-run-clonalframe: receives the result of clonal frame analysis.
#   - prepare-run-clonalorigin: makes a script for clonal origin analysis.
#   - receive-run-clonalorigin: receives the result of the first stage of clonal
#   origin analysis. 
#   - receive-run-2nd-clonalorigin: receives the result of the second stage of
#   clonal analysis.

# Prerequisites
# -------------
# . You need a user ID in a linux cluster: edit $CACUSERNAME, and $CACLOGIN.
# . You need a user ID in a linux machine with X Window: edit $X11USERNAME,
# and $X11LOGIN.
# . Create a directory in the linux cluster, and put the name in $CACBASE: edit
# $CACBASE.
# . Create a directory in the linux machine with X Window, and put the name
# X11BASE: edit $X11BASE.
# . Prepare automatic ssh login for the two machines.
# . Edit BATCHEMAIL to your email address to which you will be notified fo jobs
# status.
# . Edit BATCHACCESS to your access queue. Note that should different cluster batch
# system be used you have to change much part of this script.
# . Download unix version of progressiveMauve and install it in the cluster:
# edit BATCHPROGRESSIVEMAUVE. In the example, I installed it usr/bin of my home
# directory of my cluster account. The BATCHPROGRESSIVEMAUVE looks like this:
# BATCHPROGRESSIVEMAUVE=usr/bin/progressiveMauve
# . Install stripSubsetLCBs at $HOME/usr/bin/stripSubsetLCBs of the local
# computer. It must be a part of progressiveMauve.
# . Download unix version of ClonalFrame and install it into the cluster:
# edit BATCHCLONALFRAME. In the example, I installed it usr/bin of my home
# directory of my cluster account. The BATCHCLONALFRAME looks like this:
# BATCHCLONALFRAME=usr/bin/ClonalFrame

# User Manual
# -----------
# You should be able to download the source code from codaset repository called
# mauve-analysis. 
#
# .To pull the source code 
# ----
# $ git clone git@codaset.com:goshng/mauve-analysis.git
# $ cd mauve-analysis
# ----
#
# .Execution of menus for simulation study s1
# ----
# init-file-system
# choose-simulation
# simulate-data
# prepare-run-clonalorigin
# receive-run-clonalorigin-simulation
# ----
# 
# Menu: init-file-system
# ~~~~~~~~~~~~~~~~~~~~~
# Choose the menu for the first time only.
#
# Menu: choose-simulation
# ~~~~~~~~~~~~~~~~~~~~~~~
# This must be executed before selecting simulate-data.
#
# Menu: simulate-data
# ~~~~~~~~~~~~~~~~~~~
# The directory src/clonalorigin contains the source code of ClonalOrigin that
# was modified. Compile it before simulating data. Refer to README in the
# directory to build it.
#
# Simulation s1
# ^^^^^^^^^^^^^
# 
# 
# 
# The output directory
# ~~~~~~~~~~~~~~~~~~~~
# Use the menu init-file-system to create output 
#
# Dependency of menus
# ~~~~~~~~~~~~~~~~~~~
# 

###############################################################################
# Global variables.
###############################################################################
# CAC cluster ID setup
CAC_USERNAME=sc2265
CAC_LOGIN=linuxlogin.cac.cornell.edu
CAC_ROOT=Documents/Projects/m2
CAC_USERHOST=$CAC_USERNAME@$CAC_LOGIN
CAC_MAUVEANALYSISDIR=$CAC_USERHOST:$CAC_ROOT
CAC_OUTPUTDIR=$CAC_ROOT/output
CACBASE=$CAC_ROOT/output
# X11 linux ID setup
X11_USERNAME=choi
X11_LOGIN=swiftgen
X11_ROOT=Documents/Projects/m2
X11_USERHOST=$X11_USERNAME@$X11_LOGIN
X11_MAUVEANALYSISDIR=$X11_USERHOST:$X11_ROOT
X11_OUTPUTDIR=$CAC_ROOT/output
X11BASE=$X11_ROOT/output
# CAC cluster access to job submission
BATCHEMAIL=schoi@cornell.edu
BATCHACCESS=acs4_0001
BATCHPROGRESSIVEMAUVE=usr/bin/progressiveMauve
BATCHCLONALFRAME=usr/bin/ClonalFrame

# The main base directory contains all the subdirectories.
MAUVEANALYSISDIR=`pwd`
OUTPUTDIR=$MAUVEANALYSISDIR/output

# Replicates and repetitions.
# ---------------------------
# The output directory contains different analyses. They can be different in
# their raw data or their purposes of analyses. For example, the output
# directory can contain cornell5 for the 5 genomes of Streptococcus. It can
# contain bacillus for the genomes that Didelot et al. (2010) used. It can also
# contain a directory called s1 that includes analyses of one of simulation
# studies. REPETITION macro is mainly used for the purpose of simulation
# studies. A number of repetitons in a simulation study can performed. One
# repetition can be different from another. For real data analyses repetitions
# can be done at different time points. They can also be different in some of
# their filtering steps, which could result in different temporary data.
CLONALFRAMEREPLICATE=1
REPLICATE=1
REPETITION=1

# bash sh/run.sh smaller
# bash sh/run.sh 
SMALLER=$1
SMALLERCLONAL=$1

# Perl scripts
PERLGCT=pl/getClonalTree.pl
PERLMWF=pl/makeMauveWargFile.pl
PERLRECOMBINATIONMAP=pl/recombinationmap.pl
PERLLISTGENEGFF=pl/listgenegff.pl 
PERLCOMPUTEMEDIANS=pl/computeMedians.pl
PERLECOP=pl/extractClonalOriginParameter.pl
PERLECOP2=pl/extractClonalOriginParameter2.pl
PERLECOP3=pl/extractClonalOriginParameter3.pl
PERLECOP4=pl/extractClonalOriginParameter4.pl
PERLRECOMBINATIONINTENSITY=pl/recombination-intensity.pl
PERLRECOMBINATIONINTENSITY2=pl/recombination-intensity2.pl
PERLGUIPERL=pl/findBlocksWithInsufficientConvergence.pl

# Binary files installed by progressiveMauve and ClonalOrigin
# FIXME: Can I have source files of the binary just for inventory?
# Note that I installed usr/bin of my home directory.
AUI=$HOME/usr/bin/addUnalignedIntervals  # a part of Mauve.
LCB=$HOME/usr/bin/stripSubsetLCBs        # a part of Mauve.
GUI=clonalorigin/gui/gui.app/Contents/MacOS/gui  # GUI program of ClonalOrigin
WARGSIM=src/clonalorigin/b/wargsim

# Genome Data Directory
# ---------------------
# Bacterial genomes can be downloaded into a directory. I used to download and
# store them in a separate driver because total file sizes can be too large to
# be stored in a local machine. 
GENOMEDATADIR=/Volumes/Elements/Documents/Projects/mauve/bacteria

# SEQUENCE Command can be different for Linux and MacOSX.
if [[ "$OSTYPE" =~ "linux" ]]; then
  SEQ=seq
elif [[ "$OSTYPE" =~ "darwin" ]]; then
  SEQ=jot
fi

# Simulations
# -----------
# s1: a single block of 10,000 base pairs
# s2: 411 blocks
# s3: 10 blocks of 10,000 base pairs
# s4: 4000 minimum
SIMULATIONS=( s1 s2 s3 s4 )

###############################################################################
# Description of functions
###############################################################################
# hms: Converts seconds to a format of hours:minutes:seconds.
# ---
# init-file-system: Creates directories on the checked out directory.
# ---
# set-more-global-variable: Names more global variables. 
# ---
# mkdir-species: Makes directories for analyzing a data set.
# mkdir-simulation: Makes directories for simulation.
# mkdir-simulation-repeat: Makes directories for a repeat of a simulation.
# ---
# copy-batch-sh-run-mauve: Batch script for submitting a job for mauve
# alignment.
# ---
# choose-species: Prepares genome data to align them by using mauve. 
# analyze-run-clonalorigin-simulation: Analyzes simulation results of clonal
# origin.

###############################################################################
# Functions: utility
###############################################################################
# Format seconds into a time format
# ---------------------------------
# input: number in seconds
# output: hours:minutes:seconds
function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

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
  NUMBER_SPECIES=$(grep -v "^#" species/$SPECIES | wc -l)

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
  BASEDIR=$MAUVEANALYSISDIR/output/$SPECIES
  NUMBERDIR=$MAUVEANALYSISDIR/output/$SPECIES/$REPETITION_DIR
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
###############################################################################
# Functions: structuring file system (or creating directories)
###############################################################################
# Create initial directories
# --------------------------
# After checking out the source code from the repository output directories need
# to be created in the local, remote cluster, remote X11 machines.
# input: nothing
# output: 3 output directories
function init-file-system {
  echo -n "Creating $MAUVEANALYSISDIR/output ..." 
  mkdir $MAUVEANALYSISDIR/output 
  echo -e " done"
  echo -n "Creating $CAC_ROOT/output at $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir -p $CAC_ROOT/output
  echo -e " done"
  echo -n "Creating $X11_ROOT/output at $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir -p $X11_ROOT/output
  echo -e " done"
}

# Create direcotires for storing analyses and their results.
# ----------------------------------------------------------
# The species directory is created in output subdirectory. The cluster's file
# system is almost the same as the local one. 
# The followings are the directories to create:
# 
# /Users/goshng/Documents/Projects/mauve/output/cornell
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/data
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-mauve
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-clonalframe
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-clonalorigin
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-analysis
# 
# if 
# BASEDIR=/Users/goshng/Documents/Projects/mauve/output/cornell
# 
# I use 
function mkdir-species {
  mkdir $BASEDIR/run-analysis
  mkdir $BASEDIR \
        $NUMBERDIR \
        $DATADIR \
        $RUNMAUVE \
        $RUNCLONALFRAME \
        $RUNCLONALORIGIN \
        $RUNANALYSIS

  ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR \
                             $CAC_NUMBERDIR \
                             $CAC_DATADIR \
                             $CAC_RUNMAUVE \
                             $CAC_RUNCLONALFRAME \
                             $CAC_RUNCLONALORIGIN \
                             $CAC_RUNANALYSIS

  ssh -x $X11_USERHOST mkdir $X11_BASEDIR \
                             $X11_NUMBERDIR \
                             $X11_DATADIR \
                             $X11_RUNMAUVE \
                             $X11_RUNCLONALFRAME \
                             $X11_RUNCLONALORIGIN \
                             $X11_RUNANALYSIS
}

# Creates directories under the output directory.
# ----------------------------------------------------------
# The species directory is created in output subdirectory. The cluster's file
# structure is almost the same as the local one. 
# The followings are the directories to create:
# 
# /Users/goshng/Documents/Projects/mauve/output/cornell
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/data
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-mauve
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-clonalframe
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-clonalorigin
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-analysis
# 
# if 
# BASEDIR=/Users/goshng/Documents/Projects/mauve/output/cornell
# 

# Creates a species directory in the output directory.
# ----------------------------------------------------
# The argument is the name of species or analysis. You can find them in the
# subdirectory called species.
function mkdir-simulation {
  echo -n "  Creating a simulation $1 at $OUTPUTDIR ..."
  echo -e " done"
  mkdir $OUTPUTDIR/$1
  mkdir $OUTPUTDIR/$1/run-analysis
  echo -n "  Creating a simulation $1 at $CAC_OUTPUTDIR in $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir $CAC_OUTPUTDIR/$1
  echo -e " done"
  echo -n "  Creating a simulation $1 at $X11_OUTPUTDIR in $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir $X11_OUTPUTDIR/$1
  echo -e " done"
}

# Creates directories in each repeat directory.
# ---------------------------------------------
# The first argument is the species name, and the second is the repeat number.
# Both of them are required.
function mkdir-simulation-repeat {
  BASEDIR=$OUTPUTDIR/$1/$2
  DATADIR=$BASEDIR/data
  RUNMAUVE=$BASEDIR/run-mauve
  RUNCLONALFRAME=$BASEDIR/run-clonalframe
  RUNCLONALORIGIN=$BASEDIR/run-clonalorigin
  RUNANALYSIS=$BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $BASEDIR ..."
  mkdir $BASEDIR \
        $DATADIR \
        $RUNMAUVE \
        $RUNCLONALFRAME \
        $RUNCLONALORIGIN \
        $RUNANALYSIS
  echo -e " done"
  CAC_BASEDIR=$CAC_OUTPUTDIR/$1/$2
  CAC_DATADIR=$CAC_BASEDIR/data
  CAC_RUNMAUVE=$CAC_BASEDIR/run-mauve
  CAC_RUNCLONALFRAME=$CAC_BASEDIR/run-clonalframe
  CAC_RUNCLONALORIGIN=$CAC_BASEDIR/run-clonalorigin
  CAC_RUNANALYSIS=$CAC_BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $CAC_BASEDIR ... of $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR \
                             $CAC_DATADIR \
                             $CAC_RUNMAUVE \
                             $CAC_RUNCLONALFRAME \
                             $CAC_RUNCLONALORIGIN \
                             $CAC_RUNANALYSIS
  echo -e " done"
  X11_BASEDIR=$X11_OUTPUTDIR/$1/$2
  X11_DATADIR=$X11_BASEDIR/data
  X11_RUNMAUVE=$X11_BASEDIR/run-mauve
  X11_RUNCLONALFRAME=$X11_BASEDIR/run-clonalframe
  X11_RUNCLONALORIGIN=$X11_BASEDIR/run-clonalorigin
  X11_RUNANALYSIS=$X11_BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $X11_BASEDIR ... of $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir $X11_BASEDIR \
                             $X11_DATADIR \
                             $X11_RUNMAUVE \
                             $X11_RUNCLONALFRAME \
                             $X11_RUNCLONALORIGIN \
                             $X11_RUNANALYSIS
  echo -e " done"
}

###############################################################################
# Function: reading species file
###############################################################################

# Do something using species file.
# --------------------------------
# Species file contains list of Genbank genome files. I use the list of a
# species file to do a few things: 1. batch file for alignment is genreated
# using the list of a species file. Two bash functions can do this:
# read-species-genbank-files and copy-batch-sh-run-mauve-called.
# Similarly, mkdir-tmp-called can replace copy-batch-sh-run-mauve-called to copy
# the Genbank genome files to somewhere using a species file.
function mkdir-tmp-called {
  line="$@" # get all args
  cp $GENOMEDATADIR/$line $TMPINPUTDIR
}

function copy-batch-sh-run-mauve-called {
  line=$1 # get all args
  isLast=$2
  filename_gbk=`basename $line`
  if [ "$isLast" == "last" ]; then
    echo "  \$INPUTDIR/$filename_gbk" >> $BATCH_SH_RUN_MAUVE 
  else
    echo "  \$INPUTDIR/$filename_gbk \\" >> $BATCH_SH_RUN_MAUVE 
  fi
}

function copy-genomes-to-cac-called {
  line="$@" # get all args
  scp $GENOMEDATADIR/$line $CAC_USERHOST:$CAC_DATADIR
}

function processLine {
  line="$@" # get all args
  #  just echo them, but you may need to customize it according to your need
  # for example, F1 will store first field of $line, see readline2 script
  # for more examples
  # F1=$(echo $line | awk '{ print $1 }')
  echo $line
  #cp $GENOMEDATADIR/$line $CACDATADIR
}
 
########################################################################
# I found a script at
# http://bash.cyberciti.biz/file-management/read-a-file-line-by-line/ 
# to read a file line by line. I use it to read a species file.
# I could directly read the directory to find genbank files.
# Let me try to use the script of reading line by line for the time being.
########################################################################
function read-species-genbank-files {
  wfunction_called=$2
  ### Main script stars here ###
  # Store file name
  FILE=""
  numberLine=`grep ^\[^#\] $1 | wc | awk '{print $1'}`
   
  # Make sure we get file name as command line argument
  # Else read it from standard input device
  if [ "$1" == "" ]; then
     FILE="/dev/stdin"
  else
     FILE="$1"
     # make sure file exist and readable
     if [ ! -f $FILE ]; then
      echo "$FILE : does not exists"
      exit 1
     elif [ ! -r $FILE ]; then
      echo "$FILE: can not read"
      exit 2
     fi
  fi
  # read $FILE using the file descriptors
   
  # Set loop separator to end of line
  BAKIFS=$IFS
  IFS=$(echo -en "\n\b")
  exec 3<&0
  exec 0<$FILE
  countLine=0
  isLast=""
  while read line
  do
    if [[ "$line" =~ ^# ]]; then 
      continue
    fi
    countLine=$((countLine + 1))
    if [ $countLine == $numberLine ]; then
      isLast="last"
    else
      isLast=""
    fi
    # use $line variable to process line in processLine() function
    if [ $wfunction_called == "copy-genomes-to-cac" ]; then
      copy-genomes-to-cac-called $line
    elif [ $wfunction_called == "copy-batch-sh-run-mauve" ]; then
      copy-batch-sh-run-mauve-called $line $isLast
    elif [ $wfunction_called == "mkdir-tmp" ]; then
      mkdir-tmp-called $line
    fi
  done
  exec 0<&3
   
  # restore $IFS which was used to determine what the field separators are
  BAKIFS=$ORIGIFS
}

###############################################################################
# Function: batch script
###############################################################################

# A batch file for Mauve alignment.
# ---------------------------------
# The menu choose-species calls this bash function to create a batch file for
# mauve genome alignment. The batch file is also copied to the cluster.
# Note that ${BATCHACCESS}, ${BATCHEMAIL}, ${BATCHPROGRESSIVEMAUVE} should be
# edited.
# 
function copy-batch-sh-run-mauve {
  BATCH_SH_RUN_MAUVE=$1 
cat>$BATCH_SH_RUN_MAUVE<<EOF
#!/bin/bash
#PBS -l walltime=24:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N Strep-${SPECIES}-Mauve
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}

DATADIR=\$PBS_O_WORKDIR/../data
MAUVE=\$HOME/${BATCHPROGRESSIVEMAUVE}

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$MAUVE \$TMPDIR/
cp \$DATADIR/* \$INPUTDIR/
cd \$TMPDIR
./progressiveMauve --output=\$OUTPUTDIR/full_alignment.xmfa \\
  --output-guide-tree=\$OUTPUTDIR/guide.tree \\
EOF

  read-species-genbank-files $SPECIESFILE copy-batch-sh-run-mauve

cat>>$BATCH_SH_RUN_MAUVE<<EOF
cp -r \$OUTPUTDIR \$PBS_O_WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_MAUVE 
  scp $BATCH_SH_RUN_MAUVE $2
}

function mkdir-tmp {
  mkdir -p $TMPINPUTDIR
  read-species-genbank-files $SPECIESFILE mkdir-tmp
  #cp $GENOMEDATADIR/Streptococcus_pyogenes_SSI_1_uid57895/NC_004606.gbk $TMPINPUTDIR
}

function rmdir-tmp {
  rm -rf $TMPDIR
}

function run-lcb {
  MINIMUM_LENGTH=$1
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $RUNMAUVEOUTPUTDIR/full_alignment.xmfa \
    $RUNMAUVEOUTPUTDIR/full_alignment.xmfa.bbcols \
    $DATADIR/core_alignment.xmfa.org $MINIMUM_LENGTH
}

function run-core2smallercore {
  perl $HOME/usr/bin/core2smallercore.pl \
    $RUNLCBDIR/core_alignment.xmfa 0.1 12345
}

function run-blocksplit2fasta {
  rm -f $DATADIR/core_alignment.xmfa.*
  perl pl/blocksplit2fasta.pl $DATADIR/core_alignment.xmfa
}

# FIXME: C source code must be in src
function compute-watterson-estimate {
  FILES=$DATADIR/core_alignment.xmfa.*
  for f in $FILES
  do
    # take action on each file. $f store current file name
    DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
    /Users/goshng/Documents/Projects/biopp/bpp-test/compute_watterson_estimate \
    $f
  done
}

function sum-w {
  RUNLOG=$RUNANALYSIS/run.log
  RSCRIPTW=$RUNANALYSIS/w.R
  cat>$RSCRIPTW<<EOF
x <- read.table ("w.txt")
print (paste("Number of blocks:", length(x\$V1)))
print (paste("Length of the alignment:", sum(x\$V3)))
print (paste("Averge length of a block:", sum(x\$V3)/length(x\$V1)))
print (paste("Proportion of polymorphic sites:", sum(x\$V2)/sum(x\$V3)))
print ("Number of Species:$NUMBER_SPECIES")
print (paste("Finite-site version of Watterson's estimate:", sum (x\$V1)))
nseg <- sum (x\$V2)
s <- 0
n <- $NUMBER_SPECIES - 1
for (i in 1:n)
{
  s <- s + 1/i
}
print (paste("Infinite-site version of Watterson's estimate:", nseg/s))
EOF
  R --no-save < $RSCRIPTW > sum-w.txt
  WATTERSON_ESIMATE=$(sed s/\"//g sum-w.txt | grep "\[1\] Infinite-site version of Watterson's estimate:" | cut -d ':' -f 2)
  FINITEWATTERSON_ESIMATE=$(sed s/\"//g sum-w.txt | grep "\[1\] Finite-site version of Watterson's estimate:" | cut -d ':' -f 2)
  LEGNTH_SEQUENCE=$(sed s/\"//g sum-w.txt | grep "\[1\] Length of the alignment:" | cut -d ':' -f 2)
  NUMBER_BLOCKS=$(sed s/\"//g sum-w.txt | grep "\[1\] Number of blocks:" | cut -d ':' -f 2)
  AVERAGELEGNTH_SEQUENCE=$(sed s/\"//g sum-w.txt | grep "\[1\] Averge length of a block:" | cut -d ':' -f 2)
  PROPORTION_POLYMORPHICSITES=$(sed s/\"//g sum-w.txt | grep "\[1\] Proportion of polymorphic sites:" | cut -d ':' -f 2)
  #rm sum-w.txt
  echo -e "Watterson estimate: $WATTERSON_ESIMATE"
  echo -e "Finite-site version of Watterson estimate: $FINITEWATTERSON_ESIMATE"
  echo -e "Length of sequences: $LEGNTH_SEQUENCE"
  echo -e "Number of blocks: $NUMBER_BLOCKS"
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE"
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES"
  rm -f $RUNLOG
  echo -e "Watterson estimate: $WATTERSON_ESIMATE" >> $RUNLOG
  echo -e "Finite-site version of Watterson estimate: $FINITEWATTERSON_ESIMATE" >> $RUNLOG
  echo -e "Length of sequences: $LEGNTH_SEQUENCE" >> $RUNLOG
  echo -e "Number of blocks: $NUMBER_BLOCKS" >> $RUNLOG
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE" >> $RUNLOG
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES" >> $RUNLOG
}

function send-clonalframe-input-to-cac {
  scp $DATADIR/core_alignment.xmfa $CAC_USERHOST:$CAC_DATADIR
}

function copy-batch-sh-run-clonalframe {
  cat>$BATCH_SH_RUN_CLONALFRAME<<EOF
#!/bin/bash
#PBS -l walltime=168:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N Strep-${SPECIES}-ClonalFrame
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}
WORKDIR=\$PBS_O_WORKDIR
DATADIR=\$WORKDIR/../data
CLONALFRAME=\$HOME/${BATCHCLONALFRAME}

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$CLONALFRAME \$TMPDIR/
cp \$DATADIR/* \$INPUTDIR/
cd \$TMPDIR

x=( 10000 10000 10000 10000 10000 10000 10000 10000 )
y=( 10000 10000 10000 10000 10000 10000 10000 10000 )
z=(    10    10    10    10    10    10    10    10 )

#-t 2 \\
#-m 1506.71 -M \\

for index in 0 1 2 3 4 5 6 7
do
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \\
./ClonalFrame -x \${x[\$index]} -y \${y[\$index]} -z \${z[\$index]} \\
-t 2 -m $WATTERSON_ESIMATE -M \\
\$INPUTDIR/${SMALLER}core_alignment.xmfa \\
\$OUTPUTDIR/${SMALLER}core_clonalframe.out.\$index \\
> \$OUTPUTDIR/cf_stdout.\$index &
sleep 5
done
date
wait
date
cp -r \$OUTPUTDIR \$WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_CLONALFRAME
  scp $BATCH_SH_RUN_CLONALFRAME $CAC_USERHOST:$CAC_RUNCLONALFRAME
}

function send-clonalorigin-input-to-cac {
  scp $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa.* $CACRUNLCBDIR/
}

# 
function copy-batch-sh-run-clonalorigin {
  RUNCLONALORIGIN=$1 
  BATCH_SH_RUN_CLONALORIGIN=$1/batch.sh
  BATCH_BODY_SH_RUN_CLONALORIGIN=$1/batch_body.sh
  BATCH_TASK_SH_RUN_CLONALORIGIN=$1/batch_task.sh
  CAC_RUNCLONALORIGIN=$2
  REPLICATE=$3
  CLONAL2ndPHASE=$4

  cat>$BATCH_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
sed s/PBSARRAYSIZE/\$1/g < batch_body.sh > tbatch.sh
nsub tbatch.sh
rm tbatch.sh
EOF

  cat>$BATCH_BODY_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
#PBS -l walltime=23:59:59,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N Strep-${SPECIES}-ClonalOrigin$CLONAL2ndPHASE
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

set -x
REPLICATE=${REPLICATE}
CLONAL2ndPHASE=$CLONAL2ndPHASE
WORKDIR=\$PBS_O_WORKDIR
WARG=\$HOME/usr/bin/warg
OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input

function to-node {
  mkdir \$INPUTDIR
  mkdir \$OUTPUTDIR
  cp \$PBS_O_WORKDIR/batch_task.sh \$TMPDIR/  
  cp \$WARG \$TMPDIR/
  # The list of job descriptions (or warg command line options) 
  # is at the the working directory.
  # cp \$PBS_O_WORKDIR/remain.txt \$TMPDIR/
}

function to-node-repeat {
  mkdir -p \$PBS_O_WORKDIR/run-clonalorigin/output/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/run-clonalorigin/output2/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/run-clonalorigin/status/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/run-clonalorigin/status2/\${REPLICATE}
  mkdir \$INPUTDIR/
  mkdir \$OUTPUTDIR/
  cp \$PBS_O_WORKDIR/data/*.xmfa.* \$INPUTDIR/
  cp \$PBS_O_WORKDIR/run-clonalorigin/input/\${REPLICATE}/clonaltree.nwk \\
    \$INPUTDIR/
}

function prepare-task {
  JOBIDFILE=\$PBS_O_WORKDIR/jobidfile
  LOCKFILE=\$PBS_O_WORKDIR/lockfile
}

function task {
  cd \$TMPDIR
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batch_task.sh \\
      \$i \$JOBIDFILE \$LOCKFILE \$PBS_O_WORKDIR \$TMPDIR&
  done
}

echo -e "The job started ..."
echo -n "Start at "
date

# Create the main 
to-node

# Copy all the input data files to the compute node.
to-node-repeat 

# What am I preparing?
prepare-task

# Run jobs in multiple nodes.
task

# Wait for all of the 8 processes to finish.
wait
echo -n "End at "
date
echo -e "The job is finished."
EOF

  # Task batch script
  create-batch-task-sh $BATCH_TASK_SH_RUN_CLONALORIGIN

  chmod a+x $BATCH_SH_RUN_CLONALORIGIN
  scp $BATCH_SH_RUN_CLONALORIGIN $2
  scp $BATCH_BODY_SH_RUN_CLONALORIGIN $2
  scp $BATCH_TASK_SH_RUN_CLONALORIGIN $2
}

# A list of jobs for a repeat is created in a file.
function make-run-list-repeat {
  g=$1
  BASEDIR=$2
  REPLICATE=$3
  SPECIESTREE=$4

  NUMBERDIR=$BASEDIR/$g
  for l in `ls $NUMBERDIR/data/*.xmfa.*`; do 
    XMFA_FILE=$(basename $l) 
    # After deletion of longest match from XMFA_FILE.
    BLOCKID=${XMFA_FILE##*.}
    LINE="-a 1,1,0.1,1,1,1,1,1,0,0,0 \
          -x 1000000 -y 1000000 -z 10000 \
          input/$g/$SPECIESTREE input/$g/$XMFA_FILE \
          output/$g/core_co.phase2.$BLOCKID.xml"
    #LINE="-a 1,1,0.1,1,1,1,1,1,0,0,0 \
          #-x 1000000 -y 10000000 -z 10000 \
          #input/$g/clonaltree.nwk input/$g/$XMFA_FILE \
          #output/$g/core_co.phase2.$BLOCKID.xml"
    echo $LINE
  done
}

# A list jobs are stored as a file, which is accessed by all of the computing
# nodes.
function make-run-list {
  HOW_MANY_REPETITION=$1
  BASEDIR=$2
  REPLICATE=$3
  SPECIESTREE=$4

  for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
    make-run-list-repeat $g $BASEDIR $REPLICATE $SPECIESTREE
  done
   
}

  # The first part is from the cluster.
  # Task batch script
function create-batch-task-sh {
  RUN_BATCH_TASK_CLONALORIGIN_SH=$1
  cat>$RUN_BATCH_TASK_CLONALORIGIN_SH<<EOF
#!/bin/bash

function hms
{
  s=\$1
  h=\$((s/3600))
  s=\$((s-(h*3600)));
  m=\$((s/60));
  s=\$((s-(m*60)));
  printf "%02d:%02d:%02d\n" \$h \$m \$s
}

PMI_RANK=\$1
JOBIDFILE=\$2
LOCKFILE=\$3
WORKDIR=\$4
SCRATCH=\$5

WHICHLINE=1
JOBID=0

cd \$SCRATCH

# Read the filelock
#while [ \$JOBID -lt \$TOTALJOBS ] && [ \$JOBID -lt \$ENDJOBID ]
while [ "\$JOBID" != "" ]
do

  # lockfile=filelock
  lockfile=\$LOCKFILE
  if ( set -o noclobber; echo "\$\$" > "\$lockfile") 2> /dev/null; 
  then
    # BK: this will cause the lock file to be deleted 
    # in case of other exit
    trap 'rm -f "\$lockfile"; exit \$?' INT TERM

    # The critical section:
    # Read a line, and delete it.
    read -r JOBID < \${JOBIDFILE}
    sed '1d' \$JOBIDFILE > \$JOBIDFILE.temp; 
    mv \$JOBIDFILE.temp \$JOBIDFILE

    rm -f "\$lockfile"
    trap - INT TERM

    if [ "\$JOBID" == "" ]; then
      echo "No more jobs"
    else
      echo begin-\$JOBID
      START_TIME=\`date +%s\`
      ./warg \$JOBID
      END_TIME=\`date +%s\`
      ELAPSED=\`expr \$END_TIME - \$START_TIME\`
      echo end-\$JOBID
      hms \$ELAPSED
    fi

  else
    echo "Failed to acquire lockfile: \$lockfile." 
    echo "Held by \$(cat $lockfile)"
    sleep 5
    echo "Retry to access \$lockfile"
  fi

done
EOF
}

# A script called run.sh is created at the SPECIES directory.
# -----------------------------------------------------------
# I create a text file from which each job can read a line. The line should
# contain the input file for clonal origin.
function copy-run-sh {
  RUN_SH=$1/run.sh
  RUN_BATCH_CLONALORIGIN_SH=$1/batch_clonalorigin.sh
  RUN_BATCH_TASK_CLONALORIGIN_SH=$1/batch_clonalorigin_task.sh
  RUN_BATCH_CLONALORIGIN2_SH=$1/batch_clonalorigin2.sh
  SPECIES=$3
  HOW_MANY_REPETITION=$4
  SPECIESTREE=$5
  CLONAL2ndPHASE=$6

  cat>$RUN_BATCH_CLONALORIGIN_SH<<EOF
#!/bin/bash
#PBS -l walltime=23:59:59,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N Strep-${SPECIES}-ClonalOrigin
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# -l: The wall time is the time duration during which a job can run. 
#     Use wall time enough to finish jobs.
# -A: The ID for accessing the cluster.
# -j: The standard and error output
# -N: The name of the job
# -q: The name of the queue
# -m: When is the job's status reported?
# -M: The email address to get the notification of the jobs
# -t: The number of nodes to use. I would replace PBSARRAYSIZE with a positive
# number.

HOW_MANY_REPETITION=$HOW_MANY_REPETITION
REPLICATE=$REPLICATE
CLONAL2ndPHASE=$CLONAL2ndPHASE
# WORKDIR=\$PBS_O_WORKDIR

# Sets the echo of the command line on.
set -x
# The full path of the clonal origin executable.
WARG=\$HOME/usr/bin/warg
# The input and output directories.
OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input

# Create an input sub-directory in the tmp directory.
# Copy the task shell script.
# copy the warg program.
function to-node {
  mkdir \$INPUTDIR
  mkdir \$OUTPUTDIR
  cp \$PBS_O_WORKDIR/batch_clonalorigin_task.sh \$TMPDIR/  
  cp \$WARG \$TMPDIR/
  # The list of job descriptions (or warg command line options) 
  # is at the the working directory.
  # cp \$PBS_O_WORKDIR/remain.txt \$TMPDIR/
}

# Create output and status directories for each repeat.
# Create an input directory for each repeat.
# Copy all the data to the input for each repeat.
# Copy the tree file to the input directory.
function to-node-repeat {
  mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/output/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/output2/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/status/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/status2/\${REPLICATE}
  mkdir \$INPUTDIR/\$1
  mkdir \$OUTPUTDIR/\$1
  cp \$PBS_O_WORKDIR/\$1/data/*.xmfa.* \$INPUTDIR/\$1
  cp \$PBS_O_WORKDIR/\$1/run-clonalorigin/input/\${REPLICATE}/$SPECIESTREE \\
    \$INPUTDIR/\$1
}

# Copy the results back to the working directory for each repeat.
function from-node-repeat {
  cp \$OUTPUTDIR/\$1/* \$PBS_O_WORKDIR/\$1/run-clonalorigin/output/\${REPLICATE}
}

# 
function prepare-task {
  JOBIDFILE=\$PBS_O_WORKDIR/jobidfile
  LOCKFILE=\$PBS_O_WORKDIR/lockfile
}

# Execute as many jobs as CPUs in a computing node.
function task {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batch_clonalorigin_task.sh \\
      \$i \$JOBIDFILE \$LOCKFILE \$PBS_O_WORKDIR \$TMPDIR&
  done
}

if [[ "\$OSTYPE" =~ "linux" ]]; then
  SEQ=seq
elif [[ "\$OSTYPE" =~ "darwin" ]]; then
  SEQ=jot
fi

echo -e "The job started ..."
echo -n "Start at "
date

# Create the main 
to-node

# Copy all the input data files to the compute node.
for g in \`\$SEQ \$HOW_MANY_REPETITION\`; do
  to-node-repeat \$g
done

# What am I preparing?
prepare-task

# Run jobs in multiple nodes.
task

# Wait for all of the 8 processes to finish.
wait

for g in \`\$SEQ \$HOW_MANY_REPETITION\`; do
  from-node-repeat \$g
done

echo -n "End at "
date
echo -e "The job is finished."
EOF

  create-batch-task-sh $RUN_BATCH_TASK_CLONALORIGIN_SH

  cat>$RUN_SH<<EOF
#!/bin/bash

function submit-clonalorigin {
  sed s/PBSARRAYSIZE/\$1/g < batch_clonalorigin.sh > tbatch.sh
  nsub tbatch.sh #\$2
  rm tbatch.sh
}

function submit-clonalorigin2 {
  sed s/PBSARRAYSIZE/\$1/g < batch_clonalorigin2.sh > tbatch.sh
  nsub tbatch.sh \$2
  rm tbatch.sh
}

echo -n "How many computing nodes do you wish to use? (e.g., 3) "
read HOW_MANY_NODE
echo -n "How many repetitions do you wish to run? (e.g., 10) "
read HOW_MANY_REPETITION

PS3="Select what jobs you want to submit: "
CHOICES=( submit-clonalorigin \\
          submit-clonalorigin2 ) 
select CHOICE in \${CHOICES[@]}; do
  if [ "\$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "\$CHOICE" == "submit-clonalorigin" ];  then
    REPETITON=\$HOW_MANY_REPETITION
    submit-clonalorigin \$HOW_MANY_NODE \$HOW_MANY_REPETITION
    break
  elif [ "\$CHOICE" == "submit-clonalorigin2" ];  then
    REPETITON=\$HOW_MANY_REPETITION
    submit-clonalorigin2 \$HOW_MANY_NODE \$HOW_MANY_REPETITION
    break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done
EOF
  chmod a+x $RUN_SH
  scp $RUN_SH $2
  scp $RUN_BATCH_CLONALORIGIN_SH $2
  scp $RUN_BATCH_TASK_CLONALORIGIN_SH $2
}

function run-bbfilter {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  bbFilter $ALIGNMENT/full_alignment.xmfa.backbone 50 my_feats.bin gp
}

# A batch script to run clonal origin in the cluster.
# ---------------------------------------------------
# It is based on copy-batch-sh-run-clonalorigin. 
function copy-batch-sh-run-clonalorigin-simulation {

  cat>$BATCH_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
echo 1 > jobidfile
sed s/PBSARRAYSIZE/\$1/g < batch_body.sh > tbatch.sh
nsub tbatch.sh
rm tbatch.sh
EOF

  cat>$BATCH_BODY_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
#PBS -l walltime=23:59:59,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep-${CHOICE}-ClonalOrigin$1
#PBS -q v4
#PBS -m e
#PBS -M schoi@cornell.edu
#PBS -t 1-PBSARRAYSIZE

# nsub -t 1-3 batch.sh 3
set -x
REPLICATE=${REPLICATE}
CLONAL2ndPHASE=$1
WORKDIR=\$PBS_O_WORKDIR
LCBDIR=\$WORKDIR/../run-lcb
WARG=\$HOME/usr/bin/warg
OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input


function to-node {
  mkdir -p \$WORKDIR/output/\${REPLICATE}
  mkdir -p \$WORKDIR/output2/\${REPLICATE}
  mkdir -p \$WORKDIR/status/\${REPLICATE}
  mkdir -p \$WORKDIR/status2/\${REPLICATE}
  mkdir \$INPUTDIR
  mkdir \$OUTPUTDIR
  cp \$LCBDIR/${SMALLERCLONAL}*.xmfa.* \$INPUTDIR/
  cp \$WORKDIR/remain.txt \$TMPDIR/
  cp \$WORKDIR/input/\${REPLICATE}/clonaltree.nwk \$TMPDIR/
  cp \$WARG \$TMPDIR/
  cp \$WORKDIR/batch_task.sh \$TMPDIR/  
}

function prepare-task {
  # NODENUMBER=8 # What is this number? Is this number of cores of a node?

  # I need to count total jobs.
  TOTALJOBS=\$(ls -1 \$INPUTDIR/${SMALLERCLONAL}*.xmfa.* | wc -l)

  # NODECNT: number of computing nodes
  # TASKCNT: total number of cores
  # PBS_ARRAYID represents a computing node among those nodes.
  CORESPERNODE=\`grep processor /proc/cpuinfo | wc -l\`
  #NODECNT=\$(wc -l < "\$PBS_NODEFILE")
  NODECNT=PBSARRAYSIZE # This must match -t option.
  TASKCNT=\`expr \$CORESPERNODE \\* \$NODECNT\`
  #JOBSPERCORE=\$(( TOTALJOBS / TASKCNT + 1 ))
  JOBSPERNODE=\$(( TOTALJOBS / NODECNT + 1 ))
  # The job id is something like 613.scheduler.v4linux.
  # This deletes everything after the first dot.
  JOBNUMBER=\${PBS_JOBID%%.*}

  # JOBIDFILE=\$TMPDIR/jobidfile
  # STARTJOBID=\$(( JOBSPERNODE * (PBS_ARRAYID - 1) + 1 ))
  # ENDJOBID=\$(( JOBSPERNODE * PBS_ARRAYID + 1 )) 
  JOBIDFILE=\$WORKDIR/jobidfile
  LOCKFILE=\$WORKDIR/lockfile
  STARTJOBID=1
  ENDJOBID=\$(( TOTALJOBS + 1))
  TOTALJOBS=\$(( TOTALJOBS + 1))
  # If JOBSPERNODE is 3, then
  # STARTJOBID is 1, and ENDJOBID is 4.
}

function task {
  cd \$TMPDIR
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batch_task.sh \$i \$TOTALJOBS \$ENDJOBID \$WORKDIR \$TMPDIR \$JOBIDFILE \$LOCKFILE \$CLONAL2ndPHASE&
  done
}

echo Start at
date
to-node
prepare-task
task

wait
echo End at
date

EOF

  # Task batch script
  cat>$BATCH_TASK_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash

function hms
{
  s=\$1
  h=\$((s/3600))
  s=\$((s-(h*3600)));
  m=\$((s/60));
  s=\$((s-(m*60)));
  printf "%02d:%02d:%02d\n" \$h \$m \$s
}

REPLICATE=${REPLICATE}
PMI_RANK=\$1
TOTALJOBS=\$2
ENDJOBID=\$3
WORKDIR=\$4
SCRATCH=\$5
JOBIDFILE=\$6
LOCKFILE=\$7
CLONAL2ndPHASE=\$8
WHICHLINE=1
JOBID=0

cd \$SCRATCH

# Read the filelock
while [ \$JOBID -lt \$TOTALJOBS ] && [ \$JOBID -lt \$ENDJOBID ]
do

  #lockfile=filelock
  lockfile=\$LOCKFILE
  if ( set -o noclobber; echo "\$\$" > "\$lockfile") 2> /dev/null; 
  then
    # BK: this will cause the lock file to be deleted in case of other exit
    trap 'rm -f "\$lockfile"; exit \$?' INT TERM

    # critical-section BK: (the protected bit)
    JOBID=\$(sed -n "\${WHICHLINE}p" "\${JOBIDFILE}")

    JOBID=\$(( JOBID + 1))
    echo \$JOBID > \$JOBIDFILE
    JOBID=\$(( JOBID - 1))

    # To read in a line and delete the line so that a next job can be read.
    # Note that jobidfile should contain a list of numbers.
    #read -r JOBID < \${JOBIDFILE}
    #sed '1d' \${JOBIDFILE} > \${JOBIDFILE}.temp;
    #mv \${JOBIDFILE}.temp \${JOBIDFILE}

    rm -f "\$lockfile"
    trap - INT TERM

    if [ \$JOBID -lt \$TOTALJOBS ] && [ \$JOBID -lt \$ENDJOBID ]
    then
      echo begin-\$JOBID
      START_TIME=\`date +%s\`
      if [[ -z \$CLONAL2ndPHASE ]]; then
        FINISHED=\$(tail -n 1 \$WORKDIR/output/\${REPLICATE}/core_co.phase2.\$JOBID.xml)
        if [[ "\$FINISHED" =~ "outputFile" ]]; then
          echo Already finished: \$WORKDIR/output/\${REPLICATE}/core_co.phase2.\$JOBID.xml
        else
          STATUSFILE=\$WORKDIR/status/\${REPLICATE}/${SMALLERCLONAL}core_co.phase2.\$JOBID.status
          if [ ! -f "\$STATUSFILE" ]; then
            touch \$STATUSFILE
            ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 10000000 -z 10000 \\
              clonaltree.nwk input/${SMALLERCLONAL}core_alignment.xmfa.\$JOBID \\
              \$WORKDIR/output/\${REPLICATE}/${SMALLERCLONAL}core_co.phase2.\$JOBID.xml
            rm \$STATUSFILE
          fi
        fi
      else
        FINISHED=\$(tail -n 1 \$WORKDIR/output2/\${REPLICATE}/core_co.phase3.\$JOBID.xml)
        if [[ "\$FINISHED" =~ "outputFile" ]]; then
          echo Already finished: \$WORKDIR/output2/\${REPLICATE}/core_co.phase3.\$JOBID.xml
        else
          STATUSFILE=\$WORKDIR/status2/\${REPLICATE}/${SMALLERCLONAL}core_co.phase3.\$JOBID.status
          if [ ! -f "\$STATUSFILE" ]; then
            touch \$STATUSFILE
            ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 10000000 -z 100000 \\
              -T s${MEDIAN_THETA} -D ${MEDIAN_DELTA} -R s${MEDIAN_RHO} \\
              clonaltree.nwk input/${SMALLERCLONAL}core_alignment.xmfa.\$JOBID \\
              \$WORKDIR/output2/\${REPLICATE}/${SMALLERCLONAL}core_co.phase3.\$JOBID.xml
            rm \$STATUSFILE
          fi
        fi
      fi
      END_TIME=\`date +%s\`
      ELAPSED=\`expr \$END_TIME - \$START_TIME\`
      echo end-\$JOBID
      hms \$ELAPSED
    fi

  else
    echo "Failed to acquire lockfile: \$lockfile." 
    echo "Held by \$(cat \$lockfile)"
    sleep 5
    echo "Retry to access \$lockfile"
  fi

done
EOF

  chmod a+x $BATCH_SH_RUN_CLONALORIGIN
  scp $BATCH_SH_RUN_CLONALORIGIN $CACBASEDIR/
  scp $BATCH_BODY_SH_RUN_CLONALORIGIN $CACBASEDIR/
  scp $BATCH_TASK_SH_RUN_CLONALORIGIN $CACBASEDIR/
}

function run-bbfilter {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  bbFilter $ALIGNMENT/full_alignment.xmfa.backbone 50 my_feats.bin gp
}

# 0. For simulation I make directories in CAC and copy genomes files to the data
# directory. 
function choose-simulation {
  PS3="Choose the simulation for clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "  Creating simulation directories output..."
      mkdir-simulation $SPECIES
      echo -e "done"

      SPECIESFILE=species/$SPECIES
      echo "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      
      echo -e "  Creating directories of $HOW_MANY_REPETITION repetitions..."
      for REPETITION in `$SEQ $HOW_MANY_REPETITION`; do
        mkdir-simulation-repeat $SPECIES $REPETITION
      done

      echo -e "Execute simulate-data!"
      break
    fi
  done
}

# 1. I make directories in CAC and copy genomes files to the data directory.
# --------------------------------------------------------------------------
# Users need to download genome files to a local directory named $GENOMEDATADIR.
# They also need to prepare a species file that contains the actual Genbank
# files. 
# The first job that a user would want to do is to align the genomes. This would
# be done in the cluster CAC. The procedure is as follows:
# 1. Almost all bash variables are set in set-more-global-variable. See the bash function
# for detail. 
# 2. mkdir-species creates main file systems.
# 3. copy-genomes-to-cac copies Genkbank genomes files to CAC.
# 4. copy-batch-sh-run-mauve creates the batch file for mauve alignment, and
# copies it to CAC cluster.
function choose-species {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "Wait for muave-analysis file system preparation...\n"
      set-more-global-variable $SPECIES $REPETITION
      mkdir-species
      read-species-genbank-files $SPECIESFILE copy-genomes-to-cac
      copy-batch-sh-run-mauve \
        $RUNMAUVE/batch.sh \
        $CAC_USERHOST:$CAC_RUNMAUVE
      echo -e "Go to CAC's $SPECIES run-mauve, and execute nsub batch.sh\n"
      break
    fi
  done
}



# 2. Receive mauve-analysis.
# --------------------------
# I simply copy the alignment. 
# I could copy alignment from other repetition.
function receive-run-mauve {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Receiving mauve-output...\n"
      set-more-global-variable $SPECIES $REPETITION
      scp -r $CAC_USERHOST:$CAC_RUNMAUVE/output $RUNMAUVE/
      echo -e "Now, find core blocks of the alignment.\n"
      break
    fi
  done
}

function copy-mauve-alignment {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -n "From which repetition do you wish to copy? (e.g., 1) "
      read SOURCE_REPETITION
      echo -e "  Copying mauve-output..."
      echo -e "    from $BASEDIR/$SOURCE_REPETITION/run-mauve"
      echo -e "    to $RUNMAUVE/output"
      set-more-global-variable $SPECIES $REPETITION
      cp -r $BASEDIR/$SOURCE_REPETITION/run-mauve/output $RUNMAUVE
      echo -e "Now, find core blocks of the alignment.\n"
      break
    fi
  done
}

# 3. Find core alignment blocks.
# ------------------------------
# Core alignment blocks are generated from the mauve alignment. This is somewhat
# iterative procedure. I often was faced with two difficulties. The program,
# stripSubsetLCBs, is a part of progressiveMauve.  Core alignment blocks were
# filtered. Often some allignments were a little bizarre: two many gaps are
# still in some alignment. Another difficulty happens in ClonalOrigin analysis.
# ClonalOrigin's runs with some alignment blocks did not finish within bearable
# time, say a month. ClonalOrigin's run with some other alignment blocks were
# finished relatively fast. It depends on the option of chain lengths. I
# consider that runs are finished when multiple independent MCMC more or less
# converged. Those blocks had to be excluded from the analysis. At the first run
# of this whole procedure, I simply execute the stripSubsetLCBs to find core
# alignment blocks. I manually check the core alignment blocks to remove any
# weird alignments. I then proceed to ClonalFrame and the first stage of
# ClonalOrigin. I find problematic alignment blocks with which ClonalOrigin runs
# take too much computing time. Then, I come back to filter-blocks to remove
# them. I had to be careful in ordering of alignment blocks because when I remove any
# blocks that are not the last all the preceding block numbers have to change.
#
# Note that run-lcb alwasys use the output of Mauve alignment. In the 2nd stage
# of filtering you need to consider proper numbering. Say, in the first
# filtering of alignment with many gaps you removed the 3rd among 10 alignment
# blocks. In the 2nd stage, you found 6th alignment needed too long computing
# time. Then, you should remove 3rd and 7th, not 3rd and 6th because the 6th is
# actually the 7th among the first 10 alignment blocks. The 6th alignment is 6th
# among 9 alignment blocks that were from the 1st stage of filtering.
function filter-blocks {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e 'What is the temporary id of mauve-analysis?'
      echo -e "You may find it in the following directory"
      echo -e "`pwd`/output/$SPECIES/$REPETITION/run-mauve/output/full_alignment.xmfa"
      echo -n "JOB ID: " 
      read JOBID
      echo -e "Preparing clonalframe analysis...\n"
      set-more-global-variable $SPECIES $REPETITION
      # Then, run LCB.
      echo -e "  Finding core blocks of the alignment...\n"
      echo -n "Minimum length of block: " 
      read MINIMUM_LENGTH
      mkdir-tmp 
      run-lcb $MINIMUM_LENGTH
      rmdir-tmp

      #echo -e "  $RUNLCBDIR/core_alignment.xmfa is generated\n"
      #mv $RUNLCBDIR/core_alignment.xmfa.org $RUNLCBDIR/core_alignment.xmfa
      #run-blocksplit2fasta
      #break

      echo -n 'Do you want to filter? (y/n) '
      read WANTFILTER
      if [ "$WANTFILTER" == "y" ]; then
        echo -e "Choose blocks to remove (e.g., 33,42,57): "
        read BLOCKSREMOVED
        perl pl/remove-blocks-from-core-alignment.pl \
          -blocks $BLOCKSREMOVED -fasta $RUNLCBDIR/core_alignment.xmfa.org \
          -outfile $RUNLCBDIR/core_alignment.xmfa
        echo -e "  A new $RUNLCBDIR/core_alignment.xmfa is generated\n"
        echo -e "Now, prepare clonalframe analysis.\n"
      else
        mv $DATADIR/core_alignment.xmfa.org $DATADIR/core_alignment.xmfa
      fi
       
      echo -e "The core blocks might have weird alignment."
      echo -e "Now, edit core blocks of the alignment."
      echo -e "This is the core alignment: $DATADIR/core_alignment.xmfa"
      break
    fi
  done
}

# 4. Prepare clonalframe analysis.
# --------------------------------
# FIXME: Read the code and document it.
#
# NOTE: full_alignment.xmfa has input genome files full paths.
#       These are the paths that were used in CAC not local machine.
#       I have to replace those paths to the genome files paths
#       of this local machine.
# We could edit the xmfa file, but instead
# %s/\/tmp\/1073978.scheduler.v4linux\/input/\/Users\/goshng\/Documents\/Projects\/mauve\/$SPECIES\/data/g
# Also, change the backbone file name.
# I make the same file system structure as the run-mauve.
#
# NOTE: One thing that I am not sure about is the mutation rate.
#       Xavier said that I could fix the mutation rate to Watterson's estimate.
#       I do not know how to do it with finite-sites data.
#       McVean (2002) in Genetics.
#       ln(L/(L-S))/\sum_{k=1}^{n-1}1/k.
#       Just remove gaps and use the alignment without gaps.
#       I may have to find this value from the core genome
#       alignment: core_alignment.xmfa.
# NOTE: I run clonalframe for a very short time to find a NJ tree.
#       I had to run clonalframe twice.
# NOTE: some of the alignments are removed from the analysis.
function prepare-run-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Preparing clonalframe analysis..."
      set-more-global-variable $SPECIES $REPETITION
      echo -e "  Computing Wattersons's estimates..."
      echo -e "  Removing previous blocks..."
      rm -f $DATADIR/core_alignment.xmfa.*
      echo -e "  Splitting core_alignemnt to blocks..."
      perl pl/blocksplit2fasta.pl $DATADIR/core_alignment.xmfa
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
      rm w.txt
      echo -e "You may use the Watterson's estimate in clonalframe analysis.\n"
      echo -e "Or, you may ignore.\n"
      send-clonalframe-input-to-cac 
      copy-batch-sh-run-clonalframe
      echo -e "Go to CAC's output/$SPECIES run-clonalframe, and execute nsub batch.sh\n"
      break
    fi
  done
}

function compute-watterson-estimate-for-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      set-more-global-variable 
      # Find all the blocks in FASTA format.
      #run-blocksplit2fasta 
      echo -e "  Computing Wattersons's estimates...\n"
      run-core2smallercore
      run-blocksplit2fasta 
      #run-blocksplit2smallerfasta 
      # Compute Watterson's estimate.
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
      rm w.txt
      echo -e "You may use the Watterson's estimate in clonalframe analysis.\n"
      echo -e "Or, you may ignore.\n"
      break
    fi
  done
}

# 5. Receive clonalframe-analysis.
# --------------------------------
# A few replicates of ClonalFrame could be created.
function receive-run-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Receiving clonalframe-output...\n"
      set-more-global-variable $SPECIES $REPETITION
      echo -e "Which replicate set of ClonalFrame output files?"
      echo -n "ClonalFrame REPLICATE ID: " 
      read CLONALFRAMEREPLICATE
      mkdir -p $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE
      scp $CAC_USERHOST:$CAC_RUNCLONALFRAME/output/* $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE/
      echo -e "  Sending clonalframe-output to swiftgen...\n"
      ssh -x $X11_USERHOST \
        mkdir -p $CAC_RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE
      scp $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE/* \
        $X11_USERHOST:$X11_RUNCLONALFRAME
      echo -e "Now, prepare clonalorigin.\n"
      break
    fi
  done
}

# 6. Prepare the first stage of clonalorigin.
# -------------------------------------------
# A few variables need explanation before describing the first stage of
# ClonalOrigin.
# CLONALFRAMEREPLICATE: multiple replicates of clonal frame are possible.
# RUNID: multiple runs in each replicate of clonal frame run are available.
# Choose clonal frame replicate first, and then run identifier later. This
# combination represents a species tree using the core alignment blocks.
# REPLICATE: multiple replicates of clonal origin are avaiable. I also need to
# check the convergence before proceeding with the second stage of clonal
# origin. 
# I used split core alignments into blocks. I did it for estimating Watterson's
# estimate. Each block was in FASTA format. I modified the perl script,
# blocksplit.pl, to generate FASTA formatted files. I just use blocksplit.pl to
# split the core alignments into blocks that ClonalOrigin can read in. I delete
# all the core alignment blocks that were generated before, and recreate them so
# that I let ClonalOrigin read its expected formatted blocks.
#
function prepare-run-clonalorigin {
  PS3="Choose the species to analyze with clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Which replicate set of ClonalFrame output files?"
      echo -n "ClonalFrame REPLICATE ID: " 
      read CLONALFRAMEREPLICATE
      echo -e "Which replicate set of ClonalOrigin output files?"
      echo -n "ClonalOrigin REPLICATE ID: " 
      read REPLICATE
      echo -e "Preparing clonal origin analysis..."
      set-more-global-variable 
      mkdir -p $RUNCLONALORIGIN/input/${REPLICATE}
      mkdir $RUNCLONALORIGIN/output
      mkdir $RUNCLONALORIGIN/output2
      mkdir -p $CACRUNCLONALORIGIN/input/${REPLICATE}

      echo -e "Read which clonalframe output file is used to have a phylogeny of a clonal frame."
      echo -n "RUN ID: " 
      read RUNID
      perl $PERLGCT $RUNCLONALFRAME/output/${CLONALFRAMEREPLICATE}/${SMALLER}core_clonalframe.out.${RUNID} $RUNCLONALORIGIN/input/${REPLICATE}/clonaltree.nwk
      echo -e "  Splitting alignment into one file per block..."
      rm $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa.*
      perl pl/blocksplit.pl $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa

      send-clonalorigin-input-to-cac
      scp -r $RUNCLONALORIGIN/input $CACRUNCLONALORIGIN
      #scp $RUNCLONALORIGIN/input/${REPLICATE}/clonaltree.nwk $CACRUNCLONALORIGIN/input/${REPLICATE}/
      # Some script.
      copy-batch-sh-run-clonalorigin
      echo -e "Go to CAC's output/$SPECIES run-clonalorigin"
      echo -e "Submit a job using a different command."
      echo -e "$ bash batch.sh 3 to use three computing nodes"
      echo -e "Check the output if there are jobs that take longer"
      echo -e "tail -n 1 output/*> 1"
      echo -e "Create a file named remain.txt with block IDs, and then run"
      echo -e "$ bash batch_remain.sh 3"
      echo -e "The number of computing nodes is larger than the number of"
      echo -e "remaining jobs divided by 8"
      break
    fi
  done
}

# 7. Receive clonalorigin-analysis.
# ---------------------------------
# Note that we can have multiple replicates of clonal origin. 
# I might want to just compute global median estimates of the first stage of
# ClonalOrigin.
function receive-run-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE
      set-more-global-variable 
      mkdir -p $RUNCLONALORIGIN/summary/${REPLICATE}

      echo -e 'Have you already downloaded and do you want to skip the downloading? (y/n) '
      read WANTSKIPDOWNLOAD
      if [ "$WANTSKIPDOWNLOAD" == "y" ]; then
        echo "Skipping copy of the output files because I've already copied them ..."
      else
        echo -e "Receiving 1st stage of clonalorigin-output...\n"
        mkdir -p $RUNCLONALORIGIN/output/${REPLICATE}
        cp $CACRUNCLONALORIGIN/output/${REPLICATE}/* $RUNCLONALORIGIN/output/${REPLICATE}/
      fi

      echo -e "Computing the global medians of theta, rho, and delta ...\n"
      perl $PERLCOMPUTEMEDIANS \
        $RUNCLONALORIGIN/output/${REPLICATE}/${SMALLERCLONAL}core*.xml \
        | grep ^Median > $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

# 8. Check the convergence
# ------------------------
# A multiple runs of the first stage of ClonalOrigin are checked for their
# convergence.
# FIXME: we need a bash function.

# 9. Prepare 2nd clonalorigin-analysis.
# -------------------------------------
# I use one of replicates of the first stage of ClonalOrigin. I do not combine
# the replicates.
function prepare-run-2nd-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE
      set-more-global-variable 
      if [ -f "$RUNCLONALORIGIN/summary/${REPLICATE}/median.txt" ]; then
        MEDIAN_THETA=$(grep "Median theta" $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt | cut -d ":" -f 2)
        MEDIAN_DELTA=$(grep "Median delta" $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt | cut -d ":" -f 2)
        MEDIAN_RHO=$(grep "Median rho" $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt | cut -d ":" -f 2)
        echo -e "Preparing 2nd clonalorigin ... "
        copy-batch-sh-run-clonalorigin Clonal2ndPhase
        echo -e "Submit a job using a different command."
        echo -e "$ bash batch.sh 3 to use three computing nodes"
      else
        echo "No summary file called $RUNCLONALORIGIN/summary/${REPLICATE}/median.txt" 1>&2
      fi
      break
    fi
  done
}

# 9. Receive 2nd clonalorigin-analysis.
# -------------------------------------
# Instead of checking the convergence of the 2nd stage of ClonalOrigin I check
# if all of my results are consistent between independent runs.
function receive-run-2nd-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE
      echo -e 'What is the temporary id of mauve-analysis?'
      echo -e "You may find it in the $SPECIES/run-mauve/output/full_alignment.xmfa"
      echo -n "JOB ID: " 
      read JOBID
      echo -e "Preparing clonalframe analysis...\n"
      set-more-global-variable 
      echo -e "  Making temporary data files....\n"
      mkdir-tmp 

      echo -e "Receiving 2nd clonalorigin-output...\n"
      cp -r $CACRUNCLONALORIGIN/output2/${REPLICATE} $RUNCLONALORIGIN/output2/     # -done should be trimmed
      for f in  $RUNCLONALORIGIN/output2/${REPLICATE}/*phase*; do          # -done should be trimmed
        bzip2 $f
      done
      
      # Directory is needed: /tmp/1074429.scheduler.v4linux/input/SdeqATCC12394.gbk
      echo -e "Doing AUI ...\n"
      DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
        $AUI $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa $RUNLCBDIR/${SMALLERCLONAL}core_alignment_mauveable.xmfa
      echo -e "Doing MWF ...\n"
      
      perl $PERLMWF $RUNCLONALORIGIN/output2/${REPLICATE}/*phase3*.bz2         # -done should be trimmed
      rmdir-tmp
      echo -e "Now, do more analysis with mauve.\n"
      break
    fi
  done
}

function recombination-intensity3 {
  cat>$RUNANALYSIS/recombination-intensity3.R<<EOF
x <- read.table ("$RUNANALYSIS/recombination-intensity.txt.sgr")
length(x\$V3[x\$V3<1])/length(x\$V3)
stem(x\$V3)
postscript("$RUNANALYSIS/recombination-intensity.eps", width=10, height=10)
hist(x\$V3, main="Distribution of number of recombinant edge types", xlab="Number of recombinant edge types")
dev.off()
EOF
  R --no-save < $RUNANALYSIS/recombination-intensity3.R
}



# 10. Some post-processing procedures follow clonal origin runs.
# --------------------------------------------------------------
# Several analyses were performed using output of ClonalOrigin. Let's list
# those.
#
# recombination-intensity: A recombinant edge is classifed by its departure and
# arrival species tree branches. The number of types of recombinant edges could
# have been equal to the sqaure of the number of species tree branches including
# the rooting edge. Let the number of species tree branches L. A nucleotide site
# is affected by only a single recombinant edge type.  I can have a matrix of
# size L-by-L, each element of which is a binary value that represents that the
# corresponding site is affected by the recombinant edge with departure of the
# row index of the element, and arrival of the column index of it. Note that
# some of elements must be always 0 because their recombinant edge types are
# impossible.
#
# recombination-intensity2: This uses the output file from
# recombination-intensity menu; it must be called after the call of
# recombination-intensity. The output of recombination-intensity is a series of
# matrices.  Each line starts with a position number that represents a site in a
# genome. The position is followed by a L*L many integers. These numbers are
# elements of a matrix of size L-by-L. Numbers in the elements can be larger
# than 1 because each element is the sum of binary values over the MCMC
# iterations of ClonalOrigin. The number ranges from 0 to the size of
# iterations. I have to divide numbers in the elements by the number of
# iterations to obtain average values. I want to consider the number of
# recombinant edge types that affect a site as a measure of recombination
# intensity. The total number of recombination edge types that affect a
# nucleotide site is just the sum of all of the elements of the matrix of size
# L-by-L.
#
# recombination-intensity3: This uses the output file from
# recombination-intensity2 menu. It draw the distribution of numbers of
# recombinant edge types over sites of all of the alignment blocks.
# recombination-intensity.eps shows the distribution.
#
#
#
# 
#
# More literature search for studies of bacterial recombination.
#
#
# convergence: This should go to a separate menu.
# heatmap:
# import-ratio-locus-tag: 
# summary: 
# recedge: 
# recmap: 
# traceplot: 
# parse-jcvi-role: 
# combine-import-ratio-jcvi-role:
#
function analysis-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE
      set-more-global-variable 
 
      select WHATANALYSIS in recombination-intensity \
                             recombination-intensity2 \
                             recombination-intensity3 \
                             gene-flow \
                             convergence \
                             heatmap \
                             import-ratio-locus-tag \
                             summary \
                             recedge \
                             recmap \
                             traceplot \
                             parse-jcvi-role \
                             combine-import-ratio-jcvi-role; do 
        if [ "$WHATANALYSIS" == "" ];  then
          echo -e "You need to enter something\n"
          continue
        elif [ "$WHATANALYSIS" == "recombination-intensity" ]; then
          echo -e "Computing recombination intensity ..."
          echo perl $PERLRECOMBINATIONINTENSITY \
            -d $RUNCLONALORIGIN/output2-xml/${REPLICATE}/core_co.phase3 \
            > $RUNANALYSIS/recombination-intensity.txt
          break
        elif [ "$WHATANALYSIS" == "recombination-intensity2" ]; then
          echo -e "Draw recombination intensity along all the blocks"
          perl $PERLRECOMBINATIONINTENSITY2 \
            -d $RUNCLONALORIGIN/output2-xml/${REPLICATE}/core_co.phase3 \
            -map $RUNANALYSIS/recombination-intensity.txt 
          break
        elif [ "$WHATANALYSIS" == "recombination-intensity3" ]; then
          recombination-intensity3
          break
        elif [ "$WHATANALYSIS" == "convergence" ];  then
          echo -e "Checking convergence of parameters for the blocks ...\n"
          #rm -f $RUNCLONALORIGIN/output/convergence.txt
          #for i in {1..100}; do
          #for i in {101..200}; do
          #for i in {201..300}; do
          for i in {301..415}; do
            ALLTHREEDONE=YES
            for j in {1..3}; do
              FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$j/${SMALLERCLONAL}core_co.phase2.$i.xml)
              if [[ "$FINISHED" =~ "outputFile" ]]; then
                ALLTHREEDONE=YES
              else
                ALLTHREEDONE=NO
                break
              fi
            done

            if [ ! -f "$RUNCLONALORIGIN/output/convergence-$i.txt" ]; then
              if [[ "$ALLTHREEDONE" = "YES" ]]; then
                echo "Block: $i" > $RUNCLONALORIGIN/output/convergence-$i.txt
                echo -e "Computing Gelman-Rubin Test ...\n"
                $GUI -b -o $RUNCLONALORIGIN/output/1/${SMALLERCLONAL}core_co.phase2.$i.xml \
                  -g $RUNCLONALORIGIN/output/2/${SMALLERCLONAL}core_co.phase2.$i.xml,$RUNCLONALORIGIN/output/3/${SMALLERCLONAL}core_co.phase2.$i.xml:1 \
                  >> $RUNCLONALORIGIN/output/convergence-$i.txt
                echo -e "Finding blocks with insufficient convergence ...\n"
                perl $PERLGUIPERL -in $RUNCLONALORIGIN/output/convergence-$i.txt
              else
                echo "Block: $i do not have all replicates" 1>&2
              fi
            fi
          done 

          #echo -e "Finding blocks with insufficient convergence ...\n"
          #perl $PERLGUIPERL -in $RUNCLONALORIGIN/output/convergence.txt
          #break

          break
        elif [ "$WHATANALYSIS" == "heatmap" ];  then
          perl $ECOP4 \
            -d $RUNCLONALORIGIN/output2-xml/${REPLICATE} \
            -e $RUNCLONALORIGIN/output2-xml \
            -n 419 \
            -s 5 
          break
 
          echo -e "Computing heat map for the blocks ...\n"
          for i in {1..419}; do
            if [ -f "$RUNCLONALORIGIN/output2-xml/${REPLICATE}/${SMALLERCLONAL}core_co.phase3.$i.xml" ]; then
              # Compute prior expected number of recedges.
              $GUI -b \
                -o $RUNCLONALORIGIN/output2-xml/${REPLICATE}/${SMALLERCLONAL}core_co.phase3.$i.xml \
                -H 3 \
                > $RUNCLONALORIGIN/output2-xml/heatmap-$i.txt
            else
              echo "Block: $i was not used" 1>&2
            fi
          done 
          #perl $PERLGUIPERL -in $RUNCLONALORIGIN/output2/heatmap-$i.txt
          # Use the phase 3 xml file to count the number of recombination
          # events. For all possible pairs of 9 (5*2 - 1) find the number of
          # recedges, and divide it by the number of sample size or number
          # of <Iteration> tags. I need total length of the blocks and each
          # block length to weight the odd ratio of the averge observed number
          # of recedges and the prior expected number of recedges.
          # ECOP2 and PERLGUIPERL can be merged.  PERLGUIPERL is rather simple.
          # ECOP2 can be extened. Let's make ECOP4.
          echo perl $ECOP4 \
            -d $RUNCLONALORIGIN/output2-xml/${REPLICATE} \
            -h $RUNCLONALORIGIN/output2-xml \
            -n 419 \
            -s 5 
            # > $RUNCLONALORIGIN/log4.p

          break
        elif [ "$WHATANALYSIS" == "import-ratio-locus-tag" ];  then
          echo -e "Computing import ratio per locus tag ...\n"
          # I want to know import ratio for each locus tag.
          # 1. List all locus tags with their genomic locations.
          # 2. For each locus tag find the start and end locations of the locus
          #    tag in the blocks. I assume that a locus falls into a block. The
          #    region that the locus corresponds to is called a subblock.
          # 3. Compute the import ratio of the subblock. The value is the import
          #    ratio of the locus tag.
          # run-analysis/NC_004070.gff 
          # run-lcb/core_alignment_mauveable.xmfa
          # run-clonalorigin/output2
          echo perl $PERLLISTGENEGFF \
            -gff $RUNANALYSIS/NC_004070.gff \
            -alignment $RUNLCBDIR/core_alignment.xmfa \
            -clonalOrigin $RUNCLONALORIGIN/output2-xml/${REPLICATE} \
            -taxon 4 -ns 5 > 1.sh
          break
        elif [ "$WHATANALYSIS" == "summary" ];  then
          echo -e "Finding  theta, rho, and delta estimates for all the blocks ...\n"
          perl $ECOP \
            $RUNCLONALORIGIN/output/${SMALLERCLONAL}core*.xml \
            > $RUNCLONALORIGIN/log.p
          break
        elif [ "$WHATANALYSIS" == "recedge" ];  then
          echo -e "Finding the number of recombination events inferred relative to its expectation under our prior model given the stage 2 inferred recombination rate, for each donor/recipient pair of branches.\n"
          perl $ECOP2 \
            $RUNCLONALORIGIN/output2/${REPLICATE}/${SMALLERCLONAL}core*.xml.bz2 \
            > $RUNCLONALORIGIN/log2.p
          break
        elif [ "$WHATANALYSIS" == "recmap" ];  then
          echo -e "Making graphs to display some using IGB ...\n"
          # Header information should be in the gff file.
          #grep "RefSeq	gene" $GENOMEDATADIR/Streptococcus_pyogenes_MGAS315_uid57911/NC_004070.gff > $RUNCLONALORIGIN/NC_004070.gff

          # Recombination maps along the genome
          for i in {0..4}; do
            for j in {0..8}; do
              perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair $i,$j -map $RUNCLONALORIGIN/log2.p
            done
          done
          for j in {2..8}; do
            perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 5,$j -map $RUNCLONALORIGIN/log2.p
          done
          for j in 2 5 6 7 8; do
            perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 6,$j -map $RUNCLONALORIGIN/log2.p
          done
          for j in 6 7 8; do
            perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 7,$j -map $RUNCLONALORIGIN/log2.p
          done
          perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 8,8 -map $RUNCLONALORIGIN/log2.p

          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 0,3 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 0,4 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 0,6 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 1,3 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 1,4 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 1,6 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 5,3 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 5,4 -map $RUNCLONALORIGIN/log2.p
          #perl $PERLRECOMBINATIONMAP -samplesize 101 -chromosomename NC_004070.1 -importpair 5,6 -map $RUNCLONALORIGIN/log2.p
          break
        elif [ "$WHATANALYSIS" == "traceplot" ];  then
          echo -e "Trace plots ... \n"
          perl $ECOP3 \
            $RUNCLONALORIGIN/output/${REPLICATE}/${SMALLERCLONAL}core*.xml \
            > $RUNCLONALORIGIN/log3.p
          echo -e "Splitting the log files ...\n"
          split -l 100 $RUNCLONALORIGIN/log3.p
          for s in x*; do
            echo -e "${s}.Gen\t${s}.f\t${s}.iter\t${s}.ll\t${s}.prior\t${s}.theta\t${s}.rho\t${s}.delta\n" |cat - $s > /tmp/out && mv /tmp/out $s
          done
          echo -e "Combine all trace files ...\n"
          rm -f /tmp/in
          touch /tmp/in
          for s in x*; do
            paste /tmp/in $s > /tmp/out 
            mv /tmp/out /tmp/in
          done
          mv /tmp/in a.log
          rm x* 
          break
        elif [ "$WHATANALYSIS" == "parse-jcvi-role" ];  then
          echo -e "Parsing jcvi_role.html to find role identifiers ...\n"
          #perl pl/parse-jcvi-role.pl -in $RUNANALYSIS/jcvi_role.html > $RUNANALYSIS/jcvi_role.html.txt
          echo -e "Parsing jcvi_role.html to find role identifiers ...\n"
          #perl pl/parse-m3-locus.pl \
          #  -primary $RUNANALYSIS/bcp_m3_primary_locus.txt \
          #  -jcvi $RUNANALYSIS/bcp_m3_jcvi_locus.txt > \
          #  $RUNANALYSIS/bcp_m3_primary_to_jcvi.txt
          echo -e "Getting one-to-one relationships of locus_tag and JCVI loci ..."
          #perl pl/get-primary-jcvi-loci.pl $RUNANALYSIS/get-primary-jcvi-loci.txt
          echo -e "Listing locus_tags, their gene ontology, and JCVI roles" 
          #perl pl/list-locus-tag-go-jcvi-role.pl \
          #  -bcpRoleLink=$RUNANALYSIS/bcp_role_link \
          #  -bcpGoRoleLink=$RUNANALYSIS/bcp_go_role_link \
          #  -locusTagToJcviLocus=$RUNANALYSIS/get-primary-jcvi-loci.txt \
          #  > $RUNANALYSIS/list-locus-tag-go-jcvi-role.txt
          break
        elif [ "$WHATANALYSIS" == "combine-import-ratio-jcvi-role" ];  then
          echo -e "Combining import-ratio and jcvi-role ..."
          echo perl pl/combine-import-ratio-jcvi-role.pl \
            -importRatio $MAUVEANALYSISDIR/import-ratio-with-sde1.txt \
            -jcviRole $RUNANALYSIS/list-locus-tag-go-jcvi-role.txt
          break
        elif [ "$WHATANALYSIS" == "plot-import-ratio-jcvi-role" ];  then
          echo -e "Plotting import-ratio and jcvi-role ..."
          echo perl pl/plot-import-ratio-jcvi-role.pl \
            -importRatio $MAUVEANALYSISDIR/combine-import-ratio-jcvi-role.txt \
            -jcviRole $RUNANALYSIS/list-locus-tag-go-jcvi-role.txt
        fi
      done
      break
    fi
  done
}

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
function prepare-run-clonalorigin-simulation {
  PS3="Choose a menu of simulation with clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ]; then
      echo -e "You need to enter something\n"
      continue
    # elif [ "$SPECIES" == "s1" ] || [ "$SPECIES" == "s2" ]; then
    else
      SPECIESFILE=species/$SPECIES
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE

      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"

      echo -n "  Reading SPECIESTREE from $SPECIESFILE..."
      SPECIESTREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      echo " $SPECIESTREE"

      #for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
      # Note that seq and jot behave differently when users give two numbers.
      # seq 4 10
      # jot 7 4
      #for g in `jot 7 4`; do 
      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
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
        cp simulation/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE

        echo "  Splitting alignment into files per block..."
        CORE_ALIGNMENT=${SPECIES}_${g}_core_alignment.xmfa
        rm -f $DATADIR/$CORE_ALIGNMENT.*
        perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT

        #send-clonalorigin-input-to-cac
        echo "  Copying the split alignments..."
        scp $DATADIR/$CORE_ALIGNMENT.* \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/data

        echo "  Copying the input species tree..."
        scp $RUNCLONALORIGIN/input/${REPLICATE}/$SPECIESTREE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/run-clonalorigin/input/${REPLICATE}

        echo "  Making command options for clonal origin..."
        make-run-list-repeat $g \
          $OUTPUTDIR/$SPECIES \
          $REPLICATE \
          $SPECIESTREE \
          > $RUNCLONALORIGIN/jobidfile
        scp $RUNCLONALORIGIN/jobidfile $CAC_USERHOST:$CAC_RUNCLONALORIGIN
        copy-batch-sh-run-clonalorigin \
          $RUNCLONALORIGIN \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/run-clonalorigin \
          $REPLICATE
      done

      echo "  Make a script for submitting jobs for all the repetitions."
      make-run-list $HOW_MANY_REPETITION \
        $OUTPUTDIR/$SPECIES \
        $REPLICATE \
        $SPECIESTREE \
        > $OUTPUTDIR/$SPECIES/jobidfile
      scp $OUTPUTDIR/$SPECIES/jobidfile $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES
      copy-run-sh $OUTPUTDIR/$SPECIES \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES \
        $SPECIES \
        $HOW_MANY_REPETITION \
        $SPECIESTREE
 
      break
    fi
  done
}

# Receives result of clonal origin runs for simulation 
# ----------------------------------------------------
# Let's just receive the results.
function receive-run-clonalorigin-simulation {
  PS3="Choose the simulation result of clonalorigin: "
  SIMULATIONS=( s1 s2 )
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s1" ] || [ "$SPECIES" == "s2" ]
      then
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE
      echo -n "How many repetitions do you wish to run? (e.g., 5) "
      read HOW_MANY_REPETITION
      echo -e "Preparing clonal origin analysis..."

      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        NUMBERDIR=$OUTPUTDIR/$SPECIES/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
        rm -rf $RUNCLONALORIGIN/output/$REPLICATE
        mkdir -p $RUNCLONALORIGIN/output/$REPLICATE

        scp $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.*.xml \
          $RUNCLONALORIGIN/output/$REPLICATE
        # mv $RUNCLONALORIGIN/output/$REPLICATE/{,${SPECIES}_${g}_}core_alignment.xml
      done
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}

# Find the median of the median values of three parameters.
# ---------------------------------------------------------
# The simulation s1 would create an output file.  
# It contains a matrix of column size being equal to the sample size (Note that
# the sample size is 101 when run length is 1000000, and thinning interval is
# 10000), and row being equal to the number of repetition.
#
# 
function analyze-run-clonalorigin-simulation-s1-rscript {
  S1OUT=$1
  BATCH_R_S1=$2
cat>$BATCH_R_S1<<EOF
summaryThreeParameter <- function (f) {
  x <- scan (f, quiet=TRUE)
  x <- matrix (x, ncol=101, byrow=TRUE)
  # x <- matrix (x, ncol=100, byrow=FALSE) # 100 is the number of repetition

  y <- c() 
  for (i in 1:100) {
    y <- c(y, median(x[i,]))
  }

  cat (median(y))
  cat ("\n")
}
summaryThreeParameter ("$S1OUT.theta")
summaryThreeParameter ("$S1OUT.rho")
summaryThreeParameter ("$S1OUT.delta")
EOF
  Rscript $BATCH_R_S1 > $BATCH_R_S1.out 
}

# Find the median of the median values of three parameters.
# ---------------------------------------------------------
# The simulation s2 would create an output file. 
# It contains a matrix of column size being equal to 
# a number equal to the product of sample size (N) 
# and block size (B),
# and row being equal to the number of repetition (G).
# I take the mean of a parameter of the sample of a block. 
# The B-many mean values are used to find their median.
# I summarize G-many median values.
# N * B = 101 * 411 = 41511;
#
function analyze-run-clonalorigin-simulation-s2-rscript {
  S2OUT=$1
  BATCH_R_S2=$2
cat>$BATCH_R_S2<<EOF
summaryThreeParameter <- function (f) {
  x <- scan (f, quiet=TRUE)
  x <- matrix (x, ncol=41511, byrow=TRUE)
  # x <- matrix (x, ncol=100, byrow=FALSE) # 100 is the number of repetition

  y <- c() 
  for (i in 1:100) {
    x1 <- matrix (x[i,], ncol=101, byrow=TRUE)
    y1 <- c()
    for (j in 1:411) {
      y1 <- c(y1, median(x1[i,]))
    }

    y <- c(y, median(y1))
  }

  cat (median(y))
  cat ("\n")
}
summaryThreeParameter ("$S2OUT.theta")
summaryThreeParameter ("$S2OUT.rho")
summaryThreeParameter ("$S2OUT.delta")
EOF
  Rscript $BATCH_R_S2 > $BATCH_R_S2.out 
}


# Analysis with clonal origin simulation
# --------------------------------------
# The recovery of the true values is evaluated. The 3 main scalar parameters of
# Clonal origin model include mutation rate, recombination rate, and average
# tract length. Each run samples $N$ values of each parameter. I repeated the
# simulation $G$ times. How can I assess the coverage of estimates on the true
# value?
# For each repetition I find a point estimate such as mean or median of each
# parameter. I will check how much the 100 point estimates cover the true value.
# I could find an interval estimate for each repetition. I could check how often
# or how many among 100 interval estimates cover the true value. If we use 95%
# interval, then I'd expect that 95 of 100 interval estimates would cover the
# true value. I need to build a matrix of 100-by-100 for each parameter. I could
# use it to compute interval estimates.
#
# s1: a single block
# s2: multiple blocks or 411 blocks
#
# 
function analyze-run-clonalorigin-simulation {
  PS3="Choose the simulation result of clonalorigin: "
  SIMULATIONS=( s1 s2 )
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s1" ]; then
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE
      echo -n "How many repetitions do you wish to run? (e.g., 5) "
      read HOW_MANY_REPETITION

      echo "Extracting the 3 parameters from ${HOW_MANY_REPETITION} XML files"
      echo "  of replicate ${REPLICATE}..."
      BASEDIR=$OUTPUTDIR/$SPECIES
      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        NUMBERDIR=$BASEDIR/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        RUNANALYSIS=$NUMBERDIR/run-analysis
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        # Files that we need to compare.
        if [ "$g" == 1 ]; then
          perl pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.1.xml \
            -out $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out
        else
          perl pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.1.xml \
            -out $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
            -append
        fi
      done

      echo "Summarizing the three parameters..."
      analyze-run-clonalorigin-simulation-s1-rscript \
        $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      echo "Refer to the file for median values of the three parameters."
      
      break
    elif [ "$SPECIES" == "s2" ]; then
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE
      echo -n "How many repetitions do you wish to run? (e.g., 5) "
      read HOW_MANY_REPETITION
      NUMBER_BLOCK=411

      echo "Extracting the 3 parameters from ${HOW_MANY_REPETITION} XML files"
      echo "  of replicate ${REPLICATE}..."
      BASEDIR=$OUTPUTDIR/$SPECIES

      #echo "Summarizing the three parameters..."
      #analyze-run-clonalorigin-simulation-s2-rscript \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      #echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      #echo "Refer to the file for median values of the three parameters."
      #break

      #BLOCK_ALLREPETITION=()
      #for b in `$SEQ $NUMBER_BLOCK`; do
        #NOTALLREPETITION=0
        #for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
          #NUMBERDIR=$BASEDIR/$g
          #DATADIR=$NUMBERDIR/data
          #RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          #RUNANALYSIS=$NUMBERDIR/run-analysis
          #CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          #CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          #FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml)
          #if [[ "$FINISHED" =~ "outputFile" ]]; then
            ## NOTALLREPETITION=1
            #NOTALLREPETITION=1 # This should be something else.
          #else 
            #NOTALLREPETITION=1
          #fi
        #done
        #if [ "$NOTALLREPETITION" == 0 ]; then
          ## Add the block to the analysis
          #BLOCK_ALLREPETITION=("${BLOCK_ALLREPETITION[@]}" $b)
        #fi 
      #done

      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        NUMBERDIR=$BASEDIR/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        RUNANALYSIS=$NUMBERDIR/run-analysis
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        # Files that we need to compare.
        #for b in ${BLOCK_ALLREPETITION[@]}; do
        for b in `$SEQ $NUMBER_BLOCK`; do
          ECOP="pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml \
            -out $BASEDIR/run-analysis/out"
          FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml)
          if [[ "$FINISHED" =~ "outputFile" ]]; then
            if [ "$g" == 1 ] && [ "$b" == 1 ]; then
              ECOP="$ECOP -nonewline"
              #echo perl $ECOP
              #continue
            else
              if [ "$b" == $NUMBER_BLOCK ]; then
                ECOP="$ECOP -firsttab -append"
              elif [ "$b" != 1 ]; then
                ECOP="$ECOP -firsttab -nonewline -append" 
              elif [ "$b" == 1 ]; then
                ECOP="$ECOP -nonewline -append" 
              else
                echo "Not possible block $b"
                exit
              fi
            fi
            perl $ECOP
          else
            LENGTHBLOCK=$(perl pl/compute-block-length.pl \
              -base $DATADIR/${SPECIES}_${g}_core_alignment.xmfa \
              -block $b)
            echo "NOTYETFINISHED $g $b $LENGTHBLOCK" >> 1
          fi
        done
      done

      break
      echo "Summarizing the three parameters..."
      analyze-run-clonalorigin-simulation-s2-rscript \
        $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      echo "Refer to the file for median values of the three parameters."
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}

# Computes lengths of blocks.
# ---------------------------
# The run-lcb contains a list of core_alignment.xmfa.[NUMBER] files.
function compute-block-length {
  PS3="Choose the species to compute block lengths: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      perl pl/compute-block-length.pl \
        -base=$DATADIR/core_alignment.xmfa \
        > simulation/$SPECIES-$REPETITION-in.block
      break
    fi
  done

}

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
# s2 should be handled in the same way as s1 and s3.
function simulate-data {
  PS3="Choose a simulation (e.g., s1): "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s1" ] || [ "$SPECIES" == "s3" ]; then
      SPECIESFILE=species/$SPECIES

      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE

      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"
      
      echo -n "  Reading SPECIESTREE from $SPECIESFILE..."
      SPECIESTREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      echo " $SPECIESTREE"

      echo -n "  Reading INBLOCK from $SPECIESFILE..."
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      echo " $INBLOCK"

      echo -n "  Reading from $SPECIESFILE..."
      THETA_PER_SITE=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $THETA_PER_SITE"

      echo -n "  Reading from $SPECIESFILE..."
      RHO_PER_SITE=$(grep RhoPerSite $SPECIESFILE | cut -d":" -f2)
      echo " $RHO_PER_SITE"

      echo -n "  Reading from $SPECIESFILE..."
      DELTA=$(grep Delta $SPECIESFILE | cut -d":" -f2)
      echo " $DELTA"

      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        BASEDIR=$OUTPUTDIR/$SPECIES
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
        cp simulation/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE
        cp simulation/$INBLOCK $DATADIR
        echo -n "  Simulating data under the ClonalOrigin model ..." 
        $WARGSIM --tree-file $RUNCLONALORIGIN/input/$REPLICATE/$SPECIESTREE \
          --block-file $DATADIR/$INBLOCK \
          --out-file $DATADIR/${SPECIES}_${g}_core_alignment \
          -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE
        echo -e " done - repetition $g"
      done
      break
    elif [ "$SPECIES" == "s2" ];  then
      echo -e "Which replicate set of output files?"
      echo -n "REPLICATE ID: " 
      read REPLICATE
      echo -n "How many repetitions do you wish to run? (e.g., 3) "
      read HOW_MANY_REPETITION
      echo -e "Species tree and blocks are given as"
      SPECIESTREE=$OUTPUTDIR/cornell5-1/run-clonalorigin/input/1/clonaltree.nwk
      INBLOCK=$OUTPUTDIR/cornell5-1/run-lcb/in411.block
      echo "  species tree: $SPECIESTREE"
      echo "  block: $INBLOCK"

      # Note that seq and jot behave differently when users give two numbers.
      # seq 4 10
      # jot 7 4
      #for g in `jot 7 4`; do 
      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        BASEDIR=$OUTPUTDIR/$SPECIES
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
        # tree may be the only different part
        cp $SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE 
        cp $INBLOCK $DATADIR
        echo -n "  Simulating data under the ClonalOrigin model ..." 
        $WARGSIM --tree-file $RUNCLONALORIGIN/input/$REPLICATE/clonaltree.nwk \
          --block-file $DATADIR/in411.block \
          --out-file $DATADIR/${SPECIES}_${g}_core_alignment \
          -T s0.0542 -D 1425 -R s0.00521
        echo -e " done - repetition $g"
      done
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}


#####################################################################
# Main part of the script.
#####################################################################
PS3="Select what you want to do with mauve-analysis: "
CHOICES=( init-file-system \
          choose-simulation \
          simulate-data \
          prepare-run-clonalorigin-simulation \
          receive-run-clonalorigin-simulation \
          analyze-run-clonalorigin-simulation \
          ------------------------------------------ \
          choose-species \
          copy-mauve-alignment \
          receive-run-mauve \
          filter-blocks \
          prepare-run-clonalframe \
          receive-run-clonalframe \
          prepare-run-clonalorigin \
          receive-run-clonalorigin \
          prepare-run-2nd-clonalorigin \
          receive-run-2nd-clonalorigin \
          analysis-clonalorigin \
          compute-watterson-estimate-for-clonalframe \
          compute-block-length \
          prepare-run-clonalorigin-simulation )
select CHOICE in ${CHOICES[@]}; do 
  if [ "$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "$CHOICE" == "init-file-system" ];  then
    init-file-system
    break
  elif [ "$CHOICE" == "choose-simulation" ];  then
    choose-simulation
    break
  elif [ "$CHOICE" == "choose-species" ];  then
    choose-species
    break
  elif [ "$CHOICE" == "copy-mauve-alignment" ];  then
    copy-mauve-alignment
    break
  elif [ "$CHOICE" == "receive-run-mauve" ];  then
    receive-run-mauve
    break
  elif [ "$CHOICE" == "filter-blocks" ];  then
    filter-blocks
    break
  elif [ "$CHOICE" == "prepare-run-clonalframe" ];  then
    prepare-run-clonalframe 
    break
  elif [ "$CHOICE" == "compute-watterson-estimate-for-clonalframe" ];  then
    compute-watterson-estimate-for-clonalframe
    break
  elif [ "$CHOICE" == "receive-run-clonalframe" ];  then
    receive-run-clonalframe
    break
  elif [ "$CHOICE" == "prepare-run-clonalorigin" ];  then
    prepare-run-clonalorigin
    break
  elif [ "$CHOICE" == "receive-run-clonalorigin" ];  then
    receive-run-clonalorigin
    break
  elif [ "$CHOICE" == "prepare-run-2nd-clonalorigin" ];  then
    prepare-run-2nd-clonalorigin
    break
  elif [ "$CHOICE" == "receive-run-2nd-clonalorigin" ];  then
    receive-run-2nd-clonalorigin
    break
  elif [ "$CHOICE" == "analysis-clonalorigin" ];  then
    analysis-clonalorigin
    break
  elif [ "$CHOICE" == "prepare-run-clonalorigin-simulation" ];  then
    prepare-run-clonalorigin-simulation
    break
  elif [ "$CHOICE" == "receive-run-clonalorigin-simulation" ];  then
    receive-run-clonalorigin-simulation
    break
  elif [ "$CHOICE" == "analyze-run-clonalorigin-simulation" ];  then
    analyze-run-clonalorigin-simulation
    break
  elif [ "$CHOICE" == "compute-block-length" ];  then
    compute-block-length
    break
  elif [ "$CHOICE" == "simulate-data" ];  then
    simulate-data
    break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

