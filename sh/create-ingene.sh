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
# Date  : Thu May  5 16:05:45 EDT 2011

function create-ingene {
  PS3="Choose the simulation for $FUNCNAME: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      read-species
      echo -n "What is the length of a genome? "
      read GENOMELENGTH
      echo -n "What is the equal length of a gene? "
      read GENELENGTH
      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      perl pl/create-ingene.pl \
        -genelength $GENELENGTH \
        -genomelength $GENOMELENGTH \
        > $BASERUNANALYSIS/in.gene
      echo "File $BASERUNANALYSIS/in.gene is created!"
      break
    fi
  done
}


