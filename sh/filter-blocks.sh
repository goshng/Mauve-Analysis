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

function filter-blocks {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      MINLEN=$(grep ^REPETITION${REPETITION}-LCB-MINLEN species/$SPECIES | cut -d":" -f2)
      GAPTHRESHOULD=$(grep ^REPETITION${REPETITION}-BLOCK-GAP-THRESHOULD species/$SPECIES | cut -d":" -f2)
      echo "Minimum length of block is $MINLEN" 
      echo "Gap Threshould is $GAPTHRESHOULD" 
      set-more-global-variable $SPECIES $REPETITION
      echo "  Finding core blocks of the alignment..."

      # mkdir-tmp 
      run-lcb $MINLEN
      # rmdir-tmp

      echo -n 'Do you wish to remove blocks with gaps? (y/n) '
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -n "The number of blocks was: "
        perl pl/remove-blocks-from-core-alignment.pl count \
          -threshould $GAPTHRESHOULD \
          -in $DATADIR/core_alignment.xmfa.org
        perl pl/remove-blocks-from-core-alignment.pl remove \
          -threshould $GAPTHRESHOULD \
          -in $DATADIR/core_alignment.xmfa.org \
          -out $DATADIR/core_alignment.xmfa
        echo -n "The number of blocks is now: "
        perl pl/remove-blocks-from-core-alignment.pl count \
          -threshould $GAPTHRESHOULD \
          -in $DATADIR/core_alignment.xmfa
        echo "  A new $DATADIR/core_alignment.xmfa is generated."
        echo "Now, prepare clonalframe analysis."
      else
        mv $DATADIR/core_alignment.xmfa.org $DATADIR/core_alignment.xmfa
      fi
      echo -e "The core blocks might have weird alignment."
      echo -e "Now, edit core blocks of the alignment."
      echo -e "This is the core alignment: $DATADIR/core_alignment.xmfa"
      break
    fi
  done
}

function run-lcb {
  MINIMUM_LENGTH=$1
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $RUNMAUVEOUTPUTDIR/full_alignment.xmfa \
    $RUNMAUVEOUTPUTDIR/full_alignment.xmfa.bbcols \
    $DATADIR/core_alignment.xmfa.org $MINIMUM_LENGTH
}

function mkdir-tmp {
  mkdir -p $TEMPINPUTDIR
  read-species-genbank-files data/$SPECIES mkdir-tmp
}

function rmdir-tmp {
  rm -rf $TEMPDIR
}
