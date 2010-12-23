#!/bin/bash

#R --no-save --args ${PMI_RANK} < main.R > out${PMI_RANK}.txt

function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

 
# Create a file extension unique to each hostname (if you want)
# The %%.* turns v4linuxlogin1.cac.cornell.edu into v4linuxlogin1.
EXT=$1-${HOSTNAME%%.*}
RUNDIR=$2
  
SCRATCH=/tmp/$USER
   
cd $SCRATCH

#PMI_START=$(( 72 * PMI_RANK + 1 ))
#PMI_END=$(( 72 * (PMI_RANK + 1) ))
PMI_START=$(( 3 * PMI_RANK + 1 ))
PMI_END=$(( 3 * (PMI_RANK + 1) ))

for (( i=${PMI_START}; i<=${PMI_END}; i++ ))
do
  if [ $i -lt 576 ]
  then
echo begin-$i
START_TIME=`date +%s`
#LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \
    time ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 10000 -x 10000 -y 10000 -z 1 \
      clonaltree.nwk xmfa/core_alignment.xmfa.$i xml/core_co.phase2.$i.xml
END_TIME=`date +%s`
ELAPSED=`expr $END_TIME - $START_TIME`
echo end-$i
hms $ELAPSED
  fi
done
