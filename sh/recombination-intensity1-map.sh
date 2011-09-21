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

function recombination-intensity1-map {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) " 
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION

      NUMBER_BLOCK=$(trim $(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`))
      RIMAP=$RUNANALYSIS/rimap-$REPLICATE.txt
      echo -n "Do you wish to generate rimap-$REPLICATE.txt? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo perl pl/$FUNCNAME.pl \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -numberblock $NUMBER_BLOCK \
          -verbose \
          -out $RIMAP
      else
        echo "  Skipping generating $RIMAP"
      fi
      break
 
      # echo -e "  The number of blocks is $NUMBER_BLOCK."
      # echo "-------------------------------------"
      # cat data/$SPECIES
      # echo "-------------------------------------"
      # echo -n "What is the reference genome? (e.g., 1) " 
      # read REFGENOME
      # echo -n "What is the length of the reference genome? " 
      # read REFGENOMELENGTH

     
      echo -n "Do you wish to generate ri1-refgenome$REFGENOME-map.txt? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME.pl \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -refgenomelength $REFGENOMELENGTH \
          -numberblock $NUMBER_BLOCK \
          -verbose \
          > $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt
      else
        echo "  Skipping generating $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt"
      fi

      echo -n "Do you wish to generate ri1-refgenome$REFGENOME-map.wig? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME-wiggle.pl \
          -map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map.wig
        echo "  Generating $RUNANALYSIS/ri1-refgenome$REFGENOME.wig"
      else
        echo "  Skipping generating $RUNANALYSIS/ri1-refgenome$REFGENOME.wig"
      fi
      
      break
    fi
  done
}

