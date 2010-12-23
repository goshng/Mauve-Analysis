#!/bin/bash

RUNDIR=$2

SCRATCH=/tmp/$USER
cd $SCRATCH

cp -r xml/* $RUNDIR/xml/
cd ..
#rm -rf $SCRATCH
