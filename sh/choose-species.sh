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
function choose-species {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION

      echo -n "Do you wish to create $NUMBERDIR and its subdirectories at the local machine (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        mkdir $BASEDIR \
              $BASERUNANALYSIS \
              $NUMBERDIR \
              $DATADIR \
              $RUNMAUVE \
              $RUNCLONALFRAME \
              $RUNCLONALORIGIN \
              $RUNANALYSIS
      else
        echo -e "  Skipped creating $NUMDIR and its subdirectories" 
      fi

      echo -n "Do you wish to create $CAC_NUMBERDIR and its subdirectories at the cluster (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR \
                                   $CAC_NUMBERDIR \
                                   $CAC_DATADIR \
                                   $CAC_RUNMAUVE \
                                   $CAC_RUNCLONALFRAME \
                                   $CAC_RUNCLONALORIGIN \
                                   $CAC_RUNANALYSIS
      else
        echo -e "  Skipped creating $CAC_NUMBERDIR and its subdirectories" 
      fi


      echo -n "Do you wish to create $X11_NUMBERDIR and its subdirectories at X11 (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
      ssh -x $X11_USERHOST mkdir $X11_BASEDIR \
                                 $X11_NUMBERDIR \
                                 $X11_DATADIR \
                                 $X11_RUNMAUVE \
                                 $X11_RUNCLONALFRAME \
                                 $X11_RUNCLONALORIGIN \
                                 $X11_RUNANALYSIS
      else
        echo -e "  Skipped creating $X11_NUMBERDIR and its subdirectories" 
      fi
      break
    fi
  done
}
