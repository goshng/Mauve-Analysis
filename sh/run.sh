#!/bin/bash
# Author: Sang Chul Choi

# Programs
MAUVE=$HOME/Documents/Projects/mauve/build/mauveAligner/src/progressiveMauve
GCT=$HOME/usr/bin/getClonalTree 
AUI=$HOME/usr/bin/addUnalignedIntervals 
MWF=$HOME/usr/bin/makeMauveWargFile.pl
RESULT1=1alignment
ALIGNMENT=run-mauve-genome26/output
CLONALFRAMEOUTPUT=run-clonalframe/
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
  BASEDIR=`pwd`/output/$SPECIES
  RUNMAUVEDIR=$BASEDIR/run-mauve
  RUNMAUVEOUTPUTDIR=$RUNMAUVEDIR/output
  RUNLCBDIR=$BASEDIR/run-lcb
  RUNCLONALFRAME=$BASEDIR/run-clonalframe
  RSCRIPTW=$BASEDIR/w.R
  CACBASEDIR=/Volumes/sc2265/Documents/Projects/mauve/output/$SPECIES
  CACDATADIR=$CACBASEDIR/data
  CACRUNMAUVEDIR=$CACBASEDIR/run-mauve
  CACRUNLCBDIR=$CACBASEDIR/run-lcb
  CACRUNCLONALFRAME=$CACBASEDIR/run-clonalframe
  BATCH_SH_RUN_MAUVE=$RUNMAUVEDIR/batch.sh
  BATCH_SH_RUN_CLONALFRAME=$RUNCLONALFRAME/batch.sh
  TMPDIR=/tmp/$JOBID.scheduler.v4linux
  TMPINPUTDIR=$TMPDIR/input
  SWIFTGENDIR=choi@swiftgen:Documents/Projects/mauve/output/$SPECIES
  SWIFTGENRUNCLONALFRAME=$SWIFTGENDIR/run-clonalframe
  SMALLER=smaller
}

function mkdir-SPECIES {
  mkdir $BASEDIR
  mkdir $CACBASEDIR
  mkdir $CACDATADIR
  mkdir $CACRUNMAUVEDIR
  mkdir $RUNMAUVEDIR
  mkdir $CACRUNCLONALFRAME
  mkdir $RUNCLONALFRAME
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
  numberLine=`wc $1 | awk '{print $1'}`
   
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


function copy-genomes-to-cac {
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

for index in 0 1 2 3 4 5 6 7
do
LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/cac/contrib/gsl-1.12/lib \\
./ClonalFrame -x \${x[\$index]} -y \${y[\$index]} -z \${z[\$index]} \\
-m 1506.71 -M \\
-t 2 \\
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
      run-blocksplit2smallerfasta 
      # Compute Watterson's estimate.
      compute-watterson-estimate > w.txt
      # Use R to sum the values in w.txt.
      sum-w
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

# 4. Receive clonalframe-analysis.
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
CHOICES=( list-species generate-species preparation receive-run-mauve prepare-run-clonalframe receive-run-clonalframe )
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
  elif [ "$CHOICE" == "receive-run-clonalframe" ];  then
    receive-run-clonalframe
    break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

# 1. I make directories in CAC and copy genomes files to the data directory.
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
# %s/\/tmp\/1073978.scheduler.v4linux\/input/\/Users\/goshng\/Documents\/Projects\/mauve\/$SPECIES\/data/g
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
#send-clonalframe-input-to-cac 
#copy-batch-sh-run-clonalframe
# Go to CAC Cluster to submit clonalframe jobs.
#receive-run-clonalframe
#send-run-clonalframe-to-swiftgen


# Note that full_alignment.xmfa has the input genomes.
# Copy the genomes52 directory to /tmp/sc2265.
#run-lcb

#run-clonalframe



#run-bbfilter 

