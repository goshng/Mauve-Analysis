#!/bin/bash
#PBS -l walltime=59:00,nodes=2
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep
#PBS -q v4

cd $PBS_O_WORKDIR

CORESPERNODE=`grep processor /proc/cpuinfo | wc -l`

NODECNT=$(wc -l < "$PBS_NODEFILE")
TASKCNT=`expr $CORESPERNODE \* $NODECNT`
RUNDIR=$PBS_O_WORKDIR
# The job id is something like 613.scheduler.v4linux.
# This deletes everything after the first dot.
JOBNUMBER=${PBS_JOBID%%.*}
echo '============================'
echo $0
echo '============================'


EXT=$JOBNUMBER
cd $RUNDIR

cat $PBS_NODEFILE
if mpdboot -n $NODECNT -r /usr/bin/ssh -f $PBS_NODEFILE
then
  mpiexec -ppn 1 -np $NODECNT $RUNDIR/warg1_to_node.sh $EXT $RUNDIR
  mpiexec -ppn $CORESPERNODE -np $TASKCNT $RUNDIR/warg1_task.sh $EXT $RUNDIR
  mpiexec -ppn 1 -np $NODECNT $RUNDIR/warg1_from_node.sh $EXT $RUNDIR
  mpdallexit
fi


