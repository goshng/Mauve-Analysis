#!/bin/bash
#PBS -l nodes=1,walltime=4:00:00
#your account number
#PBS -A acs4_0001
#Join stdout and stderr
#PBS -j oe
#PBS -N Clans1Linux
#PBS -q v4

set -x

# Define directories for executable.
EXECBASE=b_clg.sh

BASE=${PBS_O_WORKDIR}
BIN=${BASE}/cl1_bin
FARM=/usr/local/bin/farm-out-work
DATA=${BASE}/data
RESULTDIR=${BASE}/results

# Set MPI information depending on where executed.
if [ -n "$PBS_NODEFILE" ]
then
  # Running in batch
  NODECNT=$(wc -l < "$PBS_NODEFILE")
  TASKCNT=`expr 8 '*' $NODECNT`
  RUNDIR=$PBS_O_WORKDIR
  JOBNUMBER=${PBS_JOBID%%.*}
elif [ "$HOST" == "v4linuxlogin1.cac.cornell.edu" ]
then
  # For quick testing on login node.
  RUNDIR=$PWD
  JOBNUMBER="01"
else
  # For interactive testing on development nodes
  NODECNT=1
  TASKCNT=4
  RUNDIR=$PWD
  PBS_NODEFILE=$RUNDIR/nodefile
  echo localhost>$PBS_NODEFILE
  JOBNUMBER=012
  DATA=$RUNDIR/data
fi

TASKFILE=$RUNDIR/tasks${JOBNUMBER}.txt
TASKBATCH=$RUNDIR/task${JOBNUMBER}.sh
rm -f $TASKFILE
rm -f $TASKBATCH

# Make the list of tasks
# Use full path to the task.
# This loops through input data, writing a lines to the tasks file.
# The taskind is just a counter so that each line has a unique index.
cd ${DATA}
taskind=0
for datafile in `dir data.*`
do
  echo $TASKBATCH ${datafile} ${taskind}>>$TASKFILE
    ((taskind+=1))
done

echo Wrote tasks.txt.
cd $RUNDIR

# Write the batch file for each task.
# This shell script writes a task.sh shell script.
# We want the created shell script to use some variables, but bash
# would normally substitute values for them, so we escape the 
# dollar sign with a backslash on those we want to keep.
# What is below would be written to look like the example above.
cat>${TASKBATCH}<<EOF
# task.sh - This is generated by batch.sh and run once for each task.
set -x
CASE=\$1
JOBINDEX=\$2
echo rank \$PMI_RANK \${CASE} \$JOBINDEX

if [ -n "\$TMPDIR" ]
then
  TEMPDIR=\$TMPDIR/${JOBNUMBER}_\${JOBINDEX}
else
  # When testing, use /tmp to create a temporary directory.
  TEMPDIR=/tmp/${JOBNUMBER}_\${JOBINDEX}
fi

if [ -d "\$TEMPDIR" ]
then
  echo Directory \$TEMPDIR already exists
else
  mkdir -p \$TEMPDIR
fi

OUTFILE=\${CASE}.txt

cp $DATA/\${CASE}* \$TEMPDIR/
# cp $BIN/* \$TEMPDIR/

cd \$TEMPDIR

date
date > \$OUTFILE
if [ "$PBS_O_QUEUE" == "v4" ]
then
  cat \$TEMPDIR/\${CASE} >> \$OUTFILE
  #./${EXECBASE} \${CASE} >> \$OUTFILE
else
  # When running on v4dev or not running in batch, just echo hostname.
  hostname >> \$OUTFILE
  hostname >> \${CASE}.mtl
fi
date >> \$OUTFILE
date

#cp \${CASE}.geo $RESULTDIR
#cp \${CASE}.em1 $RESULTDIR
#cp \${CASE}.dtr $RESULTDIR
#cp \${CASE}.mtl $RESULTDIR
cp \$OUTFILE $RESULTDIR

cd
rm -rf "\$TEMPDIR"
EOF
chmod a+x ${TASKBATCH}

echo Wrote task.sh.

# Don't mpdboot on the login node
if [ -n "$PBS_NODEFILE" ]
then
  if mpdboot -n $NODECNT --verbose -r /usr/bin/ssh -f $PBS_NODEFILE
  then
      mpiexec -ppn 8 -np $TASKCNT $FARM -v -t $TASKFILE
      mpdallexit
  fi
else
  echo No nodefile so no mpi to run.
fi

rm -f ${TASKFILE}
rm -f ${TASKBATCH}
