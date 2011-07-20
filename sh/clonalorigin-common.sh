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

  for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
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

