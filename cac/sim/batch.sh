#!/bin/bash
#PBS -l walltime=168:00:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N s17
#PBS -q v4
#PBS -m e
#PBS -M schoi@cornell.edu
#PBS -t 1-PBSARRAYSIZE

OUTPUTBASE=output/s18
DATABASE=/v4scratch/sc2265/mauve/$OUTPUTBASE

# Replace this with 100 before the actual submission.
HOW_MANY_REPETITION=100


# Sets the echo of the command line on.
set -x

# The full path of the clonal origin executable.
WARG=$HOME/usr/bin/warg
# The input and output directories.

function copy-data {
  cp $WARG $TMPDIR
  cp $DATABASE/*.tree $TMPDIR 
  cp $PBS_O_WORKDIR/batch_task.sh $TMPDIR 
  mkdir -p $TMPDIR/$OUTPUTBASE
  for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
    mkdir -p $TMPDIR/$OUTPUTBASE/$g/run-clonalorigin/output2/1
    cp -r $DATABASE/$g/data $TMPDIR/$OUTPUTBASE/$g
  done 
}

function retrieve-data {
  mkdir -p $PBS_O_WORKDIR/$OUTPUTBASE
  for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
    mkdir $PBS_O_WORKDIR/$OUTPUTBASE/$g
    cp -r $TMPDIR/$OUTPUTBASE/$g/run-clonalorigin \
      $PBS_O_WORKDIR/$OUTPUTBASE/$g
  done
}

function process-data {
  cd $TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batch_task.sh \
      $i \
      $PBS_O_WORKDIR/jobidfile \
      $PBS_O_WORKDIR/lockfile&
  done
}

echo -n "Started at "; date
copy-data
process-data; wait
retrieve-data
echo -n "End at "; date

