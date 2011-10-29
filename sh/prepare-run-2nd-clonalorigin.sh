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

function prepare-run-2nd-clonalorigin {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO2-NREPLICATE species/$SPECIES | cut -d":" -f2)
      WALLTIME=$(grep ^REPETITION${REPETITION}-CO2-WALLTIME species/$SPECIES | cut -d":" -f2)
      CO2BURNIN=$(grep ^REPETITION${REPETITION}-CO2-BURNIN species/$SPECIES | cut -d":" -f2)
      CO2CHAINLENGTH=$(grep ^REPETITION${REPETITION}-CO2-CHAINLENGTH species/$SPECIES | cut -d":" -f2)
      CO2THIN=$(grep ^REPETITION${REPETITION}-CO2-THIN $SPECIESFILE | cut -d":" -f2)
      REPLICATECLONALORIGIN1=$(grep ^REPETITION${REPETITION}-CO2-CO1ID $SPECIESFILE | cut -d":" -f2)
      if [ ! -f "$RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt" ]; then
        echo "No summary file called $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt" 1>&2
        exit
      fi

      THETA_PER_SITE=$(grep "Median theta" $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt | cut -d ":" -f 2)
      DELTA=$(grep "Median delta" $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt | cut -d ":" -f 2)
      RHO_PER_SITE=$(grep "Median rho" $RUNCLONALORIGIN/summary/${REPLICATECLONALORIGIN1}/median.txt | cut -d ":" -f 2)
      echo -e "  Preparing 2nd clonalorigin ... "

      SPECIESTREE=clonaltree.nwk

      echo "  Creating jobidfile..."
      NUMBER_BLOCK=$(trim $(echo `ls $DATADIR/$CORE_ALIGNMENT.*|wc -l`))
      JOBIDFILE=$RUNCLONALORIGIN/coii.jobidfile
      rm -f $JOBIDFILE
      for h in $(eval echo {1..$NREPLICATE}); do
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          TREE=output/$SPECIES/$REPETITION/run-clonalorigin/clonaltree.nwk
          XMFA=output/$SPECIES/$REPETITION/data/core_alignment.xmfa.$b
          XML=output/$SPECIES/$REPETITION/run-clonalorigin/output2/$h/core_co.phase3.xml.$b
          echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
            -x $CO2BURNIN -y $CO2CHAINLENGTH -z $CO2THIN \
            -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE \
            $TREE $XMFA $XML >> $JOBIDFILE
        done
      done

      scp -q $JOBIDFILE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -q cac/sim/batch_task.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/batchjob.sh
      scp -q cac/sim/run.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin

cat>$RUNCLONALORIGIN/batch.sh<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-CO2
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

for g in \$(eval echo {1..$NREPLICATE}); do
  mkdir -p output2/\$g
done

function copy-data {
  cd \$TMPDIR
  cp \$WARG .
  cp \$PBS_O_WORKDIR/batchjob.sh .
  mkdir -p \$NUMBERDIR
  cp -r \$PBS_O_WORKDIR/../data \$NUMBERDIR
  cp -r \$PBS_O_WORKDIR/../run-analysis \$NUMBERDIR
  cp -r \$PBS_O_WORKDIR/$SPECIESTREE \$NUMBERDIR
  for h in \$(eval echo {1..$NREPLICATE}); do
    mkdir -p \$CLONALORIGINDIR/output2/\$h
  done
}

function retrieve-data {
  for h in \$(eval echo {1..$NREPLICATE}); do
    cp \$CLONALORIGINDIR/output2/\$h/* \$PBS_O_WORKDIR/output2/\$h
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
      scp -q $RUNCLONALORIGIN/batch.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin

      echo -e "Go to $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin"
      echo -e "Submit a job using a different command."
      echo -e "$ bash run.sh"
      break
    fi
  done
}
