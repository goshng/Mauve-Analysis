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
TOTALJOBS=$2
ENDJOBID=$3
RUNDIR=$4
SCRATCH=$5
JOBIDFILE=$6
WHICHLINE=1
JOBID=0

cd $SCRATCH

# Read the filelock
while [ $JOBID -lt $TOTALJOBS ] && [ $JOBID -lt $ENDJOBID ]
do

  lockfile=filelock
  if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; 
  then
    # BK: this will cause the lock file to be deleted in case of other exit
    trap 'rm -f "$lockfile"; exit $?' INT TERM

    # critical-section BK: (the protected bit)
    JOBID=$(sed -n "${WHICHLINE}p" "${JOBIDFILE}")

    #LINE=$(sed -n "${WHICHLINE}p" "${COMMANDFILE}")
    #$LINE : this execute the line.
    JOBID=$(( JOBID + 1))
    echo $JOBID > $JOBIDFILE
    JOBID=$(( JOBID - 1))

    rm -f "$lockfile"
    trap - INT TERM

    if [ $JOBID -lt $TOTALJOBS ] && [ $JOBID -lt $ENDJOBID ]
    then
      echo begin-$JOBID
      START_TIME=`date +%s`
      #LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \
      #./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 10000 -x 10000 -y 10000 -z 100 \
        #clonaltree.nwk xmfa/core_alignment.xmfa.$JOBID xml/core_co.phase2.$JOBID.xml
      ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 10000 -x 10000 -y 10000 -z 100 \
        -D 1725.16905094905 -T 0.0386842013408279 -R 0.000773885007973949 \
        clonaltree.nwk xmfa/core_alignment.xmfa.$JOBID xml3/core_co.phase3.$JOBID.xml
      END_TIME=`date +%s`
      ELAPSED=`expr $END_TIME - $START_TIME`
      echo end-$JOBID
      hms $ELAPSED
      #cp $SCRATCH/xml/core_co.phase2.$JOBID.xml $RUNDIR/xml/
      cp $SCRATCH/xml3/core_co.phase3.$JOBID.xml $RUNDIR/xml3/
    fi

  else
    echo "Failed to acquire lockfile: $lockfile." 
    echo "Held by $(cat $lockfile)"
    sleep 5
    echo "Retry to access $lockfile"
  fi

done



