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

