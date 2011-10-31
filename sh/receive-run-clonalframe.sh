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

function receive-run-clonalframe {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e "  Receiving clonalframe-output..."
      set-more-global-variable $SPECIES $REPETITION
      CFREPLICATE=$(grep ^REPETITION${REPETITION}-CF-REPLICATE species/$SPECIES | cut -d":" -f2)
      CFOUTDIR=$RUNCLONALFRAME/output/$CFREPLICATE
      if [ -d $CFOUTDIR ]; then
        echo "$CFOUTDIR exists!"
        echo "Delete $CFOUTDIR or specify other clonal frame replicate ID!"
      else
        mkdir -p $RUNCLONALFRAME/output/$CFREPLICATE
        scp -q $CAC_USERHOST:$CAC_RUNCLONALFRAME/output/* $RUNCLONALFRAME/output/$CFREPLICATE/
        echo -e "  Sending clonalframe-output to swiftgen..."
        ssh -x $X11_USERHOST \
          mkdir -p $CAC_RUNCLONALFRAME/output/$CFREPLICATE
        scp $RUNCLONALFRAME/output/$CFREPLICATE/* \
          $X11_USERHOST:$X11_RUNCLONALFRAME
        echo -e "Now, prepare clonalorigin.\n"
      fi
      break
    fi
  done
}

