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

PMI_RANK=$1
JOBIDFILE=$2
LOCKFILE=$3

WHICHLINE=1
JOBID=0

cd $TMPDIR

# Read the filelock
#while [ $JOBID -lt $TOTALJOBS ] && [ $JOBID -lt $ENDJOBID ]
while [ "$JOBID" != "" ]
do

  # lockfile=filelock
  lockfile=$LOCKFILE
  if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; 
  then
    # BK: this will cause the lock file to be deleted 
    # in case of other exit
    trap 'rm -f "$lockfile"; exit $?' INT TERM

    # The critical section:
    # Read a line, and delete it.
    read -r JOBID < ${JOBIDFILE}
    sed '1d' $JOBIDFILE > $JOBIDFILE.temp; 
    mv $JOBIDFILE.temp $JOBIDFILE

    rm -f "$lockfile"
    trap - INT TERM

    if [ "$JOBID" == "" ]; then
      echo "No more jobs"
    else
      echo begin-$JOBID
      START_TIME=`date +%s`
      $JOBID
      END_TIME=`date +%s`
      ELAPSED=`expr $END_TIME - $START_TIME`
      echo end-$JOBID
      hms $ELAPSED
    fi

  else
    sleep 5
  fi

done
