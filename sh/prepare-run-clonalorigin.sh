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

function prepare-run-clonalorigin {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "Which replicate set of ClonalFrame output files? (e.g., 1)"
      set-more-global-variable $SPECIES $REPETITION

      CFID=$(grep ^REPETITION${REPETITION}-CO1-CFID $SPECIESFILE | cut -d":" -f2)
      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO1-NREPLICATE species/$SPECIES | cut -d":" -f2)
      WALLTIME=$(grep ^REPETITION${REPETITION}-CO1-WALLTIME species/$SPECIES | cut -d":" -f2)
      COIBURNIN=$(grep ^REPETITION${REPETITION}-CO1-BURNIN $SPECIESFILE | cut -d":" -f2)
      COICHAINLENGTH=$(grep ^REPETITION${REPETITION}-CO1-CHAINLENGTH $SPECIESFILE | cut -d":" -f2)
      COITHIN=$(grep ^REPETITION${REPETITION}-CO1-THIN $SPECIESFILE | cut -d":" -f2)

      echo "  ClonalFrame REPLICATE ID: $CFREPLICATE"
      echo "  Creating an input directory for a species tree..."
      mkdir -p $RUNCLONALORIGIN/input/${REPLICATE}
      echo "  Creating an output directory for the 1st stage of ClonalOrigin..." 
      mkdir $RUNCLONALORIGIN/output
      echo "  Creating an output directory for the 2nd stage of ClonalOrigin..." 
      mkdir $RUNCLONALORIGIN/output2
      echo "  Creating an input directory in the cluster..."
      CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
      # ssh -x $CAC_USERHOST \
        # mkdir -p $CAC_RUNCLONALORIGIN/input/${REPLICATE}
      echo "  Using $CFID-th clonal frame output"

      echo -e "  Splitting alignment into one file per block..."
      CORE_ALIGNMENT=core_alignment.xmfa
      rm $DATADIR/$CORE_ALIGNMENT.*
      perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT

      echo "  Copying the split alignments..."
      scp -q $DATADIR/$CORE_ALIGNMENT.* \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/data

      echo "  Extracting species tree..."
      SPECIESTREE=clonaltree.nwk
      perl pl/getClonalTree.pl \
        $RUNCLONALFRAME/output/core_clonalframe.out.${CFID} \
        $RUNCLONALORIGIN/$SPECIESTREE
      scp -q $RUNCLONALORIGIN/$SPECIESTREE \
            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin

      # g is REPETITION
      echo "  Creating jobidfile..."
      NUMBER_BLOCK=$(trim $(echo `ls $DATADIR/$CORE_ALIGNMENT.*|wc -l`))
      JOBIDFILE=$RUNCLONALORIGIN/coi.jobidfile
      rm -f $JOBIDFILE
      for h in $(eval echo {1..$NREPLICATE}); do
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          TREE=output/$SPECIES/$REPETITION/run-clonalorigin/clonaltree.nwk
          XMFA=output/$SPECIES/$REPETITION/data/core_alignment.xmfa.$b
          XML=output/$SPECIES/$REPETITION/run-clonalorigin/output/$h/core_co.phase2.xml.$b
          echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
            -x $COIBURNIN -y $COICHAINLENGTH -z $COITHIN \
            $TREE $XMFA $XML >> $JOBIDFILE
        done
      done
      scp -q $JOBIDFILE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -q cac/sim/batch_task2.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/batchjob.sh
      scp -q cac/sim/run2.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/run.sh
      scp -q $RUNCLONALORIGIN/$SPECIESTREE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin

cat>$RUNCLONALORIGIN/batch.sh<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-CO1
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# The full path of the ClonalOrigin executable.
WARG=\$HOME/usr/bin/warg
BASEDIR=output/$SPECIES
NUMBERDIR=\$BASEDIR/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
CLONALFRAMEDIR=\$NUMBERDIR/run-clonalframe
CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
DATADIR=\$NUMBERDIR/data
ANALYSISDIR=\$NUMBERDIR/run-analysis

for g in \$(eval echo {1..$NREPLICATE}); do
  mkdir -p \$PBS_O_WORKDIR/output/\$g
done

function copy-data {
  cd \$TMPDIR
  cp \$WARG .
  cp \$PBS_O_WORKDIR/batchjob.sh .
  mkdir -p \$NUMBERDIR
  cp -r \$PBS_O_WORKDIR/../data \$NUMBERDIR
  cp -r \$PBS_O_WORKDIR/../run-analysis \$NUMBERDIR
  mkdir \$CLONALORIGINDIR
  # Create the status directory.
  mkdir -p \$PBS_O_WORKDIR/status/\$PBS_ARRAYID
  cp \$PBS_O_WORKDIR/$SPECIESTREE \$CLONALORIGINDIR
  for h in \$(eval echo {1..$NREPLICATE}); do
    mkdir -p \$CLONALORIGINDIR/output/\$h
  done
}

function retrieve-data {
  for h in \$(eval echo {1..$NREPLICATE}); do
    cp \$CLONALORIGINDIR/output/\$h/* \$PBS_O_WORKDIR/output/\$h
  done
  # Remove the status directory.
  rm -rf \$PBS_O_WORKDIR/status/\$PBS_ARRAYID
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batchjob.sh \\
      \$i \\
      \$PBS_O_WORKDIR/coi.jobidfile \\
      \$PBS_O_WORKDIR/coi.lockfile \\
      \$PBS_O_WORKDIR/status/\$PBS_ARRAYID \\
      PBSARRAYSIZE&
  done
}

copy-data
process-data; wait
retrieve-data
cd \$PBS_O_WORKDIR
rm -rf \$TMPDIR
EOF
      scp -q $RUNCLONALORIGIN/batch.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      echo -e "Go to $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin"
      echo -e "Submit a job using a different command."
      echo -e "$ bash run.sh"
      break
    fi
  done
}

