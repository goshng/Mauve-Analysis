#!/bin/bash
#PBS -l walltime=59:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep
#PBS -q v4dev

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


# Copy files to the compute node.
SCRATCH=/tmp/$USER
# -p tells mkdir not to worry if the directory already exists.
# If it matters, you could delete everything in the directory before starting.
rm -rf $SCRATCH
mkdir -p $SCRATCH
   
cp -r $RUNDIR/../xmfa-backup $SCRATCH/xmfa
cp $RUNDIR/../clonaltree.nwk $SCRATCH/
cp ~/usr/bin/warg $SCRATCH/
cp ~/usr/bin/xjobs $SCRATCH/
mkdir $SCRATCH/xml
XJOBSSCRIPT=xjobs-script-$PBS_ARRAYID.txt


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
#PMI_START=$(( 72 * PMI_RANK + 1 ))
#PMI_END=$(( 72 * (PMI_RANK + 1) ))
PMI_START=$(( 32 * PBS_ARRAYID + 1 ))
PMI_END=$(( 32 * (PBS_ARRAYID + 1) ))

touch $XJOBSSCRIPT
for (( i=${PMI_START}; i<=${PMI_END}; i++ ))
do
  if [ $i -lt 576 ]
  then
    echo \
      ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 1000 -x 1000 -y 1000 -z 10 \
      clonaltree.nwk xmfa/core_alignment.xmfa.$i xml/core_co.phase2.$i.xml \
      >> $XJOBSSCRIPT

  fi
done

./xjobs -s $XJOBSSCRIPT
cp xml/* $RUNDIR/xml/
cd
rm -rf $SCRATCH
