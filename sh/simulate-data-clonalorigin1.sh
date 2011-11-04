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

function simulate-data-clonalorigin1 {
  PS3="Choose a simulation (e.g., s15): "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      for g in $(eval echo {1..$HOW_MANY_REPETITION}); do 
        BASEDIR=$OUTPUTDIR/$SPECIES
        NUMBERDIR=$BASEDIR/$g
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        DATADIR=$NUMBERDIR/data
        mkdir -p $DATADIR
        mkdir -p $RUNCLONALORIGIN/input/$REPLICATE
        cp data/$SPECIESTREE $RUNCLONALORIGIN/input/$REPLICATE
        cp data/$INBLOCK $DATADIR

        echo -ne "  Simulating data under the ClonalOrigin model ..." 
        $WARGSIM --cmd-sim-given-tree \
          --tree-file $RUNCLONALORIGIN/input/$REPLICATE/$SPECIESTREE \
          --block-file $DATADIR/$INBLOCK \
          --out-file $DATADIR/core_alignment \
          -T s$THETA_PER_SITE -D $DELTA -R s$RHO_PER_SITE

        perl pl/extractClonalOriginParameter9.pl \
          -xml $DATADIR/core_alignment.xml

        for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
          CORE_ALIGNMENT=core_alignment.$h.xmfa
          rm -f $DATADIR/$CORE_ALIGNMENT.*
          perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT
        done

        echo -ne " done - repetition $g/$HOW_MANY_REPETITION\r"
      done
      break
    fi
  done
}
