###############################################################################
# Copyright (C) 2011 Sang Chul Choi
#
# This file is part of Mauve Analysis.
# 
# Mauve Analysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mauve Analysis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mauve Analysis.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

SPECIES=cornell5
REPETITION=1
REPLICATE=1
function batch {
  batch-variable
  batch-output
  batch-speciesfile 

  batch-copy-genome
  batch-run
  batch-mauve
  batch-lcb
  batch-watterson
  batch-watterson-r
  batch-clonalframe
  batch-run-coi
  batch-analyze-coi
  batch-analyze-coi-r
  batch-run-coii
  batch-analyze-coii
  batch-analyze-coii-r
  batch-summary-coii
  batch-summary-coii-r
  batch-rmessage
  batch-sim-three
  batch-sim-prior
  batch-sim-posterior
  scp -q output/cornell5/* cac:run/mauve/101011
  scp -q species/cornell5 cac:run/mauve/101011
  scp -q data/$SIM1INBLOCK cac:run/mauve/101011
  scp -q data/$SIM1TREE cac:run/mauve/101011
}

function batch-variable {
  OUTPUTDIR=$MAUVEANALYSISDIR/output
  BASEDIR=$OUTPUTDIR/$SPECIES
  BASERUNANALYSIS=$BASEDIR/run-analysis
  NUMBERDIR=$BASEDIR/$REPETITION
  DATADIR=$NUMBERDIR/data
  RUNMAUVE=$NUMBERDIR/run-mauve
  RUNCLONALFRAME=$NUMBERDIR/run-clonalframe
  RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
  RUNANALYSIS=$NUMBERDIR/run-analysis

  SPECIESFILE=species/$SPECIES
  ROUTPUTDIR=/v4scratch/sc2265/mauve/output
  RBASEDIR=$ROUTPUTDIR/$SPECIES
  RNUMBERDIR=$ROUTPUTDIR/$SPECIES/$REPETITION
  RANALYSISDIR=$RNUMBERDIR/run-analysis
  RDATADIR=$RNUMBERDIR/data
  RMAUVEDIR=$RNUMBERDIR/run-mauve
  RCLONALFRAMEDIR=$RNUMBERDIR/run-clonalframe
  RCLONALORIGINDIR=$RNUMBERDIR/run-clonalorigin
}

function batch-rmessage {
  echo "Create cac:$RDATADIR"
  echo "Copy $BASEDIR/data cac:$RDATADIR"
  echo "Copy $BASEDIR/*sh a directory of a cluster, e.g., run/mauve/101011"
  echo "e.g., scp $BASEDIR/data/* cac:$RDATADIR"
  echo "e.g., scp output/$SPECIES/* cac:run/mauve/101011"
  echo "e.g., scp species/$SPECIES cac:run/mauve/101011"
  echo "bash run.sh at cac:run/mauve/101011"
}

function batch-copy-genome {
  read-species-genbank-files data/$SPECIES $FUNCNAME
  cp $FNA $BASEDIR/data
  cp $GFF $BASEDIR/data
}

function batch-speciesfile {
  MAUVEWALLTIME=$(grep ^MAUVEWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  LCBWALLTIME=$(grep ^LCBWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  WATTERSONWALLTIME=$(grep ^WATTERSONWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  CFWALLTIME=$(grep ^CFWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  COIWALLTIME=$(grep ^COIWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  COIIWALLTIME=$(grep ^COIIWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  AOIWALLTIME=$(grep ^AOIWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  AOIIWALLTIME=$(grep ^AOIIWALLTIME\: $SPECIESFILE | cut -d":" -f2)
  SCO1WALLTIME=$(grep ^SCO1WALLTIME\: $SPECIESFILE | cut -d":" -f2)
  SIM1WALLTIME=$(grep ^SIM1WALLTIME\: $SPECIESFILE | cut -d":" -f2)
  SIM2WALLTIME=$(grep ^SIM2WALLTIME\: $SPECIESFILE | cut -d":" -f2)
  SIM3WALLTIME=$(grep ^SIM3WALLTIME\: $SPECIESFILE | cut -d":" -f2)
  LCBMINLEN=$(grep ^LCBMINLEN\: $SPECIESFILE | cut -d":" -f2)
  NUMBERSPECIES=$(grep ^NUMBERSPECIES\: $SPECIESFILE | cut -d":" -f2)
  COIHOWMANYNODE=$(grep ^COIHOWMANYNODE\: $SPECIESFILE | cut -d":" -f2)
  COIIHOWMANYNODE=$(grep ^COIHOWMANYNODE\: $SPECIESFILE | cut -d":" -f2)
  COIREPLICATE=$(grep ^COIREPLICATE\: $SPECIESFILE | cut -d":" -f2)
  COIIREPLICATE=$(grep ^COIIREPLICATE\: $SPECIESFILE | cut -d":" -f2)
  COIPLOTXLAB=$(grep ^COIPLOTXLAB\: $SPECIESFILE | cut -d":" -f2)
  COIBURNIN=$(grep ^COIBURNIN\: $SPECIESFILE | cut -d":" -f2)
  COICHAINLENGTH=$(grep ^COICHAINLENGTH\: $SPECIESFILE | cut -d":" -f2)
  COITHIN=$(grep ^COITHIN\: $SPECIESFILE | cut -d":" -f2)
  COIIBURNIN=$(grep ^COIIBURNIN\: $SPECIESFILE | cut -d":" -f2)
  COIICHAINLENGTH=$(grep ^COIICHAINLENGTH\: $SPECIESFILE | cut -d":" -f2)
  COIITHIN=$(grep ^COIITHIN\: $SPECIESFILE | cut -d":" -f2)
  CFBURNIN=$(grep ^CFBURNIN\: $SPECIESFILE | cut -d":" -f2)
  CFCHAINLENGTH=$(grep ^CFCHAINLENGTH\: $SPECIESFILE | cut -d":" -f2)
  CFTHIN=$(grep ^CFTHIN\: $SPECIESFILE | cut -d":" -f2)
  REFGENOME=$(grep ^REFGENOME\: $SPECIESFILE | cut -d":" -f2)
  GFF=$(grep ^GFF\: $SPECIESFILE | cut -d":" -f2)
  FNA=$(grep ^FNA\: $SPECIESFILE | cut -d":" -f2)
  GBK=$(grep ^GBK\: $SPECIESFILE | cut -d":" -f2)
  TREETOPOLOGY=$(grep ^TREETOPOLOGY\: $SPECIESFILE | cut -d":" -f2)
  REFGENOMELENGTH=$(grep ^REFGENOMELENGTH\: $SPECIESFILE | cut -d":" -f2)

  # For simulation 1
  SIM1REPETITION=$(grep ^SIM1REPETITION\: $SPECIESFILE | cut -d":" -f2)
  SIM1REPLICATE=$(grep ^SIM1REPLICATE\: $SPECIESFILE | cut -d":" -f2)
  SIM1THETA=$(grep ^SIM1THETA\: $SPECIESFILE | cut -d":" -f2)
  SIM1RHO=$(grep ^SIM1RHO\: $SPECIESFILE | cut -d":" -f2)
  SIM1DELTA=$(grep ^SIM1DELTA\: $SPECIESFILE | cut -d":" -f2)
  SIM1INBLOCK=$(grep ^SIM1INBLOCK\: $SPECIESFILE | cut -d":" -f2)
  SIM1TREE=$(grep ^SIM1TREE\: $SPECIESFILE | cut -d":" -f2)
  SIM1BURNIN=$(grep ^SIM1BURNIN\: $SPECIESFILE | cut -d":" -f2)
  SIM1CHAINLENGTH=$(grep ^SIM1CHAINLENGTH\: $SPECIESFILE | cut -d":" -f2)
  SIM1THIN=$(grep ^SIM1THIN\: $SPECIESFILE | cut -d":" -f2)
}

function batch-output {
  mkdir -p $BASERUNANALYSIS
  mkdir -p $DATADIR
  mkdir -p $RUNMAUVE
  mkdir -p $RUNCLONALFRAME
  mkdir -p $RUNCLONALORIGIN
  mkdir -p $RUNANALYSIS
  mkdir -p $BASEDIR/data
}

function batch-run {
cat>$BASEDIR/run.sh<<EOF
#!/bin/bash
STATUS=mauve
nsub run-\$STATUS.sh
while [ 1 ] 
do
  if [ "\$STATUS" == "mauve" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-Mauve | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=lcb
      nsub run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  

  if [ "\$STATUS" == "lcb" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-LCB | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=watterson
      nsub run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  

  if [ "\$STATUS" == "watterson" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-Watterson | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=clonalframe
      nsub run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  

  if [ "\$STATUS" == "clonalframe" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-CF | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=coi
      bash run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi

  if [ "\$STATUS" == "coi" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-COI | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=aoi
      nsub run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  
  
  if [ "\$STATUS" == "aoi" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-AOI | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=coii
      bash run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  

  if [ "\$STATUS" == "coii" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-COII | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=aoii
      nsub run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  
 
  if [ "\$STATUS" == "aoii" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-AOII | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=summary-coii
      nsub run-\$STATUS.sh
    else
      echo "Wait for the job to be finished"
    fi  
  fi  

  if [ "\$STATUS" == "summary-coii" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-SCO1 | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=exit
      # nsub run-\$STATUS.sh
    fi  
  fi  

  if [ "\$STATUS" == "sim-three" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-SIM1 | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=sim-prior
      nsub run-\$STATUS.sh
    fi  
  fi  
  if [ "\$STATUS" == "sim-prior" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-SIM2 | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=sim-posterior
      nsub run-\$STATUS.sh
    fi  
  fi  
  if [ "\$STATUS" == "sim-posterior" ]; then
    NJOBS=\$(qstat | grep $PROJECTNAME-SIM3 | wc -l) 
    if [ \$NJOBS -eq 0 ]; then
      STATUS=exit
      #nsub run-\$STATUS.sh
    fi  
  fi  

  if [ "\$STATUS" == "exit" ]; then
    break
  fi

  sleep 60
done
EOF
}

function batch-mauve {
cat>$BASEDIR/run-mauve.sh<<EOF
#!/bin/bash
#PBS -l walltime=${MAUVEWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-Mauve
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

MAUVE=\$HOME/${BATCHPROGRESSIVEMAUVE}
BASEDIR=output/$SPECIES/$REPETITION
MAUVEDIR=\$BASEDIR/run-mauve
DATADIR=\$BASEDIR/data

mkdir -p $RMAUVEDIR
OUTPUTDIR=output/$SPECIES/$REPETITION/run-mauve/output
cd \$TMPDIR
mkdir -p \$OUTPUTDIR
cp \$MAUVE .
cp -r $RDATADIR \$BASEDIR
./progressiveMauve --output=\$OUTPUTDIR/full_alignment.xmfa \\
  --output-guide-tree=\$OUTPUTDIR/guide.tree \\
EOF

  read-species-genbank-files data/$SPECIES $FUNCNAME

cat>>$BASEDIR/run-mauve.sh<<EOF
cp -r \$OUTPUTDIR $RMAUVEDIR
cd
rm -rf \$TMPDIR
EOF
}

function batch-lcb {
cat>$BASEDIR/run-lcb.sh<<EOF
#!/bin/bash
#PBS -l walltime=${LCBWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-LCB
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

LCB=\$HOME/$BATCHLCB
BASEDIR=output/$SPECIES/$REPETITION
MAUVEDIR=\$BASEDIR/run-mauve
DATADIR=\$BASEDIR/data

cd \$TMPDIR
mkdir -p \$BASEDIR
cp \$LCB .
cp -r $RMAUVEDIR \$BASEDIR
cp -r $RDATADIR \$BASEDIR

./stripSubsetLCBs \$MAUVEDIR/output/full_alignment.xmfa \
  \$MAUVEDIR/output/full_alignment.xmfa.bbcols \
  \$DATADIR/core_alignment.xmfa.org $LCBMINLEN

cp \$DATADIR/core_alignment.xmfa.org $RDATADIR
cd
rm -rf \$TMPDIR
EOF
}

function batch-watterson {
cat>$BASEDIR/run-watterson.sh<<EOF
#!/bin/bash
#PBS -l walltime=${WATTERSONWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-Watterson
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

BASEDIR=output/$SPECIES/$REPETITION
MAUVEDIR=\$BASEDIR/run-mauve
DATADIR=\$BASEDIR/data
ANALYSISDIR=\$BASEDIR/run-analysis

cd \$TMPDIR
mkdir -p \$ANALYSISDIR
cp -r $RDATADIR \$BASEDIR
cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .
cp \$HOME/usr/bin/compute_watterson_estimate .
cp \$PBS_O_WORKDIR/run-watterson.R .

function compute-watterson-estimate {
  FILES=\$DATADIR/core_alignment.xmfa.*
  for f in \$FILES
  do
    LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$HOME/usr/lib \\
    ./compute_watterson_estimate \$f
  done
}

function sum-w {
  RUNLOG=\$ANALYSISDIR/run.log

  R --no-save < run-watterson.R > sum-w.txt
  WATTERSON_ESIMATE=\$(cat sum-w.txt | grep ^WATTERSON | cut -d ':' -f 2)
  FINITEWATTERSON_ESIMATE=\$(cat sum-w.txt | grep ^FINITEWATTERSON | cut -d ':' -f 2)
  LEGNTH_SEQUENCE=\$(cat sum-w.txt | grep ^LENGTHALIGNMENT | cut -d ':' -f 2)
  NUMBER_BLOCKS=\$(cat sum-w.txt | grep ^NUMBERBLOCK | cut -d ':' -f 2)
  AVERAGELEGNTH_SEQUENCE=\$(cat sum-w.txt | grep ^MEANBLOCKLENGTH | cut -d ':' -f 2)
  PROPORTION_POLYMORPHICSITES=\$(cat sum-w.txt | grep ^PROPORTIONPOLYSITE | cut -d ':' -f 2)
  rm -f \$RUNLOG
  echo -e "WATTERSON:\$WATTERSON_ESIMATE" >> \$RUNLOG
  echo -e "Watterson estimate: \$WATTERSON_ESIMATE" >> \$RUNLOG
  echo -e "Finite-site version of Watterson estimate: \$FINITEWATTERSON_ESIMATE" >> \$RUNLOG
  echo -e "Length of sequences: \$LEGNTH_SEQUENCE" >> \$RUNLOG
  echo -e "Number of blocks: \$NUMBER_BLOCKS" >> \$RUNLOG
  echo -e "Average length of sequences: \$AVERAGELEGNTH_SEQUENCE" >> \$RUNLOG
  echo -e "Proportion of polymorphic sites: \$PROPORTION_POLYMORPHICSITES" >> \$RUNLOG
}

#############
rm -f \$DATADIR/core_alignment.xmfa.*
perl pl/blocksplit2fasta.pl \$DATADIR/core_alignment.xmfa

compute-watterson-estimate > w.txt
# Use R to sum the values in w.txt.
sum-w
cp -r \$ANALYSISDIR $RNUMBERDIR
cp w.txt \$PBS_O_WORKDIR
cp sum-w.txt \$PBS_O_WORKDIR
cd
rm -rf \$TMPDIR
EOF
}

function batch-watterson-r {
cat>$BASEDIR/run-watterson.R<<EOF
x <- read.table ("w.txt")
cat ("NUMBERBLOCK:", length(x\$V1), "\n", sep="")
cat ("LENGTHALIGNMENT:", sum(x\$V3), "\n", sep="")
cat ("MEANBLOCKLENGTH:", sum(x\$V3)/length(x\$V1), "\n", sep="")
cat ("PROPORTIONPOLYSITE:", sum(x\$V2)/sum(x\$V3), "\n", sep="")
cat ("NUMBERSPECIES:$NUMBERSPECIES\n")
cat ("FINITEWATTERSON:", sum (x\$V1), "\n", sep="")
nseg <- sum (x\$V2)
s <- 0
n <- $NUMBERSPECIES - 1
for (i in 1:n)
{
  s <- s + 1/i
}
cat ("WATTERSON:", nseg/s, "\n", sep="")
EOF
}

function batch-clonalframe {
cat>$BASEDIR/run-clonalframe.sh<<EOF
#!/bin/bash
#PBS -l walltime=${CFWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-CF
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

CLONALFRAME=\$HOME/${BATCHCLONALFRAME}
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

cd \$TMPDIR
mkdir -p \$BASEDIR
mkdir -p \$CLONALFRAMEDIR/output
cp \$CLONALFRAME .
cp -r $RMAUVEDIR \$NUMBERDIR
cp -r $RDATADIR \$NUMBERDIR
cp -r $RANALYSISDIR \$NUMBERDIR

WATTERSON_ESIMATE=\$(cat \$ANALYSISDIR/run.log | grep WATTERSON | cut -d ':' -f 2)

x=( $CFBURNIN $CFBURNIN $CFBURNIN $CFBURNIN $CFBURNIN $CFBURNIN $CFBURNIN $CFBURNIN )
y=( $CFCHAINLENGTH $CFCHAINLENGTH $CFCHAINLENGTH $CFCHAINLENGTH $CFCHAINLENGTH $CFCHAINLENGTH $CFCHAINLENGTH $CFCHAINLENGTH )
z=( $CFTHIN $CFTHIN $CFTHIN $CFTHIN $CFTHIN $CFTHIN $CFTHIN $CFTHIN )

for index in 0 1 2 3 4 5 6 7
do
  LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \\
  ./ClonalFrame -x \${x[\$index]} -y \${y[\$index]} -z \${z[\$index]} \\
    -t 2 -m \$WATTERSON_ESIMATE -M \\
    \$DATADIR/core_alignment.xmfa \\
    \$CLONALFRAMEDIR/output/core_clonalframe.out.\$index \\
    > \$CLONALFRAMEDIR/output/cf_stdout.\$index &
  sleep 5
done

wait
cp -r \$CLONALFRAMEDIR $RNUMBERDIR
cd
rm -rf \$TMPDIR
EOF
}

function batch-run-coi {

cat>$BASEDIR/run-coi.sh<<EOF
#!/bin/bash
function trim() { echo \$1; }
NUMBER_BLOCK=\$(trim \$(echo \`ls $RDATADIR/core_alignment.xmfa.*|wc -l\`))
JOBIDFILE=coi.jobidfile
rm -f \$JOBIDFILE
for b in \$(eval echo {1..\$NUMBER_BLOCK}); do
  for g in \$(eval echo {1..$COIREPLICATE}); do
    TREE=output/$SPECIES/$REPETITION/run-clonalorigin/clonaltree.nwk
    XMFA=output/$SPECIES/$REPETITION/data/core_alignment.xmfa.\$b
    XML=output/$SPECIES/$REPETITION/run-clonalorigin/output/\$g/core_co.phase2.xml.\$b
    echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
      -x $COIBURNIN -y $COICHAINLENGTH -z $COITHIN \
      \$TREE \$XMFA \$XML >> \$JOBIDFILE
  done
done

sed s/PBSARRAYSIZE/$COIHOWMANYNODE/g < batch-coi.sh > tbatch.sh
nsub tbatch.sh 
rm tbatch.sh
EOF

cat>$BASEDIR/batch-coi.sh<<EOF
#!/bin/bash
#PBS -l walltime=${COIWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-COI
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# The full path of the clonal origin executable.
WARG=\$HOME/usr/bin/warg
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

for g in \$(eval echo {1..$COIREPLICATE}); do
  mkdir -p $RCLONALORIGINDIR/output/\$g
done

function copy-data {
  cd \$TMPDIR
  cp \$WARG .
  cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .
  cp \$PBS_O_WORKDIR/batchjob.sh .
  mkdir -p \$NUMBERDIR
  cp -r $RDATADIR \$NUMBERDIR
  cp -r $RANALYSISDIR \$NUMBERDIR
  cp -r $RCLONALFRAMEDIR \$NUMBERDIR
  for g in \$(eval echo {1..$COIREPLICATE}); do
    mkdir -p \$CLONALORIGINDIR/output/\$g
  done

  mkdir -p \$CLONALORIGINDIR
  perl pl/getClonalTree.pl \
    \$CLONALFRAMEDIR/output/core_clonalframe.out.0 \
    \$CLONALORIGINDIR/clonaltree.nwk
}

function retrieve-data {
  for g in \$(eval echo {1..$COIREPLICATE}); do
    cp \$CLONALORIGINDIR/output/\$g/* $RCLONALORIGINDIR/output/\$g
  done
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batchjob.sh \\
      \$i \\
      \$PBS_O_WORKDIR/coi.jobidfile \\
      \$PBS_O_WORKDIR/coi.lockfile&
  done
}

copy-data
process-data; wait
retrieve-data
EOF

cat>$BASEDIR/batchjob.sh<<EOF
#!/bin/bash
PMI_RANK=\$1
JOBIDFILE=\$2
LOCKFILE=\$3
WHICHLINE=1
JOBID=0
cd \$TMPDIR

# Read the filelock
while [ "\$JOBID" != "" ]
do

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
      \$JOBID
    fi
  else
    echo "Failed to acquire lockfile: \$lockfile." 
    echo "Held by \$(cat )"
    sleep 5
    echo "Retry to access \$lockfile"
  fi
done
EOF
}

function batch-analyze-coi {
cat>$BASEDIR/run-aoi.sh<<EOF
#!/bin/bash
#PBS -l walltime=${AOIWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-AOI
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

WARG=\$HOME/${BATCHWARG}
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

cd \$TMPDIR
mkdir -p \$NUMBERDIR
cp \$PBS_O_WORKDIR/analyze-coi.R .
cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .
cp -r $RCLONALORIGINDIR \$NUMBERDIR
cp -r $RDATADIR \$NUMBERDIR
cp -r $RANALYSISDIR \$NUMBERDIR

for g in \$(eval echo {1..$COIREPLICATE}); do
  mkdir -p \$CLONALORIGINDIR/summary/\$g

  UNFINISHED=\$CLONALORIGINDIR/summary/\$g/unfinished
  perl pl/report-clonalorigin-job.pl \\
    -xmlbase \$CLONALORIGINDIR/output/\$g/core_co.phase2.xml \\
    -database \$DATADIR/core_alignment.xmfa \\
    > \$UNFINISHED

  MEDIAN=\$CLONALORIGINDIR/summary/\$g/median.txt
  perl pl/computeMedians.pl \\
    \$CLONALORIGINDIR/output/\$g/core_co.phase2.xml.* \\
    | grep ^Median > \$MEDIAN

  MEDIAN_THETA=\$(grep "Median theta" \$MEDIAN | cut -d ":" -f 2)
  MEDIAN_DELTA=\$(grep "Median delta" \$MEDIAN | cut -d ":" -f 2)
  MEDIAN_RHO=\$(grep "Median rho" \$MEDIAN | cut -d ":" -f 2)

  perl pl/scatter-plot-parameter.pl three \\
    -xmlbase \$CLONALORIGINDIR/output/\$g/core_co.phase2 \\
    -xmfabase \$DATADIR/core_alignment.xmfa \\
    -out \$ANALYSISDIR/scatter-plot-parameter-\$g-out
  cp \$ANALYSISDIR/scatter-plot-parameter-\$g-out-theta S2OUT-theta
  cp \$ANALYSISDIR/scatter-plot-parameter-\$g-out-delta S2OUT-delta
  cp \$ANALYSISDIR/scatter-plot-parameter-\$g-out-rho S2OUT-rho

  sed "s/MEDIAN_THETA/\$MEDIAN_THETA/" < analyze-coi.R > 1.R
  sed "s/MEDIAN_DELTA/\$MEDIAN_DELTA/" < 1.R > 2.R
  sed "s/MEDIAN_RHO/\$MEDIAN_RHO/" < 2.R > \$ANALYSISDIR/analyze-coi-\$g.R

  Rscript \$ANALYSISDIR/analyze-coi-\$g.R > \$ANALYSISDIR/analyze-coi-\$g.R.out 
  mv S2OUT-theta.ps \$ANALYSISDIR/analyze-coi-\$g-theta.ps
  mv S2OUT-delta.ps \$ANALYSISDIR/analyze-coi-\$g-delta.ps
  mv S2OUT-rho.ps \$ANALYSISDIR/analyze-coi-\$g-rho.ps
done
cp -r \$CLONALORIGINDIR/summary $RCLONALORIGINDIR
cp \$ANALYSISDIR/*.R* $RANALYSISDIR
cp \$ANALYSISDIR/*.ps $RANALYSISDIR
cd
rm -rf \$TMPDIR
EOF
}

function batch-analyze-coi-r {
cat>$BASEDIR/analyze-coi.R<<EOF
library("geneplotter")  ## from BioConductor
require("RColorBrewer") ## from CRAN

plotThreeParameter <- function (f, xlab, ylab, m, logscale) {
  x.filename <- paste (f, ".ps", sep="")
  x <- read.table (f);

  pos.median <- c() 
  pos <- unique (x\$V1)
  for (i in pos)
  {
    pos.median <- c(pos.median, median(x\$V2[x\$V1 == i]))
  }

  postscript (file=x.filename, width=10, height=5, horizontal = FALSE, onefile = FALSE, paper = "special")
  if (logscale == TRUE) {
    smoothScatter(x\$V1, log(x\$V2), nrpoints=0, colramp = colorRampPalette(c("white", "black")), xlab=xlab, ylab=ylab)
    points (pos, log(pos.median), pch=43)
    abline (h=log(m), col="red", lty="dashed")
  } else {
    smoothScatter(x\$V1, x\$V2, nrpoints=0, colramp = colorRampPalette(c("white", "black")), xlab=xlab, ylab=ylab)
    points (pos, pos.median, pch=43)
    abline (h=m, col="red", lty="dashed")
  }
  dev.off()
}
plotThreeParameter ("S2OUT-theta", $COIPLOTXLAB, "Mutation rate per site", MEDIAN_THETA, FALSE)
plotThreeParameter ("S2OUT-rho", $COIPLOTXLAB, "Recombination rate per site", MEDIAN_RHO, FALSE)
plotThreeParameter ("S2OUT-delta", $COIPLOTXLAB, "Log average tract length", MEDIAN_DELTA, TRUE)
EOF
}

function batch-run-coii {
cat>$BASEDIR/run-coii.sh<<EOF
#!/bin/bash
function trim() { echo \$1; }
NUMBER_BLOCK=\$(trim \$(echo \`ls $RDATADIR/core_alignment.xmfa.*|wc -l\`))

MEDIAN=$RCLONALORIGINDIR/summary/1/median.txt
THETA_PER_SITE=\$(grep "Median theta" \$MEDIAN | cut -d ":" -f 2)
DELTA=\$(grep "Median delta" \$MEDIAN | cut -d ":" -f 2)
RHO_PER_SITE=\$(grep "Median rho" \$MEDIAN | cut -d ":" -f 2)

JOBIDFILE=coii.jobidfile
rm -f \$JOBIDFILE
for b in \$(eval echo {1..\$NUMBER_BLOCK}); do
  for g in \$(eval echo {1..$COIIREPLICATE}); do
    TREE=output/$SPECIES/$REPETITION/run-clonalorigin/clonaltree.nwk
    XMFA=output/$SPECIES/$REPETITION/data/core_alignment.xmfa.\$b
    XML=output/$SPECIES/$REPETITION/run-clonalorigin/output2/\$g/core_co.phase3.xml.\$b
    echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
      -x $COIBURNIN -y $COICHAINLENGTH -z $COITHIN \
      -T s\$THETA_PER_SITE -D \$DELTA -R s\$RHO_PER_SITE \
      \$TREE \$XMFA \$XML >> \$JOBIDFILE
  done
done

sed s/PBSARRAYSIZE/$COIIHOWMANYNODE/g < batch-coii.sh > tbatch.sh
nsub tbatch.sh 
rm tbatch.sh
EOF

cat>$BASEDIR/batch-coii.sh<<EOF
#!/bin/bash
#PBS -l walltime=${COIIWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-COII
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# The full path of the clonal origin executable.
WARG=\$HOME/usr/bin/warg
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

for g in \$(eval echo {1..$COIREPLICATE}); do
  mkdir -p $RCLONALORIGINDIR/output2/\$g
done

function copy-data {
  cd \$TMPDIR
  cp \$WARG .
  cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .
  cp \$PBS_O_WORKDIR/batchjob.sh .
  mkdir -p \$NUMBERDIR
  cp -r $RDATADIR \$NUMBERDIR
  cp -r $RANALYSISDIR \$NUMBERDIR
  cp -r $RCLONALFRAMEDIR \$NUMBERDIR
  cp -r $RCLONALORIGINDIR \$NUMBERDIR
  for g in \$(eval echo {1..$COIIREPLICATE}); do
    mkdir -p \$CLONALORIGINDIR/output2/\$g
  done

  mkdir -p \$CLONALORIGINDIR
  perl pl/getClonalTree.pl \
    \$CLONALFRAMEDIR/output/core_clonalframe.out.0 \
    \$CLONALORIGINDIR/clonaltree.nwk
}

function retrieve-data {
  for g in \$(eval echo {1..$COIREPLICATE}); do
    cp \$CLONALORIGINDIR/output2/\$g/* $RCLONALORIGINDIR/output2/\$g
  done
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batchjob.sh \\
      \$i \\
      \$PBS_O_WORKDIR/coii.jobidfile \\
      \$PBS_O_WORKDIR/coii.lockfile&
  done
}

copy-data
process-data; wait
retrieve-data
EOF
}

function batch-analyze-coii {
cat>$BASEDIR/run-aoii.sh<<EOF
#!/bin/bash
#PBS -l walltime=${AOIIWALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-ACOII
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

WARGGUI=\$HOME/${BATCHWARGGUI}
WARG=\$HOME/${BATCHWARG}
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

cd \$TMPDIR
cp \$WARGGUI .
cp \$PBS_O_WORKDIR/analyze-coii.R .
cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .
mkdir -p \$NUMBERDIR
cp -r $RCLONALORIGINDIR \$NUMBERDIR
cp -r $RANALYSISDIR \$NUMBERDIR
cp -r $RDATADIR \$NUMBERDIR

function trim() { echo \$1; }
NUMBER_BLOCK=\$(trim \$(echo \`ls \$DATADIR/core_alignment.xmfa.*|wc -l\`))
# NUMBER_BLOCK=3 # FIXME: for testing 
for g in \$(eval echo {1..$COIIREPLICATE}); do

  perl pl/count-observed-recedge.pl obsonly \\
    -d \$CLONALORIGINDIR/output2/\$g \\
    -n \$NUMBER_BLOCK \\
    -endblockid \\
    -obsonly \\
    -out \$ANALYSISDIR/obsonly-recedge-\$g.txt

  PRIORCOUNTDIR=\$CLONALORIGINDIR/output2/priorcount-\$g
  mkdir -p \$PRIORCOUNTDIR
  for i in \$(eval echo {1..\$NUMBER_BLOCK}); do
    if [ -f "\$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml.\$i" ]; then
      ./gui \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml.\$i \\
        > \$PRIORCOUNTDIR/\$i.txt
    fi
  done 
  cp -r \$PRIORCOUNTDIR $RCLONALORIGINDIR/output2

  perl pl/count-observed-recedge.pl heatmap \\
    -d \$CLONALORIGINDIR/output2/\$g \\
    -e \$PRIORCOUNTDIR \\
    -endblockid \\
    -n \$NUMBER_BLOCK \\
    -out \$ANALYSISDIR/heatmap-recedge-\$g.txt

  # Run the R script for a heat map.
  cp \$ANALYSISDIR/heatmap-recedge-\$g.txt COIIINTXT
  cp \$ANALYSISDIR/obsonly-recedge-\$g.txt COIIINOBSONLYTXT
  Rscript analyze-coii.R > \$ANALYSISDIR/analyze-coii-\$g.R.out 
  cp analyze-coii.R \$ANALYSISDIR/analyze-coii-\$g.R.out 
  mv COIIOUTPS \$ANALYSISDIR\/heatmap-recedge-\$g.ps

done
cp \$ANALYSISDIR/*.R* $RANALYSISDIR
cp \$ANALYSISDIR/obsonly*txt $RANALYSISDIR
cp \$ANALYSISDIR/heatmap* $RANALYSISDIR
cd
rm -rf \$TMPDIR
EOF
}

function batch-analyze-coii-r {
cat>$BASEDIR/analyze-coii.R<<EOF
numberBranch <- $NUMBERSPECIES * 2 - 1
numberElement <- numberBranch * numberBranch 
A <- matrix(scan("COIIINTXT", n=numberElement), numberBranch, numberBranch, byrow = TRUE)
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    if (A[i,j] == 0)
    {
      A[i,j] <- NA
    }
    else
    {
      A[i,j] <- log2(A[i,j])
    }
  }
}

B <- A
indexReorder <- c(0,5,1,7,2,8,3,6,4) + 1
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    A[i,j] <- B[indexReorder[i],indexReorder[j]]
  }
}

library(colorspace)
library(gplots)

Aname <- c("SDE1", "SDE", "SDE2", "SD", "SDD", "ROOT", "SPY1", "SPY", "SPY2")

# b<-seq(-max(abs(A))-0.1,max(abs(A))+0.1,length.out=42)
b<-seq(-2.2,2.2,length.out=42)
#pdf("heatmap.pdf", height=10, width=10)
postscript("COIIOUTPS", width=10, height=10, horizontal = FALSE, onefile = FALSE, paper = "special")


heatmap.2(A,
  Rowv=FALSE,
  Colv=FALSE,
  dendrogram= c("none"),
  distfun = dist,
  hclustfun = hclust,
  xlab = "", ylab = "",
  key=TRUE,
  keysize=1,
  trace="none",
  density.info=c("none"),
  margins=c(10, 8),
  breaks=b,
  col=diverge_hcl(41),
  na.color="green",
  labRow=Aname,
  labCol=Aname
)
dev.off()

print (A, digits=2, width=100)

A <- matrix(scan("COIIINOBSONLYTXT", n=numberElement), numberBranch, numberBranch, byrow = TRUE)
B <- A
indexReorder <- c(0,5,1,7,2,8,3,6,4) + 1
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    A[i,j] <- B[indexReorder[i],indexReorder[j]]
  }
}
print (A, digits=4, width=100)
EOF
}


function batch-summary-coii {
cat>$BASEDIR/run-summary-coii.sh<<EOF
#!/bin/bash
#PBS -l walltime=${SCO1WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-SCO1
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

WARGGUI=\$HOME/${BATCHWARGGUI}
WARG=\$HOME/${BATCHWARG}
WARGSIM=\$HOME/${BATCHWARGSIM}
XMFA2MAF=\$HOME/${BATCHXMFA2MAF}
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

cd \$TMPDIR
cp \$PBS_O_WORKDIR/summary-coii.R .
cp \$XMFA2MAF .
cp \$WARGSIM .
cp \$WARGGUI .
cp \$PBS_O_WORKDIR/$SPECIES .
cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .
mkdir -p \$NUMBERDIR
cp -r $RCLONALORIGINDIR \$NUMBERDIR
cp -r $RANALYSISDIR \$NUMBERDIR
cp -r $RDATADIR \$NUMBERDIR

# Convert XMFA to MAF.
./xmfa2maf \$DATADIR/core_alignment.xmfa \$DATADIR/core_alignment.maf

function trim() { echo \$1; }
NUMBER_BLOCK=\$(trim \$(echo \`ls \$DATADIR/core_alignment.xmfa.*|wc -l\`))
NUMBER_SAMPLE=\$(trim \$(echo \`grep number \$CLONALORIGINDIR/output2/1/core_co.phase3.xml.1|wc -l\`))
NUMBER_BLOCK=3 # FIXME: debug
for g in \$(eval echo {1..$COIIREPLICATE}); do
  # Create a recombination intensity map.
  RIMAP=\$ANALYSISDIR/rimap-\$g.txt
  perl pl/recombination-intensity1-map.pl \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -numberblock \$NUMBER_BLOCK \\
    -verbose \\
    -out \$RIMAP

  # I. Posterior probability of recombination
  # Create wiggle files from the recombination intensity map.
  # (All of the) Five reference genomes.
  mkdir -p \$ANALYSISDIR/rimap-\$g
  perl pl/recombination-intensity1-probability.pl split \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
    -outdir \$ANALYSISDIR/rimap-\$g

  for h in \$(eval echo {1..$NUMBERSPECIES}); do
    GBKFILE=\$(grep ^GBK\$h\\: $SPECIES | cut -d":" -f2)
    GBKFILENAME=\`basename \$GBKFILE\`
    perl pl/recombination-intensity1-probability.pl wiggle \\
      -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
      -xmfa2maf \$DATADIR/core_alignment.maf \\
      -xmfa \$DATADIR/core_alignment.xmfa \\
      -refgenome \$h \\
      -gbk \$DATADIR/\$GBKFILENAME \\
      -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
      -rimapdir \$ANALYSISDIR/rimap-\$g \\
      -clonaloriginsamplesize \$NUMBER_SAMPLE \\
      -out \$ANALYSISDIR/recombprob-ref\$h-rep\$g
  done

  GFFFILENAME=\`basename $GFF\`
  perl pl/convert-gff-ingene.pl \\
    -gff \$DATADIR/\$GFFFILENAME \\
    -out \$ANALYSISDIR/in.gene

  FNAFILENAME=\`basename $FNA\`
  perl pl/locate-gene-in-block.pl \\
    locate \\
    -fna \$DATADIR/\$FNAFILENAME \\
    -ingene \$ANALYSISDIR/in.gene \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -printseq \\
    -out \$ANALYSISDIR/in.gene.$REFGENOME.block

  # II. Recombination intensity for functional category association
  # Create recombination intensities for genes.
  RIMAPGENE=\$ANALYSISDIR/rimap-\$g.gene
  perl pl/recombination-intensity1-genes.pl \\
    rimap \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
    -ingene \$ANALYSISDIR/in.gene.$REFGENOME.block \\
    -clonaloriginsamplesize \$NUMBER_SAMPLE \\
    -out \$RIMAPGENE.all&
  perl pl/recombination-intensity1-genes.pl \\
    rimap \\
    -pairm topology \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
    -ingene \$ANALYSISDIR/in.gene.$REFGENOME.block \\
    -clonaloriginsamplesize \$NUMBER_SAMPLE \\
    -out \$RIMAPGENE.topology&
  perl pl/recombination-intensity1-genes.pl \\
    rimap \\
    -pairm notopology \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
    -ingene \$ANALYSISDIR/in.gene.$REFGENOME.block \\
    -clonaloriginsamplesize \$NUMBER_SAMPLE \\
    -out \$RIMAPGENE.notopology&
  perl pl/recombination-intensity1-genes.pl \\
    rimap \\
    -pairm pair \\
    -pairs 0,3:0,4:1,3:1,4 \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
    -ingene \$ANALYSISDIR/in.gene.$REFGENOME.block \\
    -clonaloriginsamplesize \$NUMBER_SAMPLE \\
    -out \$RIMAPGENE.sde2spy&
  perl pl/recombination-intensity1-genes.pl \\
    rimap \\
    -pairm pair \\
    -pairs 3,0:4,0:3,1:4,1 \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -ri1map \$ANALYSISDIR/rimap-\$g.txt \\
    -ingene \$ANALYSISDIR/in.gene.$REFGENOME.block \\
    -clonaloriginsamplesize \$NUMBER_SAMPLE \\
    -out \$RIMAPGENE.spy2sde&
  wait

  #####################################################
  # Make sure which rimap is used.
  # III. List of genes with high probability of recombination
  perl pl/recombination-intensity1-map.pl \\
    -xml \$CLONALORIGINDIR/output2/\$g/core_co.phase3.xml \\
    -xmfa \$DATADIR/core_alignment.xmfa \\
    -refgenome $REFGENOME \\
    -refgenomelength $REFGENOMELENGTH \\
    -numberblock \$NUMBER_BLOCK \\
    -verbose \\
    -out \$ANALYSISDIR/ri1-refgenome$REFGENOME-map-\$g.txt

  # This uses ri1-refgenome$REFGENOME-map.txt
  GBKFILENAME=\`basename $GBK\`
  perl pl/probability-recedge-gene.pl \\
    -ri1map \$ANALYSISDIR/ri1-refgenome$REFGENOME-map-\$g.txt \\
    -clonaloriginsamplesize \$NUMBER_SAMPLE \\
    -genbank \$DATADIR/\$GBKFILENAME \\
    -out \$ANALYSISDIR/probability-recedge-gene-\$g.txt

  ##########################################################
  # IV. Count gene tree topologies.
  # Tree topology
  # 1. split XML file.
  mkdir -p \$CLONALORIGINDIR/output2/ri-\$g
  perl pl/splitCOXMLPerIteration.pl \\
    -d \$CLONALORIGINDIR/output2/\$g \\
    -outdir \$CLONALORIGINDIR/output2/ri-\$g \\
    -numberblock \$NUMBER_BLOCK \\
    -endblockid
  # 2. Generate local gene trees
  mkdir -p \$CLONALORIGINDIR/output2/ri-\$g-out
  for b in \$(eval echo {1..\$NUMBER_BLOCK}); do
    for s in \$(eval echo {1..\$NUMBER_SAMPLE}); do
      BLOCKSIZE=\$(echo \`perl pl/get-block-length.pl \$CLONALORIGINDIR/output2/ri-\$g/core_co.phase3.xml.\$b.\$s\`) 
      ./wargsim --xml-file \\
        \$CLONALORIGINDIR/output2/ri-\$g/core_co.phase3.xml.\$b.\$s \\
        --gene-tree \\
        --out-file \$CLONALORIGINDIR/output2/ri-\$g-out/core_co.phase3.xml.\$b.\$s \\
        --block-length \$BLOCKSIZE
    done
  done

  # 3. Check local gene trees
  for b in \$(eval echo {1..\$NUMBER_BLOCK}); do
    for s in \$(eval echo {1..\$NUMBER_SAMPLE}); do
      BLOCKSIZE=\$(echo \`perl pl/get-block-length.pl \$CLONALORIGINDIR/output2/ri-\$g/core_co.phase3.xml.\$b.\$s\`) 
      NUM=\$(wc \$CLONALORIGINDIR/output2/ri-\$g-out/core_co.phase3.xml.\$b.\$s|awk {'print \$2'})
      if [ "\$NUM" != "\$BLOCKSIZE" ]; then
        echo "Error in local gene tree: \$b \$s not okay"
      fi
    done
  done
  # 4. Combine local gene trees.
  echo -e "  Combining ri-\$g-out ..." 
  mkdir -p \$CLONALORIGINDIR/output2/ri-\$g-combined
  RIBLOCKFILES="" 
  for b in \$(eval echo {1..\$NUMBER_BLOCK}); do
    RIFILES=""
    RIBLOCKFILE="\$CLONALORIGINDIR/output2/ri-\$g-combined/\$b"
    for s in \$(eval echo {1..\$NUMBER_SAMPLE}); do
      RIFILES="\$RIFILES \$CLONALORIGINDIR/output2/ri-\$g-out/core_co.phase3.xml.\$b.\$s"
    done
    RIBLOCKFILES="\$RIBLOCKFILES \$RIBLOCKFILE"
    cat \$RIFILES > \$RIBLOCKFILE
  done
  # 5. Count local gene trees.
  perl pl/map-tree-topology.pl \\
    -ricombined \$CLONALORIGINDIR/output2/ri-\$g-combined \\
    -ingene \$ANALYSISDIR/in.gene.$REFGENOME.block \\
    -treetopology $TREETOPOLOGY \\
    -verbose \\
    -out \$ANALYSISDIR/in.gene.$REFGENOME.block.map-tree-topology
  # 6. Summarize those counts.
  rm -f \$ANALYSISDIR/ri-\$g-combined.all
  for ricombined in \`ls \$CLONALORIGINDIR/output2/ri-\$g-combined/*\`; do 
    # awk '0 == NR % 100' \$ricombined >> \$ANALYSISDIR/ri-\$g-combined.all
    awk '0 == NR % 1' \$ricombined >> \$ANALYSISDIR/ri-\$g-combined.all
  done
  cp \$ANALYSISDIR/ri-\$g-combined.all S2OUT
  # 7. An R script
  Rscript summary-coii.R > \$ANALYSISDIR/summary-coii-\$g.R.out
done
cp \$ANALYSISDIR/in.gene* $RANALYSISDIR
cp \$ANALYSISDIR/rimap* $RANALYSISDIR
cp \$ANALYSISDIR/recombprob-ref* $RANALYSISDIR
cp \$ANALYSISDIR/in.gene* $RANALYSISDIR
cp \$ANALYSISDIR/ri1-refgenome* $RANALYSISDIR
cp \$ANALYSISDIR/probability-recedge-gene*.txt $RANALYSISDIR
cp \$ANALYSISDIR/summary-coii*  $RANALYSISDIR
for g in \$(eval echo {1..$COIIREPLICATE}); do
  cp -r \$ANALYSISDIR/rimap-\$g $RANALYSISDIR
  cp -r \$CLONALORIGINDIR/output2/ri-\$g $RCLONALORIGINDIR/output2
  cp -r \$CLONALORIGINDIR/output2/ri-\$g-out $RCLONALORIGINDIR/output2
  cp -r \$CLONALORIGINDIR/output2/ri-\$g-combined $RCLONALORIGINDIR/output2
  cp \$ANALYSISDIR/ri-\$g-combined.all $RANALYSISDIR
done

cd
rm -rf \$TMPDIR
EOF
}

function batch-summary-coii-r {
cat>$BASEDIR/summary-coii.R<<EOF
x <- scan ("S2OUT")
y <- unlist(lapply(split(x,f=x),length)) 
y.sorted <- sort(y, decreasing=T)
print(y.sorted)
y.sum <- sum(y)
y.sorted[1]/y.sum*100
y.sorted[2]/y.sum*100
y.sorted[3]/y.sum*100
EOF
}

function batch-sim-three {
SPECIES=s1
cat>$BASEDIR/run-sim-three.sh<<EOF
#!/bin/bash
#PBS -l walltime=${SIM1WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-SIM1
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

WARGGUI=\$HOME/${BATCHWARGGUI}
WARG=\$HOME/${BATCHWARG}
WARGSIM=\$HOME/${BATCHWARGSIM}
XMFA2MAF=\$HOME/${BATCHXMFA2MAF}
BASEDIR=output/$SPECIES

NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

cd \$TMPDIR
cp \$PBS_O_WORKDIR/summary-coii.R .
cp \$WARGGUI .
cp \$WARG .
cp \$WARGSIM .
cp \$XMFA2MAF .
cp -r \$PBS_O_WORKDIR/bpp/Mauve-Analysis/pl .

# Need to copy tree and block files.
cp \$PBS_O_WORKDIR/$SIM1INBLOCK .
cp \$PBS_O_WORKDIR/$SIM1TREE .

mkdir -p \$BASEDIR

for g in \$(eval echo {1..$SIM1REPETITION}); do 
  NUMBERDIR=\$BASEDIR/\$g
  DATADIR=\$NUMBERDIR/data
  CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
  mkdir -p \$DATADIR
  mkdir -p \$CLONALORIGINDIR

  # FIND: wargsim must produce a single xmfa at default?
  # wargsim also create an xml file as well?
  # DATADIR/core_alignment.1.xmfa is created.
  # We create one recombinant tree for each repetition.
  # Each recombinant tree we create one data set.
  ./wargsim --tree-file $SIM1TREE \
    --block-file $SIM1INBLOCK \
    --out-file \$DATADIR/core_alignment \
    -T s$SIM1THETA -D $SIM1DELTA -R s$SIM1RHO
  # FIND: extractClonalOriginParameter9 do some count of the generated
  # recombinant tree from wargsim?
  perl pl/extractClonalOriginParameter9.pl \
    -xml \$DATADIR/core_alignment.xml

  for h in \$(eval echo {1..$SIM1REPLICATE}); do
    perl pl/blocksplit.pl \$DATADIR/core_alignment.$h.xmfa
  done

  echo -ne " done - repetition $g/$HOW_MANY_REPETITION\r"
done

EOF
}

function batch-sim-prior {
  echo $FUNCNAME
}

function batch-sim-posterior {
  echo $FUNCNAME
}
