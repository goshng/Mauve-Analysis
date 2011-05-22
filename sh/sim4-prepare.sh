# Author: Sang Chul Choi
# Date  : Sat May  7 23:44:03 EDT 2011

function sim4-prepare {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s10" ] \
         || [ "$SPECIES" == "s11" ] \
         || [ "$SPECIES" == "s13" ] \
         || [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES

      # Copy data sets if necessary.
      # Create a main batch script: run.sh
      # Create a body batch script: batch_simulation3.sh
      # Create a task batch script: batch_simulation3_task.sh
      # Create a jobidfile: jobidfile
      # Copy perl scripts including
      # 1. clonalorigin2-simulation3-prepare.pl
      clonalorigin2-simulation3-prepare-copy-run-sh

      ssh -x $CAC_USERHOST mkdir -p $CAC_BASEDIR/pl
      scp -q pl/$FUNCNAME.pl $CAC_MAUVEANALYSISDIR/output/$SPECIES/pl/
      scp -q pl/sub*.pl $CAC_MAUVEANALYSISDIR/output/$SPECIES/pl/
      ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR/run-analysis
      scp -q $BASERUNANALYSIS/in.gene $CAC_MAUVEANALYSISDIR/output/$SPECIES/run-analysis/
      scp -q data/$INBLOCK $CAC_MAUVEANALYSISDIR/output/$SPECIES/run-analysis/

      echo -n "Do you wish to generate mt? (e.g., y/n)"
      read WISH
      if [ "$WISH" == "y" ]; then
        sim4-prepare-mt
      fi

      echo -n "Do you wish to send mt? (e.g., y/n)"
      read WISH
      if [ "$WISH" == "y" ]; then
        PROCESSEDTIME=0
        TOTALITEM=$(( $HOW_MANY_REPETITION * $HOW_MANY_REPLICATE ));
        ITEM=0
        for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
          for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            STARTTIME=$(date +%s)
            scp -qr $BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE \
              $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/output2
            ENDTIME=$(date +%s)
            ITEM=$(( $ITEM + 1 ))
            ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
            PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
            REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
            REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
            echo -ne "$REPETITION/$HOW_MANY_REPETITION - $REPLICATE/$HOW_MANY_REPLICATE - more $REMAINEDTIME min to go\r"
          done
        done
      fi

      echo "  Creating job files..."
      rm -f $BASEDIR/jobidfile
      clonalorigin2-simulation3-prepare-jobidfile
      scp -q $BASEDIR/jobidfile $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES/

      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}

function clonalorigin2-simulation3-prepare-copy-run-sh {
  RUN_SH=$OUTPUTDIR/$SPECIES/run.sh
  BATCH_SH=$OUTPUTDIR/$SPECIES/batch.sh
  cat>$RUN_SH<<EOF
#!/bin/bash
echo -n "How many computing nodes do you wish to use? (e.g., 3) "
read HOW_MANY_NODE
HOW_MANY_NODE=\$[ \$HOW_MANY_NODE - 1 ]
sed s/PBSARRAYSIZE/\$HOW_MANY_NODE/g < batch.sh > tbatch.sh
HOW_MANY_NODE=\$[ \$HOW_MANY_NODE + 1 ]
NUMBERLINE=\$(echo \`cat jobidfile|wc -l\`)
A=\$[ \$NUMBERLINE/\$HOW_MANY_NODE + 1 ]
split -d -l \$A jobidfile
nsub tbatch.sh 
rm tbatch.sh
EOF
  cat>$BATCH_SH<<EOF
#!/bin/bash
##PBS -l walltime=$WALLTIME:00,nodes=1
#PBS -l walltime=59:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N ${PROJECTNAME}-${SPECIES}-Simulation3
#PBS -q ${QUEUENAME}
##PBS -m e
##PBS -M ${BATCHEMAIL}
#PBS -t 0-PBSARRAYSIZE

# -l: The wall time is the time duration during which 
#     a job can run.  Use wall time enough to finish jobs.
# -A: The ID for accessing the cluster.
# -j: The standard and error output
# -N: The name of the job
# -q: The name of the queue
# -m: When is the job's status reported?
# -M: The email address to get notification of the jobs
# -t: The number of nodes to use.  I would replace 
#     PBSARRAYSIZE with a positive number.

HOW_MANY_REPETITION=$HOW_MANY_REPETITION
HOW_MANY_REPLICATE=$HOW_MANY_REPLICATE

# Sets the echo of the command line on.
set -x

# The full path of the clonal origin executable.
WARGSIM=\$HOME/Documents/Projects/mauve-analysis/src/clonalorigin/b/wargsim
# The input and output directories.

function copy-data {
  ID=\$(printf "%02d\\n" \$PBS_ARRAYID)
  cp \$PBS_O_WORKDIR/x\$ID \$TMPDIR/jobidfile
  cp \$WARGSIM \$TMPDIR
  cp \$PBS_O_WORKDIR/batch_task.sh \$TMPDIR 
  cp -r \$PBS_O_WORKDIR/pl \$TMPDIR
  mkdir \$TMPDIR/run-analysis
  cp \$PBS_O_WORKDIR/run-analysis/in.gene \$TMPDIR/run-analysis
  cp \$PBS_O_WORKDIR/run-analysis/$INBLOCK \$TMPDIR/run-analysis
  # HOW_MANY_REPETITION=1
  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    mkdir -p \$TMPDIR/\$g/run-clonalorigin/output2
    for REPLICATE in \$(eval echo {1..$HOW_MANY_REPLICATE}); do
      # cp -r \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/\$REPLICATE \$TMPDIR/\$g/run-clonalorigin/output2/
      # mkdir -p \$TMPDIR/\$g/run-clonalorigin/output2/mt-\$REPLICATE
      cp -r \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/mt-\$REPLICATE \$TMPDIR/\$g/run-clonalorigin/output2/
      mkdir -p \$TMPDIR/\$g/run-clonalorigin/output2/mt-\${REPLICATE}-out
    done
  done
}

function retrieve-data {
  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    for REPLICATE in \$(eval echo {1..$HOW_MANY_REPLICATE}); do
      cp -r \$TMPDIR/\$g/run-clonalorigin/output2/mt-\$REPLICATE-out \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/
    done
  done
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  NUMBERLINE=\$(echo \`cat jobidfile|wc -l\`)
  A=\$[ \$NUMBERLINE/\$CORESPERNODE + 1 ]
  split -d -l \$A jobidfile
  for (( i=0; i<CORESPERNODE; i++))
  do
    ID=\$(printf "%02d\\n" \$i)
    bash x\$ID &
    #bash batch_task.sh \\
      #\$i \\
      #\$PBS_O_WORKDIR/jobidfile \\
      #\$PBS_O_WORKDIR/lockfile&
  done
}
echo -n "Started at "; date
copy-data
process-data; wait
retrieve-data
cd /tmp; rm -rf \$TMPDIR
echo -n "End at "; date
EOF
 
  scp -q $RUN_SH $CAC_MAUVEANALYSISDIR/output/$SPECIES
  scp -q $BATCH_SH $CAC_MAUVEANALYSISDIR/output/$SPECIES
  clonalorigin2-simulation3-prepare-batch-task-sh
}

function clonalorigin2-simulation3-prepare-batch-task-sh {
  TASK_SH=$OUTPUTDIR/$SPECIES/batch_task.sh
  cat>$TASK_SH<<EOF
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
SCRATCH=\$5 # TMPDIR

WHICHLINE=1
JOBID=0

cd \$TMPDIR

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
      \$JOBID
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
  scp -q $TASK_SH $CAC_MAUVEANALYSISDIR/output/$SPECIES
}

function sim4-prepare-mt {
  PROCESSEDTIME=0
  TOTALITEM=$(( $HOW_MANY_REPETITION * $HOW_MANY_REPLICATE ));
  ITEM=0
  for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
    for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
      STARTTIME=$(date +%s)
      mkdir -p $BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE
      for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
        LINE="perl pl/sim4-prepare.pl \
              -xml $BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID \
              -out $BASEDIR/$REPETITION/run-clonalorigin/output2/mt-$REPLICATE/core_co.phase3.xml.$BLOCKID"
        #echo $LINE >> $BASEDIR/jobidfile
        $LINE
      done
      ENDTIME=$(date +%s)
      ITEM=$(( $ITEM + 1 ))
      ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
      PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
      REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
      REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
      echo -ne "$REPETITION/$HOW_MANY_REPETITION - $REPLICATE/$HOW_MANY_REPLICATE - more $REMAINEDTIME min to go\r"
    done
  done
}


function clonalorigin2-simulation3-prepare-jobidfile {
  PROCESSEDTIME=0
  TOTALITEM=$(( $HOW_MANY_REPETITION * $HOW_MANY_REPLICATE ));
  ITEM=0
  for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
    for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
      STARTTIME=$(date +%s)
      for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
        BLOCKSIZE=$(echo `perl pl/get-block-length.pl $BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID`)
        NUMBER_SAMPLE=$(echo `grep number $BASEDIR/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID|wc -l`)
        for g in $(eval echo {1..$NUMBER_SAMPLE}); do
          LINE="./wargsim \
                --xml-file $REPETITION/run-clonalorigin/output2/mt-$REPLICATE/core_co.phase3.xml.$BLOCKID.$g \
                --gene-tree \
                --out-file $REPETITION/run-clonalorigin/output2/mt-$REPLICATE-out/core_co.phase3.xml.$BLOCKID.$g \
                --block-length $BLOCKSIZE"
          echo $LINE >> $BASEDIR/jobidfile
        done
      done
      ENDTIME=$(date +%s)
      ITEM=$(( $ITEM + 1 ))
      ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
      PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
      REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
      REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
      echo -ne "$REPETITION/$HOW_MANY_REPETITION - $REPLICATE/$HOW_MANY_REPLICATE - more $REMAINEDTIME min to go\r"
    done
  done
}
