#!/bin/bash
# task.sh, The farm program runs this once for each task.
set -x
CASE=$1
JOBINDEX=$2
echo rank $PMI_RANK ${CASE} $JOBINDEX


BASEDIR=$HOME/Documents/Projects/mauve/Farm

# The scheduler automatically creates a $TMPDIR on the local drive of each node,
# but farm will run 8 separate processes, one for each core of the node, so each
# one likely needs its own subdirectory.
TEMPDIR=$TMPDIR/${JOBINDEX}
mkdir -p $TEMPDIR

# Your data files and directories will differ
OUTFILE=${CASE}.txt

cp $BASEDIR/data.txt $TEMPDIR/
#cp ~/bin/* $TEMPDIR/

cd $TEMPDIR

# Printing the data to OUTFILE with only one > deletes any previous OUTFILE
# while >> appends.
date
date > $OUTFILE
#./${EXECBASE} ${CASE} >> $OUTFILE
cat data.txt >> $OUTFILE
date >> $OUTFILE
date

#cp ${CASE}.* BASEDIR/results
cp $OUTFILE $BASEDIR/results

# Get out of the working directory before you delete it.
cd
rm -rf "$TEMPDIR"
