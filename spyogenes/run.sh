

#/Users/goshng/Documents/Projects/mauve
BASE=$HOME/Documents/Projects/mauve
#MAUVE=$HOME/usr/bin/progressiveMauve

#MAUVE=/Applications/Mauve.app/Contents/MacOS/progressiveMauve
#MAUVE=$HOME/Applications/Mauve.app/Contents/MacOS/progressiveMauve
MAUVE=$HOME/Documents/Projects/mauve/build/mauveAligner/src/progressiveMauve

GCT=$HOME/usr/bin/getClonalTree 
AUI=$HOME/usr/bin/addUnalignedIntervals 
MWF=$HOME/usr/bin/makeMauveWargFile.pl
RESULT1=1alignment
ALIGNMENT=run-mauve-genome26/output
CLONALFRAMEOUTPUT=run-clonalframe/

function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

# Programs
LCB=$HOME/usr/bin/stripSubsetLCBs 

# Directories
BASEDIR=`pwd`
RUNMAUVEDIR=$BASEDIR/run-mauve
RUNMAUVEOUTPUTDIR=$RUNMAUVEDIR/output
RUNLCBDIR=$BASEDIR/run-lcb
RUNCLONALFRAME=$BASEDIR/run-clonalframe
RSCRIPTW=$BASEDIR/w.R
GENOMEDATADIR=/Volumes/Elements/Documents/Projects/mauve/bacteria
CACBASEDIR=/Volumes/sc2265/Documents/Projects/mauve/spyogenes
CACDATADIR=$CACBASEDIR/data
CACRUNMAUVEDIR=$CACBASEDIR/run-mauve
CACRUNLCBDIR=$CACBASEDIR/run-lcb
CACRUNCLONALFRAME=$CACBASEDIR/run-clonalframe
BATCH_SH_RUN_MAUVE=$RUNMAUVEDIR/batch.sh
BATCH_SH_RUN_CLONALFRAME=$RUNCLONALFRAME/batch.sh
TMPINPUTDIR=/tmp/1074038.scheduler.v4linux/input
SWIFTGENDIR=choi@swiftgen:Documents/Projects/mauve/spyogenes/
SWIFTGENRUNCLONALFRAME=$SWIFTGENDIR/run-clonalframe
SMALLER=smaller

function mkdir-spyogenes {
  mkdir $CACBASEDIR
  mkdir $CACDATADIR
  mkdir $CACRUNMAUVEDIR
  mkdir $RUNMAUVEDIR
  mkdir $CACRUNCLONALFRAME
  mkdir $RUNCLONALFRAME
  mkdir $RUNLCBDIR
  mkdir $CACRUNLCBDIR
}

function copy-genomes-to-cac {
  # 1. M1 \$INPUTDIR/NC_002737.gbk \\
  # 2. M2 \$INPUTDIR/NC_008022.gbk \\
  # 3. M6 \$INPUTDIR/NC_006086.gbk \\
  # 4. M4 \$INPUTDIR/NC_008024.gbk \\
  # 5. M12 \$INPUTDIR/NC_008023.gbk \\
  # 6. M3 \$INPUTDIR/NC_004070.gbk \\
  # 7. M1 \$INPUTDIR/NC_007297.gbk \\
  # 8. M28 \$INPUTDIR/NC_007296.gbk \\
  # 9. M18 \$INPUTDIR/NC_003485.gbk \\
  # 10.M12 \$INPUTDIR/NC_008021.gbk \\
  # 11.M5 \$INPUTDIR/NC_009332.gbk \\
  # 12.M49 \$INPUTDIR/NC_011375.gbk \\
  # 13.M3 \$INPUTDIR/NC_004606.gbk
  cp $GENOMEDATADIR/Streptococcus_pyogenes_M1_GAS_uid57845/NC_002737.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_Manfredo_uid57847/NC_009332.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10270_uid58571/NC_008022.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10394_uid58105/NC_006086.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10750_uid58575/NC_008024.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS2096_uid58573/NC_008023.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS315_uid57911/NC_004070.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS5005_uid58337/NC_007297.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS6180_uid58335/NC_007296.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS8232_uid57871/NC_003485.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS9429_uid58569/NC_008021.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_NZ131_uid59035/NC_011375.gbk $CACDATADIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_SSI_1_uid57895/NC_004606.gbk $CACDATADIR
}

function copy-batch-sh-run-mauve {
cat>$BATCH_SH_RUN_MAUVE<<EOF
#!/bin/bash
#PBS -l walltime=8:00:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep
#PBS -q v4
#PBS -m e
#PBS -M schoi@cornell.edu
WORKDIR=\$PBS_O_WORKDIR
DATADIR=\$WORKDIR/../data
MAUVE=\$HOME/usr/bin/progressiveMauve

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$MAUVE \$TMPDIR/
cp \$DATADIR/* \$INPUTDIR/
cd \$TMPDIR
./progressiveMauve --output=\$OUTPUTDIR/full_alignment.xmfa \\
  --output-guide-tree=\$OUTPUTDIR/guide.tree \\
  \$INPUTDIR/NC_002737.gbk \\
  \$INPUTDIR/NC_008022.gbk \\
  \$INPUTDIR/NC_006086.gbk \\
  \$INPUTDIR/NC_008024.gbk \\
  \$INPUTDIR/NC_008023.gbk \\
  \$INPUTDIR/NC_004070.gbk \\
  \$INPUTDIR/NC_007297.gbk \\
  \$INPUTDIR/NC_007296.gbk \\
  \$INPUTDIR/NC_003485.gbk \\
  \$INPUTDIR/NC_008021.gbk \\
  \$INPUTDIR/NC_009332.gbk \\
  \$INPUTDIR/NC_011375.gbk \\
  \$INPUTDIR/NC_004606.gbk

cp -r \$OUTPUTDIR \$WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_MAUVE 
  cp $BATCH_SH_RUN_MAUVE $CACRUNMAUVEDIR/
}

function receive-run-mauve {
  cp -r $CACRUNMAUVEDIR/output $RUNMAUVEDIR/
}

function mkdir-tmp {
  mkdir -p $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_M1_GAS_uid57845/NC_002737.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_Manfredo_uid57847/NC_009332.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10270_uid58571/NC_008022.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10394_uid58105/NC_006086.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10750_uid58575/NC_008024.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS2096_uid58573/NC_008023.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS315_uid57911/NC_004070.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS5005_uid58337/NC_007297.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS6180_uid58335/NC_007296.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS8232_uid57871/NC_003485.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS9429_uid58569/NC_008021.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_NZ131_uid59035/NC_011375.gbk $TMPINPUTDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_SSI_1_uid57895/NC_004606.gbk $TMPINPUTDIR
}

function rmdir-tmp {
  rm -rf $TMPINPUTDIR
}

function run-lcb {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $RUNMAUVEOUTPUTDIR/full_alignment.xmfa \
    $RUNMAUVEOUTPUTDIR/full_alignment.xmfa.bbcols \
    $RUNLCBDIR/core_alignment.xmfa 500
}

function run-blocksplit2fasta {
  perl $HOME/usr/bin/blocksplit2fasta.pl $RUNLCBDIR/core_alignment.xmfa
}

function run-blocksplit2smallerfasta {
  rm -f $RUNLCBDIR/core_alignment.xmfa.*
  perl $HOME/usr/bin/blocksplit2smallerfasta.pl \
    $RUNLCBDIR/core_alignment.xmfa 0.1 12345
}

function compute-watterson-estimate {
  FILES=$RUNLCBDIR/core_alignment.xmfa.*
  for f in $FILES
  do
    # take action on each file. $f store current file name
    DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
    /Users/goshng/Documents/Projects/biopp/bpp-test/compute_watterson_estimate \
    $f
  done
}

function sum-w {
  cat>$RSCRIPTW<<EOF
x <- read.table ("w.txt")
sum (x$V1)
EOF
  R --no-save < $RSCRIPTW
}

function send-clonalframe-input-to-cac {
  cp $RUNLCBDIR/${SMALLER}core_alignment.xmfa $CACRUNLCBDIR/
}

function copy-batch-sh-run-clonalframe {
  cat>$BATCH_SH_RUN_CLONALFRAME<<EOF
#!/bin/bash
#PBS -l walltime=168:00:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep
#PBS -q v4
#PBS -m e
#PBS -M schoi@cornell.edu
WORKDIR=\$PBS_O_WORKDIR
DATADIR=\$WORKDIR/../data
MAUVE=\$HOME/usr/bin/progressiveMauve
LCBDIR=\$WORKDIR/../run-lcb
CLONALFRAME=\$HOME/usr/bin/ClonalFrame

OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input
mkdir \$INPUTDIR
mkdir \$OUTPUTDIR
cp \$CLONALFRAME \$TMPDIR/
cp \$LCBDIR/* \$INPUTDIR/
cd \$TMPDIR

x=( 10000 10000 20000 20000 30000 30000 40000 40000 )
y=( 10000 10000 20000 20000 30000 30000 40000 40000 )
z=(    10    10    20    20    30    30    40    40 )

for index in 0 1 2 3 4 5 6 7
do
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \\
./ClonalFrame -x \${x[\$index]} -y \${y[\$index]} -z \${z[\$index]} \\
-m 0.3026701 -M \\
\$INPUTDIR/${SMALLER}core_alignment.xmfa \\
\$OUTPUTDIR/${SMALLER}core_clonalframe.out.\$index \\
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
  cp $BATCH_SH_RUN_CLONALFRAME $CACRUNCLONALFRAME/
}

function receive-run-clonalframe {
  cp -r $CACRUNCLONALFRAME/output $RUNCLONALFRAME/
}

function send-run-clonalframe-to-swiftgen {
  scp -r $CACRUNCLONALFRAME/output $SWIFTGENRUNCLONALFRAME/
}

function run-clonalframe {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  ClonalFrame -x 0 -y 0 -z 1 -t 2 $ALIGNMENT/core_alignment.xmfa \
  $CLONALFRAMEOUTPUT/core_clonalframe.out.1 > $CLONALFRAMEOUTPUT/cf_stdout.1 
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #ClonalFrame -x 10 -y 10 -z 1 $ALIGNMENT/core_alignment.xmfa $ALIGNMENT/core_clonalframe.out.1 > $ALIGNMENT/cf_stdout.1 
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #ClonalFrame -x 10000 -y 10000 -z 10 core_alignment.xmfa core_clonalframe.out.2 > cf_stdout.2 
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #ClonalFrame -x 10000 -y 10000 -z 10 core_alignment.xmfa core_clonalframe.out.3 > cf_stdout.3 
}

function run-clonalorigin-format {
  $GCT core_clonalframe.out.1 clonaltree.nwk
  perl $HOME/usr/bin/blocksplit.pl core_alignment.xmfa
}

function run-clonalorigin-format {
  $GCT core_clonalframe.out.1 clonaltree.nwk
  perl $HOME/usr/bin/blocksplit.pl core_alignment.xmfa
}

function run-warg {
  #for i in {1..575}
  #rm -rf xml
  #mkdir xml

  PMI_RANK=$1
  PMI_START=$(( 144 * PMI_RANK + 1 ))
  PMI_END=$(( 144 * (PMI_RANK + 1) ))

  START_TIME=`date +%s`
  for (( i=${PMI_START}; i<=${PMI_END}; i++ ))
  #for i in {1..575}
  do
    if [ $i -lt 576 ]
    then
    #warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 1000000 -z 10000 clonaltree.nwk core_alignment.xmfa.$i core_co.phase2.$i.xml
    #warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 10000 -x 10000 -y 10000 -z 10 clonaltree.nwk \
      #xmfa/core_alignment.xmfa.$i xml/core_co.phase2.$i.xml
    warg -w 10000 -x 10000 -y 10000 -z 10 \
      -D 1725.16905094905 -T 0.0386842013408279 -R 0.000773885007973949 \
      clonaltree.nwk xmfa/core_alignment.xmfa.$i xml3/core_co.phase3.$i.xml
    fi
  done
  END_TIME=`date +%s`
  ELAPSED=`expr $END_TIME - $START_TIME`
  echo "FINISHED at " `date` " Elapsed time: " 
  hms $ELAPSED 

  # lensum is 1127288
  # Median theta: 0.0386842013408279
  # Median delta: 1725.16905094905
  # Median rho: 0.000773885007973949
}

function mauve-display {
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #$AUI core_alignment.xmfa core_alignment_mauveable.xmfa

  perl $MWF xml3-cac/*
}

function run-bbfilter {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  bbFilter $ALIGNMENT/full_alignment.xmfa.backbone 50 my_feats.bin gp
}

# 1. I make directories in CAC and copy genomes files to the data directory.
#mkdir-spyogenes
#copy-genomes-to-cac 
#copy-batch-sh-run-mauve
# -----------------------------------------------------------
# At the CAC base directory, submit the batch.sh by executing
# $ nsub batch.sh
# Then, copy the result to here.
#receive-run-mauve
# And, find core blocks of the alignment.
# NOTE: full_alignment.xmfa has input genome files full paths.
#       These are the paths that were used in CAC not local machine.
#       I have to replace those paths to the genome files paths
#       of this local machine.
# We could edit the xmfa file, but instead
# %s/\/tmp\/1073978.scheduler.v4linux\/input/\/Users\/goshng\/Documents\/Projects\/mauve\/spyogenes\/data/g
# Also, change the backbone file name.
# I make the same file system structure as the run-mauve.
#mkdir-tmp 
# Then, run LCB.
#run-lcb 
# Find all the blocks in FASTA format.
#run-blocksplit2fasta 
#run-blocksplit2smallerfasta 
# Compute Watterson's estimate.
#compute-watterson-estimate > w.txt
# Use R to sum the values in w.txt.
#sum-w
# I found out that the sum is 3.213054

# 2. I use ClonalFrame.
# NOTE: One thing that I am not sure about is the mutation rate.
#       Xavier said that I could fix the mutation rate to Watterson's estimate.
#       I do not know how to do it with finite-sites data.
#       McVean (2002) in Genetics.
#       ln(L/(L-S))/\sum_{k=1}^{n-1}1/k.
#       Just remove gaps and use the alignment without gaps.
#       I may have to find this value from the core genome
#       alignment: core_alignment.xmfa.
# NOTE: I run clonalframe for a very short time to find a NJ tree.
#       I had to run clonalframe twice.
send-clonalframe-input-to-cac 
copy-batch-sh-run-clonalframe
# Go to CAC Cluster to submit clonalframe jobs.
#receive-run-clonalframe
#send-run-clonalframe-to-swiftgen


# Note that full_alignment.xmfa has the input genomes.
# Copy the genomes52 directory to /tmp/sc2265.
#run-lcb

#run-clonalframe



#run-bbfilter 

