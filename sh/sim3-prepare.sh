# Author: Sang Chul Choi
# Date  : Thu May  5 13:45:53 EDT 2011

# Analyzes the 2nd stage of clonal origin simulation
# --------------------------------------------------
#
function sim3-prepare  {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES
      PAIRM=topology 

      # Copy data sets if necessary.
      # Create a main batch script: run.sh
      # Create a body batch script: batch_simulation3.sh
      # Create a task batch script: batch_simulation3_task.sh
      # Create a jobidfile: jobidfile
      # Copy perl scripts including
      # 1. sim3-prepare.pl
      sim3-prepare-copy-run-sh
      ssh -x $CAC_USERHOST mkdir -p $CAC_BASEDIR/pl
      ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR/run-analysis
      scp -q pl/sim3-prepare.pl $CAC_MAUVEANALYSISDIR/output/$SPECIES/pl/
      scp -q pl/sub*.pl $CAC_MAUVEANALYSISDIR/output/$SPECIES/pl/
      echo "Copy the correct in.gene file"
      # break
      scp -q $BASERUNANALYSIS/in.gene.4.block $CAC_MAUVEANALYSISDIR/output/$SPECIES/run-analysis/in.gene
      scp -q data/$INBLOCK $CAC_MAUVEANALYSISDIR/output/$SPECIES/run-analysis/in.block

      echo "  Creating job files..."
      sim3-prepare-jobidfile \
      make-run-list-repeat $g \
        $OUTPUTDIR/$SPECIES \
        $REPLICATE \
        $SPECIESTREE \
        > $BASEDIR/jobidfile
      scp -q $BASEDIR/jobidfile $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES/

break

      echo -n 'Do you wish to skip extracting recombination intensity? (y/n) '
      read SKIP
      if [ "$SKIP" == "y" ]; then
        echo "  Skipping copy of the output files because I've already copied them ..."
      else
        echo "Extracting the recombination events from ${HOW_MANY_REPETITION} XML files"
        echo "  of replicate ${REPLICATE}..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            if [ "$g" == 1 ] && [ "$REPLICATE" == 1 ]; then
              perl pl/$FUNCNAME.pl \
                -d $RUNCLONALORIGIN/output2/$REPLICATE \
                -xmfa $DATADIR/core_alignment.$REPLICATE.xmfa \
                -genelength $GENELENGTH \
                -inblock simulation/$INBLOCK \
                -endblockid \
                > $BASERUNANALYSIS/ri.txt
              echo -ne "Creating $BASERUNANALYSIS/ri.txt "
            else
              perl pl/$FUNCNAME.pl \
                -d $RUNCLONALORIGIN/output2/$REPLICATE \
                -xmfa $DATADIR/core_alignment.$REPLICATE.xmfa \
                -genelength $GENELENGTH \
                -inblock simulation/$INBLOCK \
                -endblockid \
                >> $BASERUNANALYSIS/ri.txt
              echo -ne "Appending $BASERUNANALYSIS/ri.txt "
            fi
            echo -ne "Repeition $g - $REPLICATE\r"
          done
        done
      fi

      echo -n 'Do you wish to skip dividing true recombination? (y/n) '
      read WANTSKIP
      if [ "$WANTSKIP" == "y" ]; then
        echo "  Skipping ..."
      else
        echo "  Dividing the true value of recombination..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          perl pl/extractClonalOriginParameter9.pl \
            -xml $DATADIR/core_alignment.xml
        done
      fi 

      extract_ri \
        yes \
        $REPLICATE \
        $HOW_MANY_REPETITION \
        core_alignment
      break
    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}

function extract_ri {
  ISTRUE=$1
  REPLICATE=$2
  HOW_MANY_REPETITION=$3
  WHATXMLFILEBASE=$4

  echo "Extracting the recombination events from ${HOW_MANY_REPETITION} XML files"
  echo "  of replicate ${REPLICATE}..."
  for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=$BASEDIR/$g
    DATADIR=$NUMBERDIR/data
    RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
    RUNANALYSIS=$NUMBERDIR/run-analysis
    CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
    CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

    if [ "$ISTRUE" == "yes" ]; then
      XMLBASE=$DATADIR
      XMLFILEBASE=$WHATXMLFILEBASE
      XMLFILE=$XMLBASE/$XMLFILEBASE.xml.1
      HEATFILE=$XMLBASE/${SPECIES}_${g}_heatmap-1.txt
    else
      XMLBASE=$RUNCLONALORIGIN/output2/$REPLICATE
      XMLFILEBASE=$WHATXMLFILEBASE
      XMLFILE=$XMLBASE/$XMLFILEBASE.1.xml
      HEATFILE=$XMLBASE/heatmap-1.txt
    fi

    # Files that we need to compare.
    if [ "$g" == 1 ]; then
      perl pl/analyze-run-clonalorigin2-simulation2.pl \
        -d $XMLBASE \
        -xmfa $DATADIR/core_alignment.1.xmfa \
        -genelength $GENELENGTH \
        -inblock simulation/$INBLOCK \
        -endblockid \
        -xmlbasename $XMLFILEBASE \
        > $BASERUNANALYSIS/ri-$ISTRUE.txt
    else
      perl pl/analyze-run-clonalorigin2-simulation2.pl \
        -d $XMLBASE \
        -xmfa $DATADIR/core_alignment.1.xmfa \
        -genelength $GENELENGTH \
        -inblock simulation/$INBLOCK \
        -endblockid \
        -xmlbasename $XMLFILEBASE \
        >> $BASERUNANALYSIS/ri-$ISTRUE.txt
      fi
    echo "Repeition $g"
  done
}

function sim3-prepare-copy-run-sh {
  RUN_SH=$OUTPUTDIR/$SPECIES/run.sh
  BATCH_SH=$OUTPUTDIR/$SPECIES/batch.sh
  cat>$RUN_SH<<EOF
#!/bin/bash
echo -n "How many computing nodes do you wish to use? (e.g., 3) "
read HOW_MANY_NODE
sed s/PBSARRAYSIZE/\$HOW_MANY_NODE/g < batch.sh > tbatch.sh
nsub tbatch.sh 
rm tbatch.sh
EOF
  cat>$BATCH_SH<<EOF
#!/bin/bash
##PBS -l walltime=$WALLTIME:00,nodes=1
#PBS -l walltime=36:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N ${PROJECTNAME}-${SPECIES}-Simulation3
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# -l: The wall time is the time duration during which 
#     a job can run.  Use wall time enough to finish jobs.
# -A: The ID for accessing the cluster.
# -j: The standard and error output
# -N: The name of the job
# -q: The name of the queue
# -m: When is the job's status reported?
# -M: The email address to get the notification of the jobs
# -t: The number of nodes to use.  I would replace 
#     PBSARRAYSIZE with a positive number.

HOW_MANY_REPETITION=$HOW_MANY_REPETITION
HOW_MANY_REPLICATE=$HOW_MANY_REPLICATE

# Sets the echo of the command line on.
set -x

# The full path of the clonal origin executable.
WARG=\$HOME/usr/bin/warg
# The input and output directories.

function copy-data {
  cp \$PBS_O_WORKDIR/batch_task.sh \$TMPDIR 
  cp -r \$PBS_O_WORKDIR/pl \$TMPDIR
  mkdir \$TMPDIR/run-analysis
  cp \$PBS_O_WORKDIR/run-analysis/in.gene \$TMPDIR/run-analysis
  cp \$PBS_O_WORKDIR/run-analysis/in.block \$TMPDIR/run-analysis
  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    mkdir -p \$TMPDIR/\$g/run-clonalorigin/output2
    for REPLICATE in \$(eval echo {1..$HOW_MANY_REPLICATE}); do
      cp -r \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/\$REPLICATE \$TMPDIR/\$g/run-clonalorigin/output2/
      mkdir -p \$TMPDIR/\$g/run-clonalorigin/output2/ri-\$REPLICATE
    done
  done
}

function retrieve-data {
  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    for REPLICATE in \$(eval echo {1..$HOW_MANY_REPLICATE}); do
      cp -r \$TMPDIR/\$g/run-clonalorigin/output2/ri-\$REPLICATE \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/
    done
  done
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batch_task.sh \\
      \$i \\
      \$PBS_O_WORKDIR/jobidfile \\
      \$PBS_O_WORKDIR/lockfile&
  done
}
echo -n "Started at "; date
copy-data
process-data; wait
retrieve-data
echo -n "End at "; date
EOF
 
  scp -q $RUN_SH $CAC_MAUVEANALYSISDIR/output/$SPECIES
  scp -q $BATCH_SH $CAC_MAUVEANALYSISDIR/output/$SPECIES
  sim3-prepare-batch-task-sh
}

function sim3-prepare-batch-task-sh {
  TASK_SH=$OUTPUTDIR/$SPECIES/batch_task.sh
  cat>$TASK_SH<<EOF
#!/bin/bash

function hms
{
  s=\$1
  h=\$((s/3600))
  s=\$((s-(h*3600)));
  m=\$((s/60));
  s=\$((s-(m*60)));
  printf "%02d:%02d:%02d\n" \$h \$m \$s
}

PMI_RANK=\$1
JOBIDFILE=\$2
LOCKFILE=\$3

WORKDIR=\$4
SCRATCH=\$5 # TMPDIR

WHICHLINE=1
JOBID=0

cd \$TMPDIR

# Read the filelock
#while [ \$JOBID -lt \$TOTALJOBS ] && [ \$JOBID -lt \$ENDJOBID ]
while [ "\$JOBID" != "" ]
do

  # lockfile=filelock
  lockfile=\$LOCKFILE
  if ( set -o noclobber; echo "\$\$" > "\$lockfile") 2> /dev/null; 
  then
    # BK: this will cause the lock file to be deleted 
    # in case of other exit
    trap 'rm -f "\$lockfile"; exit \$?' INT TERM

    # The critical section:
    # Read a line, and delete it.
    read -r JOBID < \${JOBIDFILE}
    sed '1d' \$JOBIDFILE > \$JOBIDFILE.temp; 
    mv \$JOBIDFILE.temp \$JOBIDFILE

    rm -f "\$lockfile"
    trap - INT TERM

    if [ "\$JOBID" == "" ]; then
      echo "No more jobs"
    else
      echo begin-\$JOBID
      START_TIME=\`date +%s\`
      \$JOBID
      END_TIME=\`date +%s\`
      ELAPSED=\`expr \$END_TIME - \$START_TIME\`
      echo end-\$JOBID
      hms \$ELAPSED
    fi

  else
    echo "Failed to acquire lockfile: \$lockfile." 
    echo "Held by \$(cat $lockfile)"
    sleep 5
    echo "Retry to access \$lockfile"
  fi

done
EOF
  scp -q $TASK_SH $CAC_MAUVEANALYSISDIR/output/$SPECIES
}

function sim3-prepare-jobidfile {
  for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
    for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
      for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
        LINE="perl pl/sim3-prepare.pl \
              -pairm $PAIRM \
              -xml $REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$BLOCKID \
              -ingene run-analysis/in.gene \
              -blockid $BLOCKID \
              -out $REPETITION/run-clonalorigin/output2/ri-$REPLICATE/$BLOCKID"
        echo $LINE
      done
    done
  done
}
