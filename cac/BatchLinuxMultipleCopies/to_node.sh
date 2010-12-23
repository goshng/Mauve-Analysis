#!/bin/bash

EXT=$1-${HOSTNAME:ar}
RUNDIR=$2

SCRATCH=/tmp/$USER
# -p tells mkdir not to worry if the directory already exists.
# If it matters, you could delete everything in the directory before starting.
rm -rf $SCRATCH
mkdir -p $SCRATCH

cp $RUNDIR/*.R $SCRATCH/
