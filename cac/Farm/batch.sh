#!/bin/bash
#PBS -l nodes=1,walltime=4:00:00
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Clans1Linux
#PBS -q v4

set -x

BASE=${PBS_O_WORKDIR}
FARM=/usr/local/bin/farm-out-work
TASKFILE=$BASE/tasks.txt

NODECNT=$(wc -l < "$PBS_NODEFILE")
TASKCNT=`expr 8 '*' $NODECNT`
if mpdboot -n $NODECNT --verbose -r /usr/bin/ssh -f $PBS_NODEFILE
then
  mpiexec -ppn 8 -np $TASKCNT $FARM -v -t $TASKFILE
  mpdallexit
fi
