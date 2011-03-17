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
#   - list-species: lists species names in NCBI ftp directory called bacteria.
#   - generate-species: creates species files.
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

# Edit these global variables.
# ----------------------------
CACUSERNAME=sc2265
CACLOGIN=linuxlogin.cac.cornell.edu
CACBASE=Documents/Projects/mauve/output
X11USERNAME=choi
X11LOGIN=swiftgen
X11BASE=Documents/Projects/mauve/output
BATCHEMAIL=schoi@cornell.edu
BATCHACCESS=acs4_0001
BATCHPROGRESSIVEMAUVE=usr/bin/progressiveMauve
BATCHCLONALFRAME=usr/bin/ClonalFrame

CLONALFRAMEREPLICATE=1
REPLICATE=1
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
PERLGUIPERL=pl/findBlocksWithInsufficientConvergence.pl

# Binary files installed by progressiveMauve and ClonalOrigin
# FIXME: Can I have source files of the binary just for inventory?
# Note that I installed usr/bin of my home directory.
AUI=$HOME/usr/bin/addUnalignedIntervals  # a part of Mauve.
LCB=$HOME/usr/bin/stripSubsetLCBs        # a part of Mauve.
GUI=clonalorigin/gui/gui.app/Contents/MacOS/gui  # GUI program of ClonalOrigin

# Genome Data Directory
# ---------------------
# Bacterial genomes can be downloaded into a directory. I used to download and
# store them in a separate driver because total file sizes can be too large to
# be stored in a local machine. 
GENOMEDATADIR=/Volumes/Elements/Documents/Projects/mauve/bacteria

# This is prepared using list-species.
ALLSPECIES=( Escherichia_coli Salmonella_enterica Staphylococcus_aureus Streptococcus_pneumoniae Streptococcus_pyogenes Prochlorococcus_marinus Helicobacter_pylori Clostridium_botulinum Bacillus_cereus Yersinia_pestis Sulfolobus_islandicus Francisella_tularensis Rhodopseudomonas_palustris Listeria_monocytogenes Chlamydia_trachomatis Buchnera_aphidicola Bacillus_anthracis Acinetobacter_baumannii Streptococcus_suis Neisseria_meningitidis Mycobacterium_tuberculosis Legionella_pneumophila Cyanothece_PCC Coxiella_burnetii Campylobacter_jejuni Burkholderia_pseudomallei Bifidobacterium_longum Yersinia_pseudotuberculosis Xylella_fastidiosa Xanthomonas_campestris Vibrio_cholerae Shewanella_baltica Rhodobacter_sphaeroides Pseudomonas_putida Pseudomonas_aeruginosa Methanococcus_maripaludis Lactococcus_lactis Haemophilus_influenzae Chlamydophila_pneumoniae Candidatus_Sulcia Burkholderia_mallei Burkholderia_cenocepacia )

# Format seconds into a time format.
function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

# Structure directories.
# ----------------------
# The name of file system is overkill.  Subdirectory names are stored in bash
# variables for convenient access to the names. This run.sh is placed in a
# subdirectory named sh. The main directory is $MAUVEANALYSISDIR. This
# run.sh file is executed at the main directory. Let's list directory variables
# and their usages. Refer to each variable in the following.
function prepare-filesystem {
  # The main base directory contains all the subdirectories.
  MAUVEANALYSISDIR=`pwd`

  # SPECIES must be set before the call of this bash function. $SPECIESFILE
  # contains a list of Genbank formatted genome file names.
  SPECIESFILE=$MAUVEANALYSISDIR/species/$SPECIES

  # Number of species in the analysis. The species file can contain comment
  # lines starting with # character at the 1st column.
  NUMBER_SPECIES=$(grep -v "^#" species/$SPECIES | wc -l)

  # The subdirectory output contains directories named after the species file.
  # The output species directory would contain all of the results from the
  # analysis.
  BASEDIR=$MAUVEANALYSISDIR/output/$SPECIES

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
  DATADIR=$BASEDIR/data
  RUNMAUVEDIR=$BASEDIR/run-mauve
  RUNLCBDIR=$BASEDIR/run-lcb
  RUNCLONALFRAME=$BASEDIR/run-clonalframe
  RUNCLONALORIGIN=$BASEDIR/run-clonalorigin
  RUNANALYSISDIR=$BASEDIR/run-analysis

  # Mauve alignments are stored in output directory. 
  RUNMAUVEOUTPUTDIR=$RUNMAUVEDIR/output

  # The cluster has almost the same file system. I used to used Samba client to
  # use the file system of the cluster. This stopped working. I did not know the
  # reason, which I did not want to know. Since then, I use scp command.
  # Note that the cluster base directory does not contain run-analysis. The
  # basic analysis is done in the local machine.
  CACROOTDIR=$CACUSERNAME@$CACLOGIN:$CACBASE
  CACBASEDIR=$CACROOTDIR/$SPECIES
  CACDATADIR=$CACBASEDIR/data
  CACRUNMAUVEDIR=$CACBASEDIR/run-mauve
  CACRUNLCBDIR=$CACBASEDIR/run-lcb
  CACRUNCLONALFRAME=$CACBASEDIR/run-clonalframe
  CACRUNCLONALORIGIN=$CACBASEDIR/run-clonalorigin

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
  BATCH_SH_RUN_MAUVE=$RUNMAUVEDIR/batch.sh
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

  # ClonalFrame has a program with X Window interface. I copy clonal frame
  # result to the linux machine where I set up ClonalFrame. Setting up
  # ClonalFrame's GUI program was done in the Linux machine.
  SWIFTGENROOTDIR=$X11USERNAME@$X11LOGIN:$X11BASE
  SWIFTGENDIR=$SWIFTGENROOTDIR/$SPECIES
  SWIFTGENRUNCLONALFRAME=$SWIFTGENDIR/run-clonalframe
   
  # FIXME: Do not create files at the base directory.
  RUNLOG=$BASEDIR/run.log
  RSCRIPTW=$BASEDIR/w.R
}

# Create direcotires for storing analyses and their results.
# ----------------------------------------------------------
# The species directory is created in output subdirectory. The cluster's file
# system is almost the same as the local one. 
function mkdir-SPECIES {
  mkdir $BASEDIR
  mkdir $DATADIR
  mkdir $RUNMAUVEDIR
  mkdir $RUNLCBDIR
  mkdir $RUNCLONALFRAME
  mkdir $RUNCLONALORIGIN
  mkdir $RUNANALYSISDIR

  scp -r $BASEDIR $CACROOTDIR
  scp -r $DATADIR $CACBASEDIR
  scp -r $RUNMAUVEDIR $CACBASEDIR
  scp -r $RUNLCBDIR $CACBASEDIR
  scp -r $RUNCLONALFRAME $CACBASEDIR
  scp -r $RUNCLONALORIGIN $CACBASEDIR

  scp -r $BASEDIR $SWIFTGENROOTDIR
  scp -r $RUNCLONALFRAME $SWIFTGENDIR
}

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
  scp $GENOMEDATADIR/$line $CACDATADIR
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

# A batch file for Mauve alignment.
# ---------------------------------
# The menu choose-species calls this bash function to create a batch file for
# mauve genome alignment. The batch file is also copied to the cluster.
# Note that ${BATCHACCESS}, ${BATCHEMAIL}, ${BATCHPROGRESSIVEMAUVE} should be
# edited.
function copy-batch-sh-run-mauve {
cat>$BATCH_SH_RUN_MAUVE<<EOF
#!/bin/bash
#PBS -l walltime=8:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N Strep-${SPECIES}-Mauve
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}
WORKDIR=\$PBS_O_WORKDIR
DATADIR=\$WORKDIR/../data
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
cp -r \$OUTPUTDIR \$WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_MAUVE 
  scp $BATCH_SH_RUN_MAUVE $CACRUNMAUVEDIR/
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
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $RUNMAUVEOUTPUTDIR/full_alignment.xmfa \
    $RUNMAUVEOUTPUTDIR/full_alignment.xmfa.bbcols \
    $RUNLCBDIR/core_alignment.xmfa.org 500
}

function run-core2smallercore {
  perl $HOME/usr/bin/core2smallercore.pl \
    $RUNLCBDIR/core_alignment.xmfa 0.1 12345
}

# FIXME: put perl script in the pl directory.
function run-blocksplit2fasta {
  rm -f $RUNLCBDIR/${SMALLER}core_alignment.xmfa.*
  perl $HOME/usr/bin/blocksplit2fasta.pl $RUNLCBDIR/${SMALLER}core_alignment.xmfa
}

function compute-watterson-estimate {
  FILES=$RUNLCBDIR/${SMALLER}core_alignment.xmfa.*
  for f in $FILES
  do
    # take action on each file. $f store current file name
    DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
    /Users/goshng/Documents/Projects/biopp/bpp-test/compute_watterson_estimate \
    $f
  done
}

function sum-w {
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
  echo -e "Number of blocks: $NUMBER_BLOCKS" >> $RUNLOG
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE" >> $RUNLOG
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES" >> $RUNLOG
}

function send-clonalframe-input-to-cac {
  scp $RUNLCBDIR/${SMALLER}core_alignment.xmfa $CACRUNLCBDIR/
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
LCBDIR=\$WORKDIR/../run-lcb
CLONALFRAME=\$HOME/${BATCHCLONALFRAME}

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$CLONALFRAME \$TMPDIR/
cp \$LCBDIR/* \$INPUTDIR/
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
  scp $BATCH_SH_RUN_CLONALFRAME $CACRUNCLONALFRAME/
}

function send-clonalorigin-input-to-cac {
  cp $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa.* $CACRUNLCBDIR/
}

function copy-batch-sh-run-clonalorigin {

  cat>$BATCH_REMAIN_BODY_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
#PBS -l walltime=23:59:59,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep-${SPECIES}-ClonalOrigin$1
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

function run-clonalorigin-jobs {
  ### Main script stars here ###
  STARTJOBSECTIONID=\$2
  STARTJOBID=\$(( (STARTJOBSECTIONID - 1) * 8 ))
  ENDJOBID=\$(( STARTJOBSECTIONID * 8 + 1 )) 
  # Store file name
  FILE=""
   
  # Make sure we get file name as command line argument
  # Else read it from standard input device
  if [ "\$1" == "" ]; then
     FILE="/dev/stdin"
  else
     FILE="\$1"
     # make sure file exist and readable
     if [ ! -f \$FILE ]; then
      echo "\$FILE : does not exists"
      exit 1
     elif [ ! -r \$FILE ]; then
      echo "\$FILE: can not read"
      exit 2
     fi
  fi
  # read \$FILE using the file descriptors
   
  # Set loop separator to end of line
  BAKIFS=\$IFS
  IFS=\$(echo -en "\\n\\b")
  exec 3<&0
  exec 0<\$FILE
  countLine=0
  isLast=""
  while read line
  do
    if [[ "\$line" =~ ^# ]]; then 
      continue
    fi
    countLine=\$((countLine + 1))
    if [ \$countLine -gt \$STARTJOBID ] && [ \$countLine -lt \$ENDJOBID ]
    then
      STATUSFILE=\$WORKDIR/status/\${REPLICATE}/${SMALLERCLONAL}core_co.phase2.\$line.status
      touch \$STATUSFILE
      ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 10000000 -z 10000 \\
        clonaltree.nwk input/${SMALLERCLONAL}core_alignment.xmfa.\$line \\
        \$WORKDIR/output/\${REPLICATE}/${SMALLERCLONAL}core_co.phase2.\$line.xml &
      # rm \$STATUSFILE
    fi
  done
  exec 0<&3
   
  # restore \$IFS which was used to determine what the field separators are
  BAKIFS=\$ORIGIFS
}

echo Start at
date
to-node
cd \$TMPDIR
run-clonalorigin-jobs remain.txt \$PBS_ARRAYID

wait
echo End at
date

EOF

  cat>$BATCH_REMAIN_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
sed s/PBSARRAYSIZE/\$1/g < batch_remain_body.sh > tbatch.sh
nsub tbatch.sh
rm tbatch.sh
EOF

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
#PBS -N Strep-${SPECIES}-ClonalOrigin$1
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
  #for (( i=1; i<=TASKCNT; i++))
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
  cp $BATCH_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
  cp $BATCH_BODY_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
  cp $BATCH_TASK_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
  cp $BATCH_REMAIN_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
  cp $BATCH_REMAIN_BODY_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
}

function run-bbfilter {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  bbFilter $ALIGNMENT/full_alignment.xmfa.backbone 50 my_feats.bin gp
}

# 1. I make directories in CAC and copy genomes files to the data directory.
# --------------------------------------------------------------------------
# Users need to download genome files to a local directory named $GENOMEDATADIR.
# They also need to prepare a species file that contains the actual Genbank
# files. See the bash functions: list-species and generate-species for detail.
# The first job that a user would want to do is to align the genomes. This would
# be done in the cluster CAC. The procedure is as follows:
# 1. Almost all bash variables are set in prepare-filesystem. See the bash function
# for detail. 
# 2. mkdir-SPECIES creates main file systems.
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
      echo -e "Wait for muave-analysis file system preparation...\n"
      prepare-filesystem 
      mkdir-SPECIES
      read-species-genbank-files $SPECIESFILE copy-genomes-to-cac
      copy-batch-sh-run-mauve
      echo -e "Go to CAC's $SPECIES run-mauve, and execute nsub batch.sh\n"
      break
    fi
  done
}

# 2. Receive mauve-analysis.
# --------------------------
# I simply copy the alignment. 
function receive-run-mauve {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Receiving mauve-output...\n"
      prepare-filesystem 
      scp -r $CACRUNMAUVEDIR/output $RUNMAUVEDIR/
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
      echo -e 'What is the temporary id of mauve-analysis?'
      echo -e "You may find it in the following directory"
      echo -e "`pwd`/output/$SPECIES/run-mauve/output/full_alignment.xmfa"
      echo -n "JOB ID: " 
      read JOBID
      echo -e "Preparing clonalframe analysis...\n"
      prepare-filesystem 
      # Then, run LCB.
      echo -e "  Finding core blocks of the alignment...\n"
      mkdir-tmp 
      run-lcb 
      rmdir-tmp

      #echo -e "  $RUNLCBDIR/core_alignment.xmfa is generated\n"
      #mv $RUNLCBDIR/core_alignment.xmfa.org $RUNLCBDIR/core_alignment.xmfa
      #run-blocksplit2fasta
      #break

      echo -e 'Do you want to filter? (y/n)'
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
        mv $RUNLCBDIR/core_alignment.xmfa.org $RUNLCBDIR/core_alignment.xmfa
      fi
       
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
      echo -e "Preparing clonalframe analysis...\n"
      prepare-filesystem 
      echo -e "  Computing Wattersons's estimates...\n"
      run-blocksplit2fasta 
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
      prepare-filesystem 
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
      echo -e "Which replicate set of ClonalFrame output files?"
      echo -n "ClonalFrame REPLICATE ID: " 
      read CLONALFRAMEREPLICATE
      echo -e "Receiving clonalframe-output...\n"
      prepare-filesystem 
      mkdir -p $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE
      scp $CACRUNCLONALFRAME/output/* $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE/
      echo -e "Sending clonalframe-output to swiftgen...\n"
      scp -r $RUNCLONALFRAME/output/$CLONALFRAMEREPLICATE $SWIFTGENRUNCLONALFRAME/
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
      prepare-filesystem 
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
      # FIXME: put perl script in the pl directory.
      perl $HOME/usr/bin/blocksplit.pl $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa

      send-clonalorigin-input-to-cac
      cp $RUNCLONALORIGIN/input/${REPLICATE}/clonaltree.nwk $CACRUNCLONALORIGIN/input/${REPLICATE}/
      # Some script.
      copy-batch-sh-run-clonalorigin
      echo -e "Go to CAC's output/$SPECIES run-clonalorigin, and execute nsub batch.sh"
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
      prepare-filesystem 
      mkdir -p $RUNCLONALORIGIN/summary/${REPLICATE}

      echo -e 'Have you already downloaded and do you want to skip the downloading? (y/n)'
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
      prepare-filesystem 
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
      prepare-filesystem 
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

# 10. Some post-processing procedures follow clonal origin runs.
# --------------------------------------------------------------
# Several analyses were performed using output of ClonalOrigin. Let's list
# those.
# recombination-intensity: I order all the alignment blocks with respect to the
# genome of SDE1, which is the 1st genome in the alignment.  The number of
# recombinant edges that affect a nucleotide site is recorded. 
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
      prepare-filesystem 
 
      select WHATANALYSIS in recombination-intensity convergence heatmap import-ratio-locus-tag summary recedge recmap traceplot parse-jcvi-role combine-import-ratio-jcvi-role; do 
        if [ "$WHATANALYSIS" == "" ];  then
          echo -e "You need to enter something\n"
          continue
        elif [ "$WHATANALYSIS" == "recombination-intensity" ]; then
          echo -e "Computing recombination intensity ..."
          echo perl $PERLRECOMBINATIONINTENSITY \
            -d $RUNCLONALORIGIN/output2-xml/${REPLICATE}/core_co.phase3
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
            -gff $RUNANALYSISDIR/NC_004070.gff \
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
          #perl pl/parse-jcvi-role.pl -in $RUNANALYSISDIR/jcvi_role.html > $RUNANALYSISDIR/jcvi_role.html.txt
          echo -e "Parsing jcvi_role.html to find role identifiers ...\n"
          #perl pl/parse-m3-locus.pl \
          #  -primary $RUNANALYSISDIR/bcp_m3_primary_locus.txt \
          #  -jcvi $RUNANALYSISDIR/bcp_m3_jcvi_locus.txt > \
          #  $RUNANALYSISDIR/bcp_m3_primary_to_jcvi.txt
          echo -e "Getting one-to-one relationships of locus_tag and JCVI loci ..."
          #perl pl/get-primary-jcvi-loci.pl $RUNANALYSISDIR/get-primary-jcvi-loci.txt
          echo -e "Listing locus_tags, their gene ontology, and JCVI roles" 
          #perl pl/list-locus-tag-go-jcvi-role.pl \
          #  -bcpRoleLink=$RUNANALYSISDIR/bcp_role_link \
          #  -bcpGoRoleLink=$RUNANALYSISDIR/bcp_go_role_link \
          #  -locusTagToJcviLocus=$RUNANALYSISDIR/get-primary-jcvi-loci.txt \
          #  > $RUNANALYSISDIR/list-locus-tag-go-jcvi-role.txt
          break
        elif [ "$WHATANALYSIS" == "combine-import-ratio-jcvi-role" ];  then
          echo -e "Combining import-ratio and jcvi-role ..."
          echo perl pl/combine-import-ratio-jcvi-role.pl \
            -importRatio $MAUVEANALYSISDIR/import-ratio-with-sde1.txt \
            -jcviRole $RUNANALYSISDIR/list-locus-tag-go-jcvi-role.txt
          break
        elif [ "$WHATANALYSIS" == "plot-import-ratio-jcvi-role" ];  then
          echo -e "Plotting import-ratio and jcvi-role ..."
          echo perl pl/plot-import-ratio-jcvi-role.pl \
            -importRatio $MAUVEANALYSISDIR/combine-import-ratio-jcvi-role.txt \
            -jcviRole $RUNANALYSISDIR/list-locus-tag-go-jcvi-role.txt
        fi
      done
      break
    fi
  done
}

# Find bacteria species and their counts in the NCBI genome data.
# ---------------------------------------------------------------
# The directory bacteria in NCBI's ftp site was downloaded for easy access to
# the raw sequence data set. $GENOMEDATADIR was the downloaded directory.
# A bacterial genome was stored in a separate directory in the ftp site. The
# name of a bacteria directory was prefixed species name. I extracted 
# species names from the bacteria directory names. 
function list-species {
  for i in `ls $GENOMEDATADIR`; do 
    echo $i | sed 's/\([[:alpha:]]*\)_\([[:alpha:]]*\)_.*/\1\_\2/'
  done
}

# Create species files in the species directory.
# ----------------------------------------------
# The species directory contains files, each of which lists NCBI Genbank files.
# An NCBI Genbank file name starts with the unique genome name: e.g., 
# Streptococcus_pyogenes_MGAS315_uid57911/NC_004070.gbk
# where the first directory is the genome name, and the second is its NCBI
# Genbank file. The following bash function creates a species file for one of
# species name in ALLSPECIES array. This is also a semi-automatic procedure. I
# do not use it, but I used it.  I just want to save the function. I filtered
# Genbank files with at least 1 Megabytes. This is undesirable because I do not
# know how large a genome Genbank file is. It would be better to find
# automatically find genome Genbank files in NCBI ftp directory bacteria. 
# Note that the base directory name is hard-coded in the sed command. Change the
# name to suit your need, and $GENOMEDATADIR should be the same as the directory
# name in the sed command.
function generate-species {
  prepare-filesystem
  for s in ${ALLSPECIES[@]}; do
    ls -1 `find $GENOMEDATADIR -name *.gbk -and -size +1000k` \
      | sed 's/\/Volumes\/Elements\/Documents\/Projects\/mauve\/bacteria\///' \
      | grep $s > $MAUVEANALYSISDIR/species/$s
  done
}

#####################################################################
# Main part of the script.
#####################################################################
PS3="Select what you want to do with mauve-analysis: "
CHOICES=( choose-species receive-run-mauve filter-blocks prepare-run-clonalframe receive-run-clonalframe prepare-run-clonalorigin receive-run-clonalorigin prepare-run-2nd-clonalorigin receive-run-2nd-clonalorigin analysis-clonalorigin list-species generate-species compute-watterson-estimate-for-clonalframe )
select CHOICE in ${CHOICES[@]}; do 
  if [ "$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "$CHOICE" == "list-species" ];  then
    list-species | sort | uniq -c | sort -nr > species.txt
    echo -e "A file named species.txt is generated!\n"
    echo -e "Remove counts by running cut -c 5- species.txt\n"
    break
  elif [ "$CHOICE" == "generate-species" ];  then
    generate-species 
    break
  elif [ "$CHOICE" == "choose-species" ];  then
    choose-species
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
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

