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

function choose-simulation {
  PS3="Choose the simulation for clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      echo -e "  Creating simulation directories output..."
      mkdir-simulation $SPECIES
      echo -e "done"

      SPECIESFILE=species/$SPECIES
      echo "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      
      echo -e "  Creating directories of $HOW_MANY_REPETITION repetitions..."

      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        mkdir-simulation-repeat $SPECIES $REPETITION
      done

      echo -e "Execute simulate-data!"
      break
    fi
  done
}

# Creates a species directory in the output directory.
# ----------------------------------------------------
# The argument is the name of species or analysis. You can find them in the
# subdirectory called species.
function mkdir-simulation {
  echo -n "  Creating a simulation $1 at $OUTPUTDIR ..."
  echo -e " done"
  mkdir $OUTPUTDIR/$1
  mkdir $OUTPUTDIR/$1/run-analysis
  return 0

  echo -n "  Creating a simulation $1 at $CAC_OUTPUTDIR in $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir $CAC_OUTPUTDIR/$1
  echo -e " done"
  echo -n "  Creating a simulation $1 at $X11_OUTPUTDIR in $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir $X11_OUTPUTDIR/$1
  echo -e " done"
}

# Creates directories in each repeat directory.
# ---------------------------------------------
# The first argument is the species name, and the second is the repeat number.
# Both of them are required.
function mkdir-simulation-repeat {
  BASEDIR=$OUTPUTDIR/$1/$2
  DATADIR=$BASEDIR/data
  RUNMAUVE=$BASEDIR/run-mauve
  RUNCLONALFRAME=$BASEDIR/run-clonalframe
  RUNCLONALORIGIN=$BASEDIR/run-clonalorigin
  RUNANALYSIS=$BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $BASEDIR ..."
  mkdir $BASEDIR \
        $DATADIR \
        $RUNMAUVE \
        $RUNCLONALFRAME \
        $RUNCLONALORIGIN \
        $RUNANALYSIS
  echo -e " done"
  return 0

  CAC_BASEDIR=$CAC_OUTPUTDIR/$1/$2
  CAC_DATADIR=$CAC_BASEDIR/data
  CAC_RUNMAUVE=$CAC_BASEDIR/run-mauve
  CAC_RUNCLONALFRAME=$CAC_BASEDIR/run-clonalframe
  CAC_RUNCLONALORIGIN=$CAC_BASEDIR/run-clonalorigin
  CAC_RUNANALYSIS=$CAC_BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $CAC_BASEDIR ... of $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR \
                             $CAC_DATADIR \
                             $CAC_RUNMAUVE \
                             $CAC_RUNCLONALFRAME \
                             $CAC_RUNCLONALORIGIN \
                             $CAC_RUNANALYSIS
  echo -e " done"
  X11_BASEDIR=$X11_OUTPUTDIR/$1/$2
  X11_DATADIR=$X11_BASEDIR/data
  X11_RUNMAUVE=$X11_BASEDIR/run-mauve
  X11_RUNCLONALFRAME=$X11_BASEDIR/run-clonalframe
  X11_RUNCLONALORIGIN=$X11_BASEDIR/run-clonalorigin
  X11_RUNANALYSIS=$X11_BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $X11_BASEDIR ... of $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir $X11_BASEDIR \
                             $X11_DATADIR \
                             $X11_RUNMAUVE \
                             $X11_RUNCLONALFRAME \
                             $X11_RUNCLONALORIGIN \
                             $X11_RUNANALYSIS
  echo -e " done"
}

