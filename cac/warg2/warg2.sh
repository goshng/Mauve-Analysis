#!/bin/bash
#PBS -l walltime=59:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep
#PBS -q v4dev

set -x

# TOTALJOBS=575
TOTALJOBS=13
cd $PBS_O_WORKDIR

CORESPERNODE=`grep processor /proc/cpuinfo | wc -l`

NODECNT=$(wc -l < "$PBS_NODEFILE")
TASKCNT=`expr $CORESPERNODE \* $NODECNT`
JOBSPERCORE=$(( TOTALJOBS / TASKCNT + 1 ))
RUNDIR=$PBS_O_WORKDIR
# The job id is something like 613.scheduler.v4linux.
# This deletes everything after the first dot.
JOBNUMBER=${PBS_JOBID%%.*}
echo '============================'
echo $0
echo '============================'

echo "TASKCNT"
echo $TASKCNT

EXT=$JOBNUMBER
cd $RUNDIR

SCRATCH=/tmp/$USER

function to-node {
  # -p tells mkdir not to worry if the directory already exists.
  # If it matters, you could delete everything in the directory before starting.
  rm -rf $SCRATCH
  mkdir -p $SCRATCH
     
  cp -r ../xmfa-backup $SCRATCH/xmfa
  cp ../clonaltree.nwk $SCRATCH/
  cp ~/usr/bin/warg $SCRATCH/
  cp warg2_task.sh $SCRATCH/  
  mkdir $SCRATCH/xml
}

function task {
  cd $SCRATCH 
  #for i in {1..8}
  for (( i=1; i<=TASKCNT; i++))
  do
    bash warg2_task.sh $i $JOBSPERCORE $TOTALJOBS $RUNDIR $SCRATCH&
  done
}

to-node
task

wait
cd
rm -rf $SCRATCH
