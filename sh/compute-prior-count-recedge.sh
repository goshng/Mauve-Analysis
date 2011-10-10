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
# Date  : Wed Apr 20 10:23:47 EDT 2011

function compute-prior-count-recedge {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of ClonalOrigin output2 files? (e.g., 1) "
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"

      PRIORCOUNTDIR=$RUNCLONALORIGIN/output2/priorcount-${REPLICATE}
      mkdir $PRIORCOUNTDIR

      echo "Computing heat map for the blocks ... "
      for i in $(eval echo {1..$NUMBER_BLOCK}); do
        if [ -f "$RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml.$i" ]; then
          # Compute prior expected number of recedges.
          $GUI -b \
            -o $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml.$i \
            -H 3 \
            > $PRIORCOUNTDIR/$i.txt
        else
          echo "Block: $i was not found" 1>&2
        fi
        echo -ne "  Block: $i\r";
      done 
      echo -ne "$i Block - Finished!\n";

      break
    fi
  done
}
