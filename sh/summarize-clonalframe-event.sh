###############################################################################
# Copyright (C) 2012 Sang Chul Choi
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

function summarize-clonalframe-event {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      set-more-global-variable $SPECIES $REPETITION
      CFID=$(grep ^REPETITION${REPETITION}-CO1-CFID species/$SPECIES | cut -d":" -f2)

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      NUMBER_SPECIES=$(echo `grep ^GBK $SPECIESFILE|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo -e "The number of species is $NUMBER_SPECIES."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"
      # for h in $(eval echo {1..$NREPLICATE}); do
      echo perl pl/summarize-clonalframe-event.pl import \
        -node 1 \
        -in $RUNCLONALFRAME/output/core_clonalframe.out.$CFID \
        -out $RUNANALYSIS/clonalframe-event.txt
      # done
      break
    fi
  done
}
