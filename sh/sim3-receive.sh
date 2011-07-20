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

function sim3-receive {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      CAC_BASEDIR=$CAC_OUTPUTDIR/$SPECIES
      echo -n "What kinds of recombinant edges do you want to receive? "
      PAIRM=topology 

      echo "Receiving $SPECIES ri simulation..."
      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        mkdir $BASEDIR/$REPETITION/run-clonalorigin/output2/$PAIRM
        for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          scp -rq $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/output2/ri-$REPLICATE \
            $BASEDIR/$REPETITION/run-clonalorigin/output2/$PAIRM
          echo -ne "$REPETITION/$HOW_MANY_REPETITION - $REPLICATE/$HOW_MANY_REPLICATE\r"
        done
      done
      break
    fi 
  done
}

