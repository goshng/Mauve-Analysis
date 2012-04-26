###############################################################################
# Copyright (C) 2011-2012 Sang Chul Choi
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

function compute-heatmap-recedge {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in ${SPECIESS[@]}; do
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      set-more-global-variable $SPECIES $REPETITION
      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO2-NREPLICATE species/$SPECIES | cut -d":" -f2)

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      NUMBER_SPECIES=$(echo `grep ^GBK $SPECIESFILE|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo -e "The number of species is $NUMBER_SPECIES."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"
      # for h in $(eval echo {1..$NREPLICATE}); do
        perl pl/count-observed-recedge.pl exponly \
          -d $RUNCLONALORIGIN/output2/1 \
          -e $RUNCLONALORIGIN/output2/priorcount \
          -n $NUMBER_BLOCK \
          -out $RUNANALYSIS/exponly-recedge.txt
      # done
      break

      perl pl/count-observed-recedge.pl heatmap \
        -d $RUNCLONALORIGIN/output2/${REPLICATE} \
        -e $RUNCLONALORIGIN/output2/priorcount-${REPLICATE} \
        -endblockid \
        -n $NUMBER_BLOCK \
        -s $NUMBER_SPECIES \
        > $RUNANALYSIS/heatmap-recedge-${REPLICATE}.txt
      echo "Check file $RUNANALYSIS/heatmap-recedge-${REPLICATE}.txt"
      break
    fi
  done
}
