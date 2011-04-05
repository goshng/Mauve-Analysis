#!/bin/bash
# File  : noweb.sh
# Author: Sang Chul Choi
# Date  : Thu Mar 24 14:54:44 EDT 2011

# A list of command lines can be applied to a noweb file in the directory named
# noweb.

BASEDIR=`pwd`
NOWEBDIR=$BASEDIR/noweb
SIMMLSTNW=$NOWEBDIR/simmlst.nw
SIMMLSTTEX=$NOWEBDIR/output/simmlst.tex
SIMMLSTDVI=$NOWEBDIR/output/simmlst.dvi
SIMMLSTCOMPILE=$NOWEBDIR/output/simmlst.compile.sh
SIMMLSTLATEX=$NOWEBDIR/output/simmlst.latex.sh
SIMMLSTSH=$NOWEBDIR/output/simmlst.sh

function simmlst {
  notangle -Rsimmlst.sh $SIMMLSTNW > $SIMMLSTSH
}



#####################################################################
# Main part of the script.
#####################################################################
PS3="Select what you want to do with the noweb of mauve-analysis: "
CHOICES=( simmlst )
select CHOICE in ${CHOICES[@]}; do 
  if [ "$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "$CHOICE" == "simmlst" ];  then
    simmlst
    break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

