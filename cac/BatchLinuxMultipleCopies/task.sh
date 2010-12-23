#!/bin/bash

# Create a file extension unique to each hostname (if you want)
# The %%.* turns v4linuxlogin1.cac.cornell.edu into v4linuxlogin1.
EXT=$1-${HOSTNAME%%.*}
RUNDIR=$2

SCRATCH=/tmp/$USER

cd $SCRATCH

R --no-save --args ${PMI_RANK} < main.R > out${PMI_RANK}.txt