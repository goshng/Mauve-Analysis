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

function prepare-mauve-alignment {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo "Wait for muave-analysis file system preparation..."
      set-more-global-variable $SPECIES $REPETITION

      WALLTIME=$(grep REPETITION${REPETITION}-MAUVE-WALLTIME species/$SPECIES | cut -d":" -f2)
      # mkdir-species
      read-species-genbank-files data/$SPECIES copy-genomes-to-cac
      read-species-genbank-files data/$SPECIES batch-copy-genome
      copy-batch-sh-run-mauve \
        $RUNMAUVE/batch.sh \
        $CAC_USERHOST:$CAC_RUNMAUVE
      echo "Go to cac:$CAC_ROOT/output/$SPECIES/$REPETITION/run-mauve"
      echo "Execute the following command to submit a job."
      echo "$ nsub batch.sh"
      break
    fi
  done
}

# A batch file for Mauve alignment.
# ---------------------------------
# The menu choose-species calls this bash function to create a batch file for
# mauve genome alignment. The batch file is also copied to the cluster.
# Note that ${BATCHACCESS}, ${BATCHEMAIL}, ${BATCHPROGRESSIVEMAUVE} should be
# edited.
# 
function copy-batch-sh-run-mauve {
  BATCH_SH_RUN_MAUVE=$1 
cat>$BATCH_SH_RUN_MAUVE<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N ${PROJECTNAME}-${SPECIES}-Mauve
#PBS -q ${QUEUENAME}
#PBS -m e
#PBS -M ${BATCHEMAIL}

MAUVE=\$HOME/${BATCHPROGRESSIVEMAUVE}
BASEDIR=output/$SPECIES
NUMBERDIR=output/$SPECIES/$REPETITION
MAUVEDIR=\$NUMBERDIR/run-mauve
DATADIR=\$BASEDIR/data

OUTPUTDIR=output/$SPECIES/$REPETITION/run-mauve/output
cd \$TMPDIR
mkdir -p \$OUTPUTDIR
cp \$MAUVE .
cp -r \$PBS_O_WORKDIR/../../data \$BASEDIR
./progressiveMauve --output=\$OUTPUTDIR/full_alignment.xmfa \\
  --output-guide-tree=\$OUTPUTDIR/guide.tree \\
EOF

  read-species-genbank-files data/$SPECIES copy-batch-sh-run-mauve

cat>>$BATCH_SH_RUN_MAUVE<<EOF
cp -r \$OUTPUTDIR \$PBS_O_WORKDIR
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_MAUVE 
  scp -q $BATCH_SH_RUN_MAUVE $2
}

