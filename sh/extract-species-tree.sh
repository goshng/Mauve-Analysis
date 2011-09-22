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

function extract-species-tree {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -n "What replicate do you wish to use? (e.g., 1) "
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION
      perl pl/$FUNCNAME.pl \
        -xml $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1 \
        -out $RUNANALYSIS/species-tree-$REPLICATE.tree
      echo "Check $RUNANALYSIS/species-tree-$REPLICATE.tree"
      break
    fi
  done
}
