# Author: Sang Chul Choi
# Date  : Mon May  2 13:58:45 EDT 2011

# Prepare runs of computing the heatmap of recombinant edge counts.
# -----------------------------------------------------------------
# 1. Copy a set of input data to the cluster. 
#    (I could use the data in the cluster from run-clonalorigin2)
# 2. Create scripts for the input data.
# 3. Create a jobidfile.
# I wish to extract recedge counts for each iteration.
# I need to do this for computing sample variance as well.
function prepare-run-compute-heatmap-recedge {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of output files? (e.g., 1) "
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      NUMBER_SPECIES=$(echo `grep gbk $SPECIESFILE|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo -e "The number of species is $NUMBER_SPECIES."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"

      # perl pl/extractClonalOriginParameter12.pl \
      perl pl/compute-heatmap-recedge.pl \
        -d $RUNCLONALORIGIN/output2/${REPLICATE} \
        -e $RUNCLONALORIGIN/output2/priorcount-${REPLICATE} \
        -endblockid \
        -n $NUMBER_BLOCK \
        -s $NUMBER_SPECIES
        > $RUNANALYSIS/heatmap-recedge.txt
      echo "Check file $RUNANALYSIS/heatmap-recedge.txt"
      break
    fi
  done
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
#PBS -l walltime=$WALLTIME:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N Strep-${SPECIES}-ClonalOrigin
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# -l: The wall time is the time duration during which 
#     a job can run.  Use wall time enough to finish jobs.
# -A: The ID for accessing the cluster.
# -j: The standard and error output
# -N: The name of the job
# -q: The name of the queue
# -m: When is the job's status reported?
# -M: The email address to get the notification of the jobs
# -t: The number of nodes to use.  I would replace 
#     PBSARRAYSIZE with a positive number.

HOW_MANY_REPETITION=$HOW_MANY_REPETITION
HOW_MANY_REPLICATE=$HOW_MANY_REPLICATE
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
}

# Create output and status directories for each repeat.
# Create an input directory for each repeat.
# Copy all the data to the input for each repeat.
# Copy the tree file to the input directory.
function to-node-repeat {
  mkdir \$INPUTDIR/\$1
  cp \$PBS_O_WORKDIR/\$1/data/*.xmfa.* \$INPUTDIR/\$1
  mkdir \$OUTPUTDIR/\$1
  if [ "\$HOW_MANY_REPLICATE" == "1" ]; then
    mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/output/\${REPLICATE}
    mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/output2/\${REPLICATE}
    mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/status/\${REPLICATE}
    mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/status2/\${REPLICATE}
    cp \$PBS_O_WORKDIR/\$1/run-clonalorigin/input/\${REPLICATE}/$SPECIESTREE \\
      \$INPUTDIR/\$1
    mkdir \$OUTPUTDIR/\$1/\$REPLICATE
  else
    for REPLICATE in \$(eval echo {1..\$HOW_MANY_REPLICATE}); do 
      mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/output/\${REPLICATE}
      mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/output2/\${REPLICATE}
      mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/status/\${REPLICATE}
      mkdir -p \$PBS_O_WORKDIR/\$1/run-clonalorigin/status2/\${REPLICATE}
      cp \$PBS_O_WORKDIR/\$1/run-clonalorigin/input/\${REPLICATE}/$SPECIESTREE \\
        \$INPUTDIR/\$1
      mkdir \$OUTPUTDIR/\$1/\$REPLICATE
    done 
  fi
}

# Copy the results back to the working directory for each repeat.
function from-node-repeat {
  if [ "\$HOW_MANY_REPLICATE" == "1" ]; then
    if [[ -z \$CLONAL2ndPHASE ]]; then
      cp \$OUTPUTDIR/\$1/\${REPLICATE}/* \$PBS_O_WORKDIR/\$1/run-clonalorigin/output/\${REPLICATE}
    else
      cp \$OUTPUTDIR/\$1/\${REPLICATE}/* \$PBS_O_WORKDIR/\$1/run-clonalorigin/output2/\${REPLICATE}
    fi
  else
    for REPLICATE in \$(eval echo {1..\$HOW_MANY_REPLICATE}); do 
      if [[ -z \$CLONAL2ndPHASE ]]; then
        cp \$OUTPUTDIR/\$1/\${REPLICATE}/* \$PBS_O_WORKDIR/\$1/run-clonalorigin/output/\${REPLICATE}
      else
        cp \$OUTPUTDIR/\$1/\${REPLICATE}/* \$PBS_O_WORKDIR/\$1/run-clonalorigin/output2/\${REPLICATE}
      fi
    done 
  fi
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
for g in \$(eval echo {1..\$HOW_MANY_REPETITION}); do 
  to-node-repeat \$g
done

# What am I preparing?
prepare-task

# Run jobs in multiple nodes.
task

# Wait for all of the 8 processes to finish.
wait

for g in \$(eval echo {1..\$HOW_MANY_REPETITION}); do 
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
  nsub tbatch.sh 
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
    submit-clonalorigin \$HOW_MANY_NODE \$HOW_MANY_REPETITION
    break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done
EOF
  chmod a+x $RUN_SH
  scp -q $RUN_SH $2
  scp -q $RUN_BATCH_CLONALORIGIN_SH $2
  scp -q $RUN_BATCH_TASK_CLONALORIGIN_SH $2
}



