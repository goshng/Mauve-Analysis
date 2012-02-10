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

function prepare-run-clonalframe {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Preparing clonalframe analysis..."
      set-more-global-variable $SPECIES $REPETITION
      WALLTIME=$(grep REPETITION${REPETITION}-CF-WALLTIME species/$SPECIES | cut -d":" -f2)
      echo -e "  Computing Wattersons's estimates..."
      echo -e "  Removing previous blocks..."
      rm -f $DATADIR/core_alignment.xmfa.*
      echo -e "  Splitting core_alignemnt to blocks..."
      perl pl/blocksplit2fasta.pl $DATADIR/core_alignment.xmfa
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
      rm w.txt
      echo "Use the Watterson's estimate in clonalframe analysis."
      send-clonalframe-input-to-cac 
      copy-batch-sh-run-clonalframe
      echo -e "Go to $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalframe"
      echo -e "$ nsub batch.sh"
      break
    fi
  done
}

# FIXME: C source code must be in src
function compute-watterson-estimate {
  FILES=$DATADIR/core_alignment.xmfa.*
  for f in $FILES
  do
    # take action on each file. $f store current file name
    DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
    src/utils/b/compute_watterson_estimate \
    $f
  done
}

function sum-w {
  RUNLOG=$RUNANALYSIS/run.log
  RSCRIPTW=$RUNANALYSIS/w.R
  cat>$RSCRIPTW<<EOF
x <- read.table ("w.txt")
print (paste("Number of blocks:", length(x\$V1)))
print (paste("Length of the alignment:", sum(x\$V3)))
print (paste("Averge length of a block:", sum(x\$V3)/length(x\$V1)))
print (paste("Proportion of polymorphic sites:", sum(x\$V2)/sum(x\$V3)))
print ("Number of Species:$NUMBER_SPECIES")
print (paste("Finite-site version of Watterson's estimate:", sum (x\$V1)))
nseg <- sum (x\$V2)
s <- 0
n <- $NUMBER_SPECIES - 1
for (i in 1:n)
{
  s <- s + 1/i
}
print (paste("Infinite-site version of Watterson's estimate:", nseg/s))
EOF
  R --no-save < $RSCRIPTW > sum-w.txt
  WATTERSON_ESIMATE=$(sed s/\"//g sum-w.txt | grep "\[1\] Infinite-site version of Watterson's estimate:" | cut -d ':' -f 2)
  FINITEWATTERSON_ESIMATE=$(sed s/\"//g sum-w.txt | grep "\[1\] Finite-site version of Watterson's estimate:" | cut -d ':' -f 2)
  LEGNTH_SEQUENCE=$(sed s/\"//g sum-w.txt | grep "\[1\] Length of the alignment:" | cut -d ':' -f 2)
  NUMBER_BLOCKS=$(sed s/\"//g sum-w.txt | grep "\[1\] Number of blocks:" | cut -d ':' -f 2)
  AVERAGELEGNTH_SEQUENCE=$(sed s/\"//g sum-w.txt | grep "\[1\] Averge length of a block:" | cut -d ':' -f 2)
  PROPORTION_POLYMORPHICSITES=$(sed s/\"//g sum-w.txt | grep "\[1\] Proportion of polymorphic sites:" | cut -d ':' -f 2)
  #rm sum-w.txt
  echo -e "Watterson estimate: $WATTERSON_ESIMATE"
  echo -e "Finite-site version of Watterson estimate: $FINITEWATTERSON_ESIMATE"
  echo -e "Length of sequences: $LEGNTH_SEQUENCE"
  echo -e "Number of blocks: $NUMBER_BLOCKS"
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE"
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES"
  rm -f $RUNLOG
  echo -e "Watterson estimate: $WATTERSON_ESIMATE" >> $RUNLOG
  echo -e "Finite-site version of Watterson estimate: $FINITEWATTERSON_ESIMATE" >> $RUNLOG
  echo -e "Length of sequences: $LEGNTH_SEQUENCE" >> $RUNLOG
  echo -e "Number of blocks: $NUMBER_BLOCKS" >> $RUNLOG
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE" >> $RUNLOG
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES" >> $RUNLOG
}

function send-clonalframe-input-to-cac {
  scp -q $DATADIR/core_alignment.xmfa $CAC_USERHOST:$CAC_DATADIR
}

function copy-batch-sh-run-clonalframe {
  cat>$BATCH_SH_RUN_CLONALFRAME<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N ${PROJECTNAME}-${SPECIES}-CF
#PBS -q v4
#PBS -m e
#PBS -M ${BATCHEMAIL}
WORKDIR=\$PBS_O_WORKDIR
DATADIR=\$WORKDIR/../data
CLONALFRAME=\$HOME/${BATCHCLONALFRAME}

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$CLONALFRAME \$TMPDIR/
cp \$DATADIR/* \$INPUTDIR/
cd \$TMPDIR

x=( 10000 10000 10000 10000 10000 10000 10000 10000 )
y=( 10000 10000 10000 10000 10000 10000 10000 10000 )
z=(    10    10    10    10    10    10    10    10 )

for index in 0 1 2 3 4 5 6 7
do
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \\
./ClonalFrame -x \${x[\$index]} -y \${y[\$index]} -z \${z[\$index]} \\
-t 2 -m $WATTERSON_ESIMATE -M \\
\$INPUTDIR/core_alignment.xmfa \\
\$OUTPUTDIR/core_clonalframe.out.\$index \\
> \$OUTPUTDIR/cf_stdout.\$index &
sleep 5
done
date
wait
date
cp -r \$OUTPUTDIR \$WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_CLONALFRAME
  scp $BATCH_SH_RUN_CLONALFRAME $CAC_USERHOST:$CAC_RUNCLONALFRAME
}

