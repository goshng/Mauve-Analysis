#!/bin/bash
# File  : run.sh
# Author: Sang Chul Choi
# Date  : Wed Mar 16 16:59:42 EDT 2011

# This is the key run file to analyze bacterial genome data sets using
# ClonalOrigin. A menu is displayed so that a user can choose an operation that
# she or he wants to execute. Some commands do their job on their own right, and
# others require users to go to a cluster to submit a job. Each menu is executed
# by its corresponding bash function. Locate the bash function to see
# what it does. 

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
# simulate-data-clonalorigin1-receive
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
MAUVEANALYSISDIR=`pwd`
source sh/conf.sh
source sh/read-species.sh
conf

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
#
# In simulation for second stage of Clonal Origin a clonal frame and recombinant
# edges are fixed to generate a number of DNA sequence alignments. A number of
# replicates are generated with a given clonal frame and its recombinant edges
# fixed. A number of repetitions are performed and each repetition would have
# a different set of recombinant edges. I am not sure what this kind of two
# levels of repeated experiments can do for me. I could generate data with a
# clonal frame with its recombinant edges where a set of recombinant edges can
# come from one iteration of ClonalOrigin output.
#
CLONALFRAMEREPLICATE=1
REPLICATE=1
REPETITION=1

# Perl scripts
PERLRECOMBINATIONMAP=pl/recombinationmap.pl
PERLLISTGENEGFF=pl/listgenegff.pl 
PERLECOP=pl/extractClonalOriginParameter.pl
PERLECOP2=pl/extractClonalOriginParameter2.pl
PERLECOP3=pl/extractClonalOriginParameter3.pl
PERLECOP4=pl/extractClonalOriginParameter4.pl
PERLRECOMBINATIONINTENSITY=pl/recombination-intensity.pl
PERLRECOMBINATIONINTENSITY2=pl/recombination-intensity2.pl
PERLGUIPERL=pl/findBlocksWithInsufficientConvergence.pl

# SEQUENCE Command can be different for Linux and MacOSX.
# This will be deleted.
if [[ "$OSTYPE" =~ "linux" ]]; then
  SEQ=seq
elif [[ "$OSTYPE" =~ "darwin" ]]; then
  SEQ=jot
fi

SIMULATIONS=$(ls species|grep ^s)
SPECIESS=$(ls species|grep -v ^s)

source sh/hms.sh
source sh/set-more-global-variable.sh
source sh/mkdir-species.sh
source sh/read-species-file.sh 
 
###############################################################################
# Function: batch script
###############################################################################

function copy-batch-sh-run-clonalorigin {
  REPETITION=$1
  RUNCLONALORIGIN=$2/$REPETITION/run-clonalorigin 
  BATCH_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch.sh
  BATCH_BODY_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_body.sh
  BATCH_TASK_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_task.sh
  CAC_RUNCLONALORIGIN=$3
  SPECIES=$4
  SPECIESTREE=$5
  REPLICATE=$6
  CLONAL2ndPHASE=$7
  CAC_RUNCLONALORIGINOUTPUT=$3/$REPETITION/run-clonalorigin

  cat>$BATCH_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
sed s/PBSARRAYSIZE/\$1/g < batch_body.sh > tbatch.sh
nsub tbatch.sh
rm tbatch.sh
EOF

  cat>$BATCH_BODY_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
#PBS -l walltime=24:00:00,nodes=1
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
WARG=\$HOME/usr/bin/warg
OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input

function to-node {
  mkdir \$INPUTDIR
  mkdir \$OUTPUTDIR
  cp \$PBS_O_WORKDIR/batch_task.sh \$TMPDIR/  
  cp \$WARG \$TMPDIR/
}

function to-node-repeat {
  mkdir -p \$PBS_O_WORKDIR/output/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/output2/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/status/\${REPLICATE}
  mkdir -p \$PBS_O_WORKDIR/status2/\${REPLICATE}
  mkdir \$INPUTDIR/\$1
  mkdir \$OUTPUTDIR/\$1
  cp \$PBS_O_WORKDIR/../data/*.xmfa.* \$INPUTDIR/\$1
  cp \$PBS_O_WORKDIR/input/\${REPLICATE}/$SPECIESTREE \\
    \$INPUTDIR/\$1
}

# Copy the results back to the working directory for each repeat.
function from-node-repeat {
  if [[ -z \$CLONAL2ndPHASE ]]; then
    cp \$OUTPUTDIR/\$1/* \$PBS_O_WORKDIR/output/\${REPLICATE}
  else
    cp \$OUTPUTDIR/\$1/* \$PBS_O_WORKDIR/output2/\${REPLICATE}
  fi
}

function prepare-task {
  JOBIDFILE=\$PBS_O_WORKDIR/jobidfile
  LOCKFILE=\$PBS_O_WORKDIR/lockfile
}

function task {
  cd \$TMPDIR
  CORESPERNODE=8
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
to-node-repeat $REPETITION

# What am I preparing?
prepare-task

# Run jobs in multiple nodes.
task

# Wait for all of the 8 processes to finish.
wait

from-node-repeat $REPETITION

echo -n "End at "
date
echo -e "The job is finished."
EOF

  # Task batch script
  create-batch-task-sh $BATCH_TASK_SH_RUN_CLONALORIGIN

  chmod a+x $BATCH_SH_RUN_CLONALORIGIN
  scp -q $BATCH_SH_RUN_CLONALORIGIN \
    $CAC_RUNCLONALORIGINOUTPUT
  scp -q $BATCH_BODY_SH_RUN_CLONALORIGIN \
    $CAC_RUNCLONALORIGINOUTPUT
  scp -q $BATCH_TASK_SH_RUN_CLONALORIGIN \
    $CAC_RUNCLONALORIGINOUTPUT
}

# A list of jobs for a repeat is created in a file.
function make-run-list-repeat {
  g=$1
  BASEDIR=$2
  REPLICATE=$3
  SPECIESTREE=$4
  CLONAL2ndPHASE=$5

  NUMBERDIR=$BASEDIR/$g
  for l in `ls $NUMBERDIR/data/*.xmfa.*`; do 
    XMFA_FILE=$(basename $l) 
    # After deletion of longest match from XMFA_FILE.
    BLOCKID=${XMFA_FILE##*.}
    REPLICATEID=$(eval echo $XMFA_FILE | cut -d'.' -f 2)
    if [ "$REPLICATEID" == "xmfa" ]; then
      REPLICATEID=""
    else
      REPLICATEID="$REPLICATEID/"
    fi

    if [[ -z $CLONAL2ndPHASE ]]; then
      LINE="-a 1,1,0.1,1,1,1,1,1,0,0,0 \
            -x $BURNIN -y $CHAINLENGTH -z $THIN \
            input/$g/$SPECIESTREE input/$g/$XMFA_FILE \
            output/$g/${REPLICATEID}core_co.phase2.xml.$BLOCKID"
            #output/$g/core_co.phase2.$REPLICATEID.xml.$BLOCKID"
            # output/$g/core_co.phase2.$BLOCKID.xml"
      XML_FILE=$NUMBERDIR/run-clonalorigin/output/$REPLICATE/core_co.phase2.xml.$BLOCKID
      if [ -f "$XML_FILE" ]; then
        FINISHED=$(tail -n 1 $XML_FILE)
        if [[ ! "$FINISHED" =~ "outputFile" ]]; then
          echo $LINE
        fi
      else
        echo $LINE
      fi 
    else
      LINE="-a 1,1,0.1,1,1,1,1,1,0,0,0 \
            -x $BURNIN -y $CHAINLENGTH -z $THIN \
            -T s${MEDIAN_THETA} -D ${MEDIAN_DELTA} -R s${MEDIAN_RHO} \
            input/$g/$SPECIESTREE input/$g/$XMFA_FILE \
            output/$g/${REPLICATEID}core_co.phase3.xml.$BLOCKID"
            #output/$g/core_co.phase3.$REPLICATEID.xml.$BLOCKID"
            #output/$g/core_co.phase3.$BLOCKID.xml"
            #-x 1000000 -y 1000000 -z 10000 \
            #-x 100 -y 100 -z 10 \
            #-x 1000000 -y 10000000 -z 100000 \
    #LINE="-a 1,1,0.1,1,1,1,1,1,0,0,0 \
          #-x 1000000 -y 10000000 -z 10000 \
          #input/$g/clonaltree.nwk input/$g/$XMFA_FILE \
          #output/$g/core_co.phase2.$BLOCKID.xml"
      XML_FILE=$NUMBERDIR/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID
      if [ -f "$XML_FILE" ]; then
        FINISHED=$(tail -n 1 $XML_FILE)
        if [[ ! "$FINISHED" =~ "outputFile" ]]; then
          echo $LINE
        fi
      else
        echo $LINE
      fi 
    fi
   
  done
}

# A list jobs are stored as a file, which is accessed by all of the computing
# nodes.
function make-run-list {
  HOW_MANY_REPETITION=$1
  BASEDIR=$2
  REPLICATE=$3
  SPECIESTREE=$4
  CLONAL2ndPHASE=$5

  for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
    make-run-list-repeat $g $BASEDIR $REPLICATE $SPECIESTREE $CLONAL2ndPHASE
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

source sh/copy-run-sh.sh

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
  cp \$LCBDIR/*.xmfa.* \$INPUTDIR/
  cp \$WORKDIR/remain.txt \$TMPDIR/
  cp \$WORKDIR/input/\${REPLICATE}/clonaltree.nwk \$TMPDIR/
  cp \$WARG \$TMPDIR/
  cp \$WORKDIR/batch_task.sh \$TMPDIR/  
}

function prepare-task {
  # NODENUMBER=8 # What is this number? Is this number of cores of a node?

  # I need to count total jobs.
  TOTALJOBS=\$(ls -1 \$INPUTDIR/*.xmfa.* | wc -l)

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
          STATUSFILE=\$WORKDIR/status/\${REPLICATE}/core_co.phase2.\$JOBID.status
          if [ ! -f "\$STATUSFILE" ]; then
            touch \$STATUSFILE
            ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 10000000 -z 10000 \\
              clonaltree.nwk input/core_alignment.xmfa.\$JOBID \\
              \$WORKDIR/output/\${REPLICATE}/core_co.phase2.\$JOBID.xml
            rm \$STATUSFILE
          fi
        fi
      else
        FINISHED=\$(tail -n 1 \$WORKDIR/output2/\${REPLICATE}/core_co.phase3.\$JOBID.xml)
        if [[ "\$FINISHED" =~ "outputFile" ]]; then
          echo Already finished: \$WORKDIR/output2/\${REPLICATE}/core_co.phase3.\$JOBID.xml
        else
          STATUSFILE=\$WORKDIR/status2/\${REPLICATE}/core_co.phase3.\$JOBID.status
          if [ ! -f "\$STATUSFILE" ]; then
            touch \$STATUSFILE
            ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 10000000 -z 100000 \\
              -T s${MEDIAN_THETA} -D ${MEDIAN_DELTA} -R s${MEDIAN_RHO} \\
              clonaltree.nwk input/core_alignment.xmfa.\$JOBID \\
              \$WORKDIR/output2/\${REPLICATE}/core_co.phase3.\$JOBID.xml
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

function compute-watterson-estimate-for-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      set-more-global-variable 
      # Find all the blocks in FASTA format.
      echo -e "  Computing Wattersons's estimates...\n"
      rm -f $DATADIR/core_alignment.xmfa.*
      perl pl/blocksplit2fasta.pl $DATADIR/core_alignment.xmfa
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


# 8. Check the convergence
# ------------------------
# A multiple runs of the first stage of ClonalOrigin are checked for their
# convergence.
# FIXME: we need a bash function.

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
# recombination-intensity2 menu. It draws the distribution of numbers of
# recombinant edge types over sites of all of the alignment blocks.
# recombination-intensity.eps shows the distribution.
# 
#
# More literature search for studies of bacterial recombination.
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
              FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$j/core_co.phase2.$i.xml)
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
                $GUI -b -o $RUNCLONALORIGIN/output/1/core_co.phase2.$i.xml \
                  -g $RUNCLONALORIGIN/output/2/core_co.phase2.$i.xml,$RUNCLONALORIGIN/output/3/core_co.phase2.$i.xml:1 \
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
            if [ -f "$RUNCLONALORIGIN/output2-xml/${REPLICATE}/core_co.phase3.$i.xml" ]; then
              # Compute prior expected number of recedges.
              $GUI -b \
                -o $RUNCLONALORIGIN/output2-xml/${REPLICATE}/core_co.phase3.$i.xml \
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
            $RUNCLONALORIGIN/output/core*.xml \
            > $RUNCLONALORIGIN/log.p
          break
        elif [ "$WHATANALYSIS" == "recedge" ];  then
          echo -e "Finding the number of recombination events inferred relative to its expectation under our prior model given the stage 2 inferred recombination rate, for each donor/recipient pair of branches.\n"
          perl $ECOP2 \
            $RUNCLONALORIGIN/output2/${REPLICATE}/core*.xml.bz2 \
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
            $RUNCLONALORIGIN/output/${REPLICATE}/core*.xml \
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

source sh/progressbar.sh
source sh/init-file-system.sh
source sh/choose-simulation.sh 
source sh/simulate-data-clonalorigin1-prepare.sh
source sh/simulate-data-clonalorigin1-receive.sh 
source sh/simulate-data-clonalorigin1-analyze.sh
source sh/receive-run-2nd-clonalorigin.sh
source sh/prepare-mauve-alignment.sh
 

source sh/scatter-plot-parameter.sh
source sh/plot-number-recombination-within-blocks.sh
source sh/heatmap-compute.sh
source sh/heatmap-get-observed.sh
source sh/compute-global-median.sh
source sh/simulate-data-clonalorigin2-prepare.sh 
source sh/sim2-analyze.sh 
source sh/divide-simulated-xml-data.sh
source sh/divide-simulated-xmfa-data.sh
source sh/simulate-data-clonalorigin2.sh
source sh/receive-run-clonalorigin.sh 
source sh/prepare-run-2nd-clonalorigin.sh
source sh/simulate-data-clonalorigin2-from-xml.sh
source sh/probability-recombination.sh
source sh/map-tree-topology.sh
source sh/compute-heatmap-recedge.sh
source sh/prepare-run-compute-heatmap-recedge.sh
source sh/analyze-run-clonalorigin2-simulation2.sh 
source sh/sim3-prepare.sh 
source sh/sim3-receive.sh 
source sh/sim3-analyze.sh 
source sh/create-ingene.sh
source sh/convert-gff-ingene.sh 
source sh/locate-gene-in-block.sh
source sh/list-gene-go.sh
source sh/clonalorigin2-simulation3.sh
source sh/sim4-prepare.sh
source sh/sim4-receive.sh
source sh/sim4-analyze.sh
source sh/sim4-each-block.sh
source sh/extract-species-tree.sh
source sh/compute-block-length.sh
source sh/simulate-data-clonalorigin1.sh
source sh/summarize-clonalorigin1.sh 
source sh/recombination-intensity1-map.sh 
source sh/recombination-intensity1-genes.sh 
source sh/recombination-intensity1-probability.sh 
source sh/probability-recedge-gene.sh
source sh/receive-mauve-alignment.sh
source sh/prepare-run-clonalframe.sh
source sh/receive-run-clonalframe.sh
source sh/filter-blocks.sh
source sh/prepare-run-clonalorigin.sh 

#####################################################################
# Main part of the script.
#####################################################################
PS3="Select what you want to do with mauve-analysis: "
CHOICES=( init-file-system \
          choose-simulation \
          --- SIMULATION1 ---\
          simulate-data-clonalorigin1 \
          simulate-data-clonalorigin1-prepare \
          simulate-data-clonalorigin1-receive \
          simulate-data-clonalorigin1-analyze \
          --- SIMULATION2 ---\
          simulate-data-clonalorigin2 \
          simulate-data-clonalorigin2-prepare \
          sim2-receive \
          sim2-analyze \
          simulate-data-clonalorigin2-analyze \
          analyze-run-clonalorigin2-simulation \
          --- SIMULATION3 ---\
          analyze-run-clonalorigin2-simulation2 \
          sim3-prepare \
          sim3-receive \
          sim3-analyze \
          --- SIMULATION4 ---\
          clonalorigin2-simulation3 \
          sim4-prepare \
          sim4-receive \
          sim4-analyze \
          sim4-each-block \
          --- SIMULATION5 ---\
          clonalorigin2-simulation4 \
          --- SIMULATION5 ---\
          simulate-data-clonalorigin2-from-xml \
          --- REAL-DATA-ALIGNMENT ---\
          prepare-mauve-alignment \
          copy-mauve-alignment \
          receive-mauve-alignment \
          --- REAL-DATA-CLONALFRAME ---\
          filter-blocks \
          prepare-run-clonalframe \
          receive-run-clonalframe \
          --- CLONALORIGIN1 ---\
          prepare-run-clonalorigin \
          receive-run-clonalorigin \
          --- THREE-PARAMETERS ---\
          summarize-clonalorigin1 \
          --- CLONALORIGIN2 ---\
          prepare-run-2nd-clonalorigin \
          receive-run-2nd-clonalorigin \
          --- RECOMBINATION-COUNT ---\
          scatter-plot-parameter \
          plot-number-recombination-within-blocks \
          --- RECOMBINATION-COUNT ---\
          count-observed-recedge \
          compute-prior-count-recedge \
          compute-heatmap-recedge \
          --- RECOMBINATION-COUNT ---\
          prepare-run-compute-heatmap-recedge \
          --- RECOMBINATION-INTENSITY1 ---\
          probability-recombination \
          recombination-intensity1-map \
          recombination-intensity1-genes \
          recombination-intensity1-probability \
          probability-recedge-gene \
          --- RECOMBINATION-INTENSITY2 ---\
          recombination-intensity2-map \
          map-tree-topology \
          --- GENE-ANNOTATION ---\
          convert-gff-ingene \
          locate-gene-in-block \
          list-gene-go \
          ----------\
          analysis-clonalorigin \
          compute-watterson-estimate-for-clonalframe \
          compute-block-length \
          compute-global-median \
          create-ingene \
          extract-species-tree \
          simulate-data-clonalorigin1-prepare )
select CHOICE in ${CHOICES[@]}; do 
  if [ "$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "$CHOICE" == "init-file-system" ]; then $CHOICE; break
  elif [ "$CHOICE" == "choose-simulation" ]; then $CHOICE; break
  elif [ "$CHOICE" == "copy-mauve-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-mauve-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "receive-mauve-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "filter-blocks" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-clonalframe" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-watterson-estimate-for-clonalframe" ];  then
    compute-watterson-estimate-for-clonalframe
    break
  elif [ "$CHOICE" == "receive-run-clonalframe" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-clonalorigin" ]; then $CHOICE; break
  elif [ "$CHOICE" == "receive-run-clonalorigin" ]; then $CHOICE; break
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
  elif [ "$CHOICE" == "sim2-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-block-length" ];  then
    compute-block-length
    break
  elif [ "$CHOICE" == "simulate-data" ];  then
    simulate-data
    break
  elif [ "$CHOICE" == "simulate-data-clonalorigin2-from-xml" ]; then
    $CHOICE
    break
  elif [ "$CHOICE" == "scatter-plot-parameter" ]; then $CHOICE; break
  elif [ "$CHOICE" == "plot-number-recombination-within-blocks" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-prior-count-recedge" ];  then
    heatmap-compute
    break
  elif [ "$CHOICE" == "count-observed-recedge" ];  then
    heatmap-get-observed
    break
  elif [ "$CHOICE" == "compute-global-median" ];  then
    compute-global-median
    break
  elif [ "$CHOICE" == "divide-simulated-xml-data" ];  then
    divide-simulated-xml-data
    break
  elif [ "$CHOICE" == "divide-simulated-xmfa-data" ];  then
    divide-simulated-xmfa-data
    break
  elif [ "$CHOICE" == "probability-recombination" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-heatmap-recedge" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-compute-heatmap-recedge" ]; then $CHOICE; break
  elif [ "$CHOICE" == "map-tree-topology" ]; then $CHOICE; break
  elif [ "$CHOICE" == "analyze-run-clonalorigin2-simulation2" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim3-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim3-receive" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim3-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "create-ingene" ]; then $CHOICE; break
  elif [ "$CHOICE" == "convert-gff-ingene" ]; then $CHOICE; break
  elif [ "$CHOICE" == "locate-gene-in-block" ]; then $CHOICE; break
  elif [ "$CHOICE" == "list-gene-go" ]; then $CHOICE; break
  elif [ "$CHOICE" == "clonalorigin2-simulation3" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-receive" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-each-block" ]; then $CHOICE; break
  elif [ "$CHOICE" == "extract-species-tree" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin2" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1-receive" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim2-receive" ]; then
    simulate-data-clonalorigin1-receive Clonal2ndPhase
    break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin2-prepare" ];  then
    simulate-data-clonalorigin2-prepare Clonal2ndPhase
    break
  elif [ "$CHOICE" == "summarize-clonalorigin1" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-intensity1-genes" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-intensity1-probability" ]; then $CHOICE; break
  elif [ "$CHOICE" == "probability-recedge-gene" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-intensity1-map" ]; then $CHOICE; break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

