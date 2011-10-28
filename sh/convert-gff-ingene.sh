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
# Date  : Fri May  6 20:34:17 EDT 2011

function convert-gff-ingene {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      GFF=$(grep REPETITION${REPETITION}-GFF $SPECIESFILE | cut -d":" -f2)
      OUT=$RUNANALYSIS/in.gene
      echo "Coverting $GFF to $OUT ..."
      perl pl/$FUNCNAME.pl \
        -gff $GFF \
        -out $OUT
      perl pl/$FUNCNAME.pl \
        -gff $GFF \
        -withdescription \
        -out $OUT.description
      echo "File $OUT is created!"
      break
    fi
  done
}
