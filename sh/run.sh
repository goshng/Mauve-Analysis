#!/bin/bash
# Author: Sang Chul Choi

# How to customize this script:
# SMALLER: To analyze a smaller data set with ClonalFrame.
# SMALLERCLONAL: To nalayze a smaller data set with ClonalOrigin.
# Remove either of these to analyze the full data set.
# 
# FIXME:
# When running ClonalOrigin, I use nodes=1 and -t option to
# control the number of computing nodes. I do not know 
# how to find the number of nodes.  NODECNT must be the same
# as the number of elements in the PBS's ARRAY.
# NODECNT=2 # This must match -t option.
#
# Menus:
#   - list-species: 
#   - generate-species:
#   - preparation: makes file system for a species, and make it ready to run
#   mauve.
#   - receive-run-mauve: gets the result of mauve alignment from the cluster
#   - prepare-run-clonalframe: finds blocks and makes a script to run
#   clonalframe.
#   - compute-watterson-estimate-for-clonalframe: (optional)
#   - receive-run-clonalframe: receives the result of clonal frame analysis.
#   - prepare-run-clonalorigin: makes a script for clonal origin analysis.
#   - receive-run-clonalorigin: receives the result of the first stage of clonal
#   origin analysis. 
#   - receive-run-2nd-clonalorigin: receives the result of the second stage of
#   clonal analysis.

# bash sh/run.sh smaller smaller
# bash sh/run.sh 

SMALLER=$1
SMALLERCLONAL=$2

# Programs
MAUVE=$HOME/Documents/Projects/mauve/build/mauveAligner/src/progressiveMauve
GCT=$HOME/usr/bin/getClonalTree 
AUI=$HOME/usr/bin/addUnalignedIntervals 
MWF=$HOME/usr/bin/makeMauveWargFile.pl
COMPUTEMEDIANS=$HOME/usr/bin/computeMedians.pl
LCB=$HOME/usr/bin/stripSubsetLCBs 
# Genome Data Directory
GENOMEDATADIR=/Volumes/Elements/Documents/Projects/mauve/bacteria

function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

# Directories
function prepare-filesystem {
  MAUVEANALYSISDIR=`pwd`
  SPECIESFILE=species/$SPECIES
  NUMBER_SPECIES=$(wc -l < species/$SPECIES)
  BASEDIR=`pwd`/output/$SPECIES
  RUNMAUVEDIR=$BASEDIR/run-mauve
  RUNMAUVEOUTPUTDIR=$RUNMAUVEDIR/output
  RUNLCBDIR=$BASEDIR/run-lcb
  RUNCLONALFRAME=$BASEDIR/run-clonalframe
  RUNCLONALORIGIN=$BASEDIR/run-clonalorigin
  RSCRIPTW=$BASEDIR/w.R
  CACBASEDIR=/Volumes/sc2265/Documents/Projects/mauve/output/$SPECIES
  CACDATADIR=$CACBASEDIR/data
  CACRUNMAUVEDIR=$CACBASEDIR/run-mauve
  CACRUNLCBDIR=$CACBASEDIR/run-lcb
  CACRUNCLONALFRAME=$CACBASEDIR/run-clonalframe
  CACRUNCLONALORIGIN=$CACBASEDIR/run-clonalorigin
  BATCH_SH_RUN_MAUVE=$RUNMAUVEDIR/batch.sh
  BATCH_SH_RUN_CLONALFRAME=$RUNCLONALFRAME/batch.sh
  BATCH_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch.sh
  BATCH_BODY_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_body.sh
  BATCH_TASK_SH_RUN_CLONALORIGIN=$RUNCLONALORIGIN/batch_task.sh
  TMPDIR=/tmp/$JOBID.scheduler.v4linux
  TMPINPUTDIR=$TMPDIR/input
  SWIFTGENDIR=choi@swiftgen:Documents/Projects/mauve/output/$SPECIES
  SWIFTGENRUNCLONALFRAME=$SWIFTGENDIR/run-clonalframe
   
  RUNLOG=$BASEDIR/run.log
}

function mkdir-SPECIES {
  mkdir $BASEDIR
  mkdir $CACBASEDIR
  mkdir $CACDATADIR
  mkdir $CACRUNMAUVEDIR
  mkdir $RUNMAUVEDIR
  mkdir $CACRUNCLONALFRAME
  mkdir $CACRUNCLONALORIGIN
  mkdir $RUNCLONALFRAME
  mkdir $RUNCLONALORIGIN
  mkdir $RUNLCBDIR
  mkdir $CACRUNLCBDIR
}

########################################################################
# 
########################################################################

function mkdir-tmp-called {
  line="$@" # get all args
  cp $GENOMEDATADIR/$line $TMPINPUTDIR
}

function copy-batch-sh-run-mauve-called {
  line=$1 # get all args
  isLast=$2
  filename_gbk=`basename $line`
  if [ "$isLast" == "last" ]; then
    echo "  \$INPUTDIR/$filename_gbk" >> $BATCH_SH_RUN_MAUVE 
  else
    echo "  \$INPUTDIR/$filename_gbk \\" >> $BATCH_SH_RUN_MAUVE 
  fi
}

function copy-genomes-to-cac-called {
  line="$@" # get all args
  cp $GENOMEDATADIR/$line $CACDATADIR
}

function processLine {
  line="$@" # get all args
  #  just echo them, but you may need to customize it according to your need
  # for example, F1 will store first field of $line, see readline2 script
  # for more examples
  # F1=$(echo $line | awk '{ print $1 }')
  echo $line
  #cp $GENOMEDATADIR/$line $CACDATADIR
}
 
########################################################################
# I found a script at
# http://bash.cyberciti.biz/file-management/read-a-file-line-by-line/ 
# to read a file line by line. I use it to read a species file.
# I could directly read the directory to find genbank files.
# Genbank directory of my machine is
# /Users/goshng/Elements/Documents/Projects/mauve/bacteria.
# A command line to list genbank files is as follows:
# ls -l `find . -name *.gbk`| grep Clostridium_botulinum >
# ~/Documents/Projects/mauve/species/Clostridium_botulinum
# Let me try to use the script of reading line by line for the time being.
########################################################################
function read-species-genbank-files {
  wfunction_called=$2
  ### Main script stars here ###
  # Store file name
  FILE=""
  numberLine=`grep ^\[^#\] $1 | wc | awk '{print $1'}`
   
  # Make sure we get file name as command line argument
  # Else read it from standard input device
  if [ "$1" == "" ]; then
     FILE="/dev/stdin"
  else
     FILE="$1"
     # make sure file exist and readable
     if [ ! -f $FILE ]; then
      echo "$FILE : does not exists"
      exit 1
     elif [ ! -r $FILE ]; then
      echo "$FILE: can not read"
      exit 2
     fi
  fi
  # read $FILE using the file descriptors
   
  # Set loop separator to end of line
  BAKIFS=$IFS
  IFS=$(echo -en "\n\b")
  exec 3<&0
  exec 0<$FILE
  countLine=0
  isLast=""
  while read line
  do
    if [[ "$line" =~ ^# ]]; then 
      continue
    fi
    countLine=$((countLine + 1))
    if [ $countLine == $numberLine ]; then
      isLast="last"
    else
      isLast=""
    fi
    # use $line variable to process line in processLine() function
    if [ $wfunction_called == "copy-genomes-to-cac" ]; then
      copy-genomes-to-cac-called $line
    elif [ $wfunction_called == "copy-batch-sh-run-mauve" ]; then
      copy-batch-sh-run-mauve-called $line $isLast
    elif [ $wfunction_called == "mkdir-tmp" ]; then
      mkdir-tmp-called $line
    fi
  done
  exec 0<&3
   
  # restore $IFS which was used to determine what the field separators are
  BAKIFS=$ORIGIFS
}

function copy-batch-sh-run-mauve {
cat>$BATCH_SH_RUN_MAUVE<<EOF
#!/bin/bash
#PBS -l walltime=8:00:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep-${SPECIES}-Mauve
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
EOF

  read-species-genbank-files $SPECIESFILE copy-batch-sh-run-mauve

cat>>$BATCH_SH_RUN_MAUVE<<EOF
cp -r \$OUTPUTDIR \$WORKDIR/
cd
rm -rf \$TMPDIR
EOF
  chmod a+x $BATCH_SH_RUN_MAUVE 
  cp $BATCH_SH_RUN_MAUVE $CACRUNMAUVEDIR/
}

function mkdir-tmp {
  mkdir -p $TMPINPUTDIR
  read-species-genbank-files $SPECIESFILE mkdir-tmp
  #cp $GENOMEDATADIR/Streptococcus_pyogenes_SSI_1_uid57895/NC_004606.gbk $TMPINPUTDIR
}

function rmdir-tmp {
  rm -rf $TMPDIR
}

function run-lcb {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $RUNMAUVEOUTPUTDIR/full_alignment.xmfa \
    $RUNMAUVEOUTPUTDIR/full_alignment.xmfa.bbcols \
    $RUNLCBDIR/core_alignment.xmfa 500
}

function run-core2smallercore {
  perl $HOME/usr/bin/core2smallercore.pl \
    $RUNLCBDIR/core_alignment.xmfa 0.1 12345
}

function run-blocksplit2fasta {
  rm -f $RUNLCBDIR/${SMALLER}core_alignment.xmfa.*
  perl $HOME/usr/bin/blocksplit2fasta.pl $RUNLCBDIR/${SMALLER}core_alignment.xmfa
}

function compute-watterson-estimate {
  FILES=$RUNLCBDIR/${SMALLER}core_alignment.xmfa.*
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
  rm sum-w.txt
  echo -e "Watteron estimate: $WATTERSON_ESIMATE"
  echo -e "Finite-site version of Watteron estimate: $FINITEWATTERSON_ESIMATE"
  echo -e "Length of sequences: $LEGNTH_SEQUENCE"
  echo -e "Number of blocks: $NUMBER_BLOCKS"
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE"
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES"
  rm -f $RUNLOG
  echo -e "Watteron estimate: $WATTERSON_ESIMATE" >> $RUNLOG
  echo -e "Finite-site version of Watteron estimate: $FINITEWATTERSON_ESIMATE" >> $RUNLOG
  echo -e "Number of blocks: $NUMBER_BLOCKS" >> $RUNLOG
  echo -e "Average length of sequences: $AVERAGELEGNTH_SEQUENCE" >> $RUNLOG
  echo -e "Proportion of polymorphic sites: $PROPORTION_POLYMORPHICSITES" >> $RUNLOG
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
#PBS -N Strep-${SPECIES}-ClonalFrame
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

# 1506.71
# 0.3026701 
#-t 2 \\
#-m 1506.71 -M \\

for index in 0 1 2 3 4 5 6 7
do
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \\
./ClonalFrame -x \${x[\$index]} -y \${y[\$index]} -z \${z[\$index]} \\
-m $WATTERSON_ESIMATE -M \\
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

function send-clonalorigin-input-to-cac {
  cp $RUNCLONALORIGIN/clonaltree.nwk $CACRUNCLONALORIGIN/
  cp $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa.* $CACRUNLCBDIR/
}

function copy-batch-sh-run-clonalorigin {

  cat>$BATCH_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
sed s/PBSARRAYSIZE/\$1/g < batch_body.sh > tbatch.sh
nsub tbatch.sh
rm tbatch.sh
EOF

  cat>$BATCH_BODY_SH_RUN_CLONALORIGIN<<EOF
#!/bin/bash
#PBS -l walltime=20:00:00,nodes=1
#PBS -A acs4_0001
#PBS -j oe
#PBS -N Strep-${SPECIES}-ClonalOrigin-$1
#PBS -q v4
#PBS -m e
#PBS -M schoi@cornell.edu
#PBS -t 1-PBSARRAYSIZE

# nsub -t 1-3 batch.sh 3
set -x
CLONAL2ndPHASE=$1
WORKDIR=\$PBS_O_WORKDIR
LCBDIR=\$WORKDIR/../run-lcb
WARG=\$HOME/usr/bin/warg
OUTPUTDIR=\$TMPDIR/output
INPUTDIR=\$TMPDIR/input


function to-node {
  mkdir \$WORKDIR/output
  mkdir \$WORKDIR/output2
  mkdir \$INPUTDIR
  mkdir \$OUTPUTDIR
  cp \$LCBDIR/${SMALLERCLONAL}*.xmfa.* \$INPUTDIR/
  cp \$WORKDIR/clonaltree.nwk \$TMPDIR/
  cp \$WARG \$TMPDIR/
  cp \$WORKDIR/batch_task.sh \$TMPDIR/  
}

function prepare-task {
  # NODENUMBER=8 # What is this number? Is this number of cores of a node?

  # I need to count total jobs.
  TOTALJOBS=\$(ls -1 \$INPUTDIR/${SMALLERCLONAL}*.xmfa.* | wc -l)

  # NODECNT: number of computing nodes
  # TASKCNT: total number of cores
  # PBS_ARRAYID represents a computing node among those nodes.
  CORESPERNODE=\`grep processor /proc/cpuinfo | wc -l\`
  #NODECNT=\$(wc -l < "\$PBS_NODEFILE")
  NODECNT=PBSARRAYSIZE # This must match -t option.
  TASKCNT=\`expr \$CORESPERNODE \\* \$NODECNT\`
  #JOBSPERCORE=\$(( TOTALJOBS / TASKCNT + 1 ))
  JOBSPERNODE=\$(( TOTALJOBS / NODECNT + 1 ))
  # The job id is something like 613.scheduler.v4linux.
  # This deletes everything after the first dot.
  JOBNUMBER=\${PBS_JOBID%%.*}

  JOBIDFILE=\$TMPDIR/jobidfile
  STARTJOBID=\$(( JOBSPERNODE * (PBS_ARRAYID - 1) + 1 ))
  ENDJOBID=\$(( JOBSPERNODE * PBS_ARRAYID + 1 )) 
  TOTALJOBS=\$(( TOTALJOBS + 1))
  # If JOBSPERNODE is 3, then
  # STARTJOBID is 1, and ENDJOBID is 4.
}

function task {
  cd \$TMPDIR
  #for (( i=1; i<=TASKCNT; i++))
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batch_task.sh \$i \$TOTALJOBS \$ENDJOBID \$WORKDIR \$TMPDIR \$JOBIDFILE \$CLONAL2ndPHASE&
  done
}

echo Start at
date
to-node
prepare-task
echo \$STARTJOBID > \$JOBIDFILE
task

wait
echo End at
date

EOF

  # Task batch script
  cat>$BATCH_TASK_SH_RUN_CLONALORIGIN<<EOF
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
TOTALJOBS=\$2
ENDJOBID=\$3
WORKDIR=\$4
SCRATCH=\$5
JOBIDFILE=\$6
CLONAL2ndPHASE=\$7
WHICHLINE=1
JOBID=0

cd \$SCRATCH

# Read the filelock
while [ \$JOBID -lt \$TOTALJOBS ] && [ \$JOBID -lt \$ENDJOBID ]
do

  lockfile=filelock
  if ( set -o noclobber; echo "\$\$" > "\$lockfile") 2> /dev/null; 
  then
    # BK: this will cause the lock file to be deleted in case of other exit
    trap 'rm -f "\$lockfile"; exit \$?' INT TERM

    # critical-section BK: (the protected bit)
    JOBID=\$(sed -n "\${WHICHLINE}p" "\${JOBIDFILE}")

    #LINE=\$(sed -n "\${WHICHLINE}p" "\${COMMANDFILE}")
    #\$LINE : this execute the line.
    JOBID=\$(( JOBID + 1))
    echo \$JOBID > \$JOBIDFILE
    JOBID=\$(( JOBID - 1))

    rm -f "\$lockfile"
    trap - INT TERM

    if [ \$JOBID -lt \$TOTALJOBS ] && [ \$JOBID -lt \$ENDJOBID ]
    then
      echo begin-\$JOBID
      START_TIME=\`date +%s\`
      #./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 2 -x 2 -y 2 -z 1 \\
      if [[ -z \$CLONAL2ndPHASE ]]; then
        ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 100000 -x 100000 -y 100000 -z 1000 \\
          clonaltree.nwk input/${SMALLERCLONAL}core_alignment.xmfa.\$JOBID \\
          \$WORKDIR/output/${SMALLERCLONAL}core_co.phase2.\$JOBID.xml
      else
        #./warg -x 1000000 -y 10000000 -z 100000 \\
        ./warg -x 1000000 -y 1000000 -z 10000 \\
          -T ${MEDIAN_THETA} -D ${MEDIAN_DELTA} -R ${MEDIAN_RHO} \\
          clonaltree.nwk input/${SMALLERCLONAL}core_alignment.xmfa.\$JOBID \\
          \$WORKDIR/output2/${SMALLERCLONAL}core_co.phase3.\$JOBID.xml
      fi
      END_TIME=\`date +%s\`
      ELAPSED=\`expr \$END_TIME - \$START_TIME\`
      echo end-\$JOBID
      hms \$ELAPSED
    fi

  else
    echo "Failed to acquire lockfile: \$lockfile." 
    echo "Held by \$(cat \$lockfile)"
    sleep 5
    echo "Retry to access \$lockfile"
  fi

done
EOF

  chmod a+x $BATCH_SH_RUN_CLONALORIGIN
  cp $BATCH_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
  cp $BATCH_BODY_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
  cp $BATCH_TASK_SH_RUN_CLONALORIGIN $CACRUNCLONALORIGIN/
}

function run-bbfilter {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  bbFilter $ALIGNMENT/full_alignment.xmfa.backbone 50 my_feats.bin gp
}

# 1. I make directories in CAC and copy genomes files to the data directory.
function choose-species {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Wait for muave-analysis file system preparation...\n"
      prepare-filesystem 
      mkdir-SPECIES
      read-species-genbank-files $SPECIESFILE copy-genomes-to-cac
      copy-batch-sh-run-mauve
      echo -e "Go to CAC's $SPECIES run-mauve, and execute nsub batch.sh\n"
      break
    fi
  done
}

# 2. Receive mauve-analysis.
function receive-run-mauve {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Receiving mauve-output...\n"
      prepare-filesystem 
      cp -r $CACRUNMAUVEDIR/output $RUNMAUVEDIR/
      echo -e "Now, find core blocks of the alignment.\n"
      break
    fi
  done
}

# 3. Prepare clonalframe analysis.
# NOTE: full_alignment.xmfa has input genome files full paths.
#       These are the paths that were used in CAC not local machine.
#       I have to replace those paths to the genome files paths
#       of this local machine.
# We could edit the xmfa file, but instead
# %s/\/tmp\/1073978.scheduler.v4linux\/input/\/Users\/goshng\/Documents\/Projects\/mauve\/$SPECIES\/data/g
# Also, change the backbone file name.
# I make the same file system structure as the run-mauve.
#
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
function prepare-run-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e 'What is the temporary id of mauve-analysis?'
      echo -e "You may find it in the $SPECIES/run-mauve/output/full_alignment.xmfa"
      echo -n "JOB ID: " 
      read JOBID
      echo -e "Preparing clonalframe analysis...\n"
      prepare-filesystem 
      echo -e "  Making temporary data files....\n"
      mkdir-tmp 
      # Then, run LCB.
      echo -e "  Finding core blocks of the alignment...\n"
      run-lcb 
      # Find all the blocks in FASTA format.
      #run-blocksplit2fasta 
      echo -e "  Computing Wattersons's estimates...\n"
      run-core2smallercore
      run-blocksplit2fasta 
      #run-blocksplit2smallerfasta 
      # Compute Watterson's estimate.
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
      rm w.txt
      echo -e "You may use the Watterson's estimate in clonalframe analysis.\n"
      echo -e "Or, you may ignore.\n"
      send-clonalframe-input-to-cac 
      copy-batch-sh-run-clonalframe
      rmdir-tmp
      echo -e "Go to CAC's output/$SPECIES run-clonalframe, and execute nsub batch.sh\n"
      break
    fi
  done
}

function compute-watterson-estimate-for-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      prepare-filesystem 
      # Find all the blocks in FASTA format.
      #run-blocksplit2fasta 
      echo -e "  Computing Wattersons's estimates...\n"
      run-core2smallercore
      run-blocksplit2fasta 
      #run-blocksplit2smallerfasta 
      # Compute Watterson's estimate.
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
      rm w.txt
      echo -e "You may use the Watterson's estimate in clonalframe analysis.\n"
      echo -e "Or, you may ignore.\n"
      break
    fi
  done
}

# 6. Receive clonalframe-analysis.
function receive-run-clonalframe {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Receiving clonalframe-output...\n"
      prepare-filesystem 
      cp -r $CACRUNCLONALFRAME/output $RUNCLONALFRAME/
      echo -e "Sending clonalframe-output to swiftgen...\n"
      scp -r $CACRUNCLONALFRAME/output $SWIFTGENRUNCLONALFRAME/
      echo -e "Now, prepare clonalorigin.\n"
      break
    fi
  done
}

# 7. Prepare the first stage of clonalorigin.
function prepare-run-clonalorigin {
  PS3="Choose the species to analyze with clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      #echo -e 'What is the temporary id of mauve-analysis?'
      #echo -e "You may find it in the $SPECIES/run-mauve/output/full_alignment.xmfa"
      #echo -n "JOB ID: " 
      #read JOBID
      echo -e "Preparing clonalframe analysis..."
      prepare-filesystem 

      echo -e "Read which clonalframe output file is used to have a phylogeny of a clonal frame."
      echo -n "RUN ID: " 
      read RUNID
      $GCT $RUNCLONALFRAME/output/${SMALLER}core_clonalframe.out.${RUNID} $RUNCLONALORIGIN/clonaltree.nwk
      echo -e "  Splitting alignment into one file per block..."
      perl $HOME/usr/bin/blocksplit.pl $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa
      # Some script.
      send-clonalorigin-input-to-cac
      copy-batch-sh-run-clonalorigin
      echo -e "Go to CAC's output/$SPECIES run-clonalorigin, and execute nsub batch.sh"
      echo -e "You must use multiple computing nodes by chaing PBS -t option in"
      echo -e "e.g., #PBS -t 1 to use a single computing node"
      echo -e "e.g., #PBS -t 1-2 to use two computing nodes"
      echo -e "Do not use 0-index for -t option"
      echo -e "e.g., This is not work: #PBS -t 0-1"
      echo -e "the batch.sh script."
      break
    fi
  done



}

# 8. Receive clonalorigin-analysis.
function receive-run-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Receiving clonalframe-output...\n"
      prepare-filesystem 
      cp -r $CACRUNCLONALORIGIN/output $RUNCLONALORIGIN/
      perl $COMPUTEMEDIANS \
        $RUNCLONALORIGIN/output/${SMALLERCLONAL}core*.xml \
        | grep ^Median > $RUNCLONALORIGIN/median.txt
      MEDIAN_THETA=$(grep "Median theta" $RUNCLONALORIGIN/median.txt | cut -d ":" -f 2)
      MEDIAN_DELTA=$(grep "Median delta" $RUNCLONALORIGIN/median.txt | cut -d ":" -f 2)
      MEDIAN_RHO=$(grep "Median rho" $RUNCLONALORIGIN/median.txt | cut -d ":" -f 2)
      echo -e "Now, prepare 2nd clonalorigin."
      echo -e "Submit a job using a different command."
      echo -e "$ bash batch.sh 3 to use three computing nodes"
      copy-batch-sh-run-clonalorigin Clonal2ndPhase
      break
    fi
  done
}

# 9. Receive 2nd clonalorigin-analysis.
function receive-run-2nd-clonalorigin {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -e "Receiving 2nd clonalorigin-output...\n"
      prepare-filesystem 
      cp -r $CACRUNCLONALORIGIN/output2 $RUNCLONALORIGIN/

      DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
        $AUI $RUNLCBDIR/${SMALLERCLONAL}core_alignment.xmfa $RUNLCBDIR/${SMALLERCLONAL}core_alignment_mauveable.xmfa
      perl $MWF $RUNCLONALORIGIN/output2/*phase3*.bz2
      echo -e "Now, do more analysis with mauve.\n"
      break
    fi
  done
}

# Find bacteria species and their counts in the NCBI genome data.
function list-species {
  for i in `ls $GENOMEDATADIR`; do 
    echo $i | sed 's/\([[:alpha:]]*\)_\([[:alpha:]]*\)_.*/\1\_\2/'
    #echo $i | sed "s/\([[:alpha:]]+\)/\1/p"
    #echo ${i/*_*_*/}
    #mv $i${i%%.txt}.html
  done
}

# This is prepared using list-species.
ALLSPECIES=( Escherichia_coli Salmonella_enterica Staphylococcus_aureus Streptococcus_pneumoniae Streptococcus_pyogenes Prochlorococcus_marinus Helicobacter_pylori Clostridium_botulinum Bacillus_cereus Yersinia_pestis Sulfolobus_islandicus Francisella_tularensis Rhodopseudomonas_palustris Listeria_monocytogenes Chlamydia_trachomatis Buchnera_aphidicola Bacillus_anthracis Acinetobacter_baumannii Streptococcus_suis Neisseria_meningitidis Mycobacterium_tuberculosis Legionella_pneumophila Cyanothece_PCC Coxiella_burnetii Campylobacter_jejuni Burkholderia_pseudomallei Bifidobacterium_longum Yersinia_pseudotuberculosis Xylella_fastidiosa Xanthomonas_campestris Vibrio_cholerae Shewanella_baltica Rhodobacter_sphaeroides Pseudomonas_putida Pseudomonas_aeruginosa Methanococcus_maripaludis Lactococcus_lactis Haemophilus_influenzae Chlamydophila_pneumoniae Candidatus_Sulcia Burkholderia_mallei Burkholderia_cenocepacia )

# Improvements that are needed.
# 1. Do not use file size options.
function generate-species {
  prepare-filesystem
  for s in ${ALLSPECIES[@]}; do
    ls -1 `find $GENOMEDATADIR -name *.gbk -and -size +1000k` | sed 's/\/Volumes\/Elements\/Documents\/Projects\/mauve\/bacteria\///' | grep $s > $MAUVEANALYSISDIR/species/$s
  done
  #ls -l `find . -name *.gbk`| grep Chlamydia_trachomatis > ~/Documents/Projects/mauve/species/Chlamydia_trachomatis
}

#####################################################################
# Main part of the script.
#####################################################################
PS3="Select what you want to do with mauve-analysis: "
CHOICES=( list-species generate-species preparation receive-run-mauve prepare-run-clonalframe compute-watterson-estimate-for-clonalframe receive-run-clonalframe prepare-run-clonalorigin receive-run-clonalorigin receive-run-2nd-clonalorigin )
select CHOICE in ${CHOICES[@]}; do 
 
  if [ "$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "$CHOICE" == "list-species" ];  then
    list-species | sort | uniq -c | sort -nr > species.txt
    echo -e "A file named species.txt is generated!\n"
    echo -e "Remove counts by running cut -c 5- species.txt\n"
    break
  elif [ "$CHOICE" == "generate-species" ];  then
    generate-species 
    break
  elif [ "$CHOICE" == "preparation" ];  then
    choose-species
    break
  elif [ "$CHOICE" == "receive-run-mauve" ];  then
    receive-run-mauve
    break
  elif [ "$CHOICE" == "prepare-run-clonalframe" ];  then
    prepare-run-clonalframe 
    break
  elif [ "$CHOICE" == "compute-watterson-estimate-for-clonalframe" ];  then
    compute-watterson-estimate-for-clonalframe
    break
  elif [ "$CHOICE" == "receive-run-clonalframe" ];  then
    receive-run-clonalframe
    break
  elif [ "$CHOICE" == "prepare-run-clonalorigin" ];  then
    prepare-run-clonalorigin
    break
  elif [ "$CHOICE" == "receive-run-clonalorigin" ];  then
    receive-run-clonalorigin
    break
  elif [ "$CHOICE" == "receive-run-2nd-clonalorigin" ];  then
    receive-run-2nd-clonalorigin
    break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

