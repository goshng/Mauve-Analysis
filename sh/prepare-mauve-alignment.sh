
# 1. I make directories in CAC and copy genomes files to the data directory.
# --------------------------------------------------------------------------
# Users need to download genome files to a local directory named $GENOMEDATADIR.
# They also need to prepare a species file that contains the actual Genbank
# files. 
# The first job that a user would want to do is to align the genomes. This would
# be done in the cluster CAC. The procedure is as follows:
# 1. Almost all bash variables are set in set-more-global-variable. See the bash function
# for detail. 
# 2. mkdir-species creates main file systems.
# 3. copy-genomes-to-cac copies Genkbank genomes files to CAC.
# 4. copy-batch-sh-run-mauve creates the batch file for mauve alignment, and
# copies it to CAC cluster.
function prepare-mauve-alignment {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "Wait for muave-analysis file system preparation...\n"
      set-more-global-variable $SPECIES $REPETITION

      WALLTIME=$(grep REPETITION${REPETITION}-MAUVE-Walltime species/$SPECIES | cut -d":" -f2)
      mkdir-species
      read-species-genbank-files data/$SPECIES copy-genomes-to-cac
      copy-batch-sh-run-mauve \
        $RUNMAUVE/batch.sh \
        $CAC_USERHOST:$CAC_RUNMAUVE
      echo -e "Go to CAC's $SPECIES run-mauve, and execute nsub batch.sh\n"
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

DATADIR=\$PBS_O_WORKDIR/../data
MAUVE=\$HOME/${BATCHPROGRESSIVEMAUVE}

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$MAUVE \$TMPDIR/
cp \$DATADIR/* \$INPUTDIR/
cd \$TMPDIR
./progressiveMauve --output=\$OUTPUTDIR/full_alignment.xmfa \\
  --output-guide-tree=\$OUTPUTDIR/guide.tree \\
EOF

  read-species-genbank-files data/$SPECIES copy-batch-sh-run-mauve

cat>>$BATCH_SH_RUN_MAUVE<<EOF
cp -r \$OUTPUTDIR \$PBS_O_WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_MAUVE 
  scp -q $BATCH_SH_RUN_MAUVE $2
}

