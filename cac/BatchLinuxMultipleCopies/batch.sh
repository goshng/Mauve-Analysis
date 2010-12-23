#!/bin/sh
#PBS -l walltime=59:00,nodes=2
#PBS -A acs4_0001
#PBS -j oe
#PBS -N insects
#PBS -q v4

# Turn on echo of shell commands
set -x

# Counts the number of cores on this host.
# Assume this doesn't change across the cluster.
CORESPERNODE=`grep processor /proc/cpuinfo | wc -l`

# Pull standard stuff from the environment variables
# If running under batch, as defined by the presence of
# a PBS_NODEFILE, then pull info from environment variables.
if [ -n "$PBS_NODEFILE" ]
then
  NODECNT=$(wc -l < "$PBS_NODEFILE")
  TASKCNT=`expr $CORESPERNODE \* $NODECNT`
  RUNDIR=$PBS_O_WORKDIR
  # The job id is something like 613.scheduler.v4linux.
  # This deletes everything after the first dot.
  JOBNUMBER=${PBS_JOBID%%.*}
  echo '============================'
  echo $0
  echo '============================'
else
  # These variables are used running an interactive debugging job
  # on v4dev.
  NODECNT=1
  TASKCNT=4
  RUNDIR=/home/gfs01/ajd27/dev/working
  PBS_NODEFILE=$RUNDIR/nodefile
  echo localhost>$PBS_NODEFILE
  JOBNUMBER=01
fi

# Set up our job
EXT=$JOBNUMBER
cd $RUNDIR

cat $PBS_NODEFILE
if mpdboot -n $NODECNT -r /usr/bin/ssh -f $PBS_NODEFILE
then
  mpiexec -ppn 1 -np $NODECNT $RUNDIR/to_node.sh $EXT $RUNDIR
  mpiexec -ppn $CORESPERNODE -np $TASKCNT $RUNDIR/task.sh $EXT $RUNDIR
  mpiexec -ppn 1 -np $NODECNT $RUNDIR/from_node.sh $EXT $RUNDIR

  mpdallexit
fi
