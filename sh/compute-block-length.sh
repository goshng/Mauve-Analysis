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

# Computes lengths of blocks.
# ---------------------------
# The run-lcb contains a list of core_alignment.xmfa.[NUMBER] files.
function compute-block-length {
  PS3="Choose the species to compute block lengths: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      perl pl/compute-block-length.pl \
        -base=$DATADIR/core_alignment.xmfa \
        > data/$SPECIES-$REPETITION-in.block
      cp data/$SPECIES-$REPETITION-in.block $RUNANALYSIS/in.block
      echo "Check data/$SPECIES-$REPETITION-in.block"
      break
    fi
  done
}
