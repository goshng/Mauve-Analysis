#!/bin/bash
 
RUNDIR=$2
  
SCRATCH=/tmp/$USER
#cd $SCRATCH
   
cp -r $SCRATCH/xml $RUNDIR/

rm -rf $SCRATCH
