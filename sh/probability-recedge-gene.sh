###############################################################################
# Copyright (C) 2011 Sang Chul Choi
#
# This file is part of Mauve Analysis.
# 
# Mauve Analysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mauve Analysis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mauve Analysis.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
# Author: Sang Chul Choi
# Date  : Wed Jun  8 15:31:42 EDT 2011

function probability-recedge-gene {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) " 
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      echo -e "  The number of blocks is $NUMBER_BLOCK."

      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1|wc -l`)
      echo -e "  The posterior sample size is $NUMBER_SAMPLE."

      echo -n "  Reading TREETOPOLOGY of REPETITION$REPETITION from $SPECIESFILE..."
      TREETOPOLOGY=$(grep REPETITION$REPETITION-TREETOPOLOGY $SPECIESFILE | cut -d":" -f2)
      echo " $TREETOPOLOGY"

      echo -n "  Reading of REFGENOME of REPETITION$REPETITION from $SPECIESFILE..."
      REFGENOME=$(grep REPETITION$REPETITION-REFGENOME $SPECIESFILE | cut -d":" -f2)
      echo " $REFGENOME"

      echo -n "  Reading of GENBANK of REPETITION$REPETITION from $SPECIESFILE..."
      GENBANK=$(grep REPETITION$REPETITION-GENBANK $SPECIESFILE | cut -d":" -f2)
      echo " $GENBANK"

      echo -n "Do you wish to search for genes with high recombination probability (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME.pl \
          -ri1map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -genbank $GENOMEDATADIR/$GENBANK \
          -out $RUNANALYSIS/$FUNCNAME.txt
        echo "Check file $RUNANALYSIS/$FUNCNAME.txt"
      else
        echo -e "  Nothing is done with $FUNCNAME ..." 
      fi
      break
    fi
  done
}

