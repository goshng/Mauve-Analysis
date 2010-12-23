#!/bin/bash

function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

set -x

PMI_RANK=$1
JOBSPERCORE=$2
TOTALJOBS=$3
RUNDIR=$4
SCRATCH=$5

cd $SCRATCH

#PMI_START=$(( 72 * (PMI_RANK - 1) + 1 ))
#PMI_END=$(( 72 * (PMI_RANK) ))
PMI_START=$(( JOBSPERCORE * (PMI_RANK - 1) + 1 ))
PMI_END=$(( JOBSPERCORE * (PMI_RANK) ))

for (( i=${PMI_START}; i<=${PMI_END}; i++ ))
do
  if [ $i -lt $TOTALJOBS ]
  then

    echo begin-$i
    START_TIME=`date +%s`
#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \
    ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 10000 -x 10000 -y 10000 -z 100 \
      clonaltree.nwk xmfa/core_alignment.xmfa.$i xml/core_co.phase2.$i.xml
    END_TIME=`date +%s`
    ELAPSED=`expr $END_TIME - $START_TIME`
    echo end-$i
    hms $ELAPSED
    cp $SCRATCH/xml/core_co.phase2.$i.xml $RUNDIR/xml/

  fi
done


