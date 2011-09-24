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

function recombination-intensity1-probability {
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

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      echo -e "  The number of blocks is $NUMBER_BLOCK."

      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1|wc -l`)
      echo -e "  The posterior sample size is $NUMBER_SAMPLE."

      echo -n "  Reading TREETOPOLOGY of REPETITION$REPETITION from $SPECIESFILE..."
      TREETOPOLOGY=$(grep REPETITION$REPETITION-TREETOPOLOGY $SPECIESFILE | cut -d":" -f2)
      echo " $TREETOPOLOGY"

      echo -n "  Reading of REFGENOME of REPETITION$REPETITION from $SPECIESFILE..."
      REFGENOME=$(grep REPETITION$REPETITION-REFGENOME $SPECIESFILE | cut -d":" -f2)
      echo " $REFGENOME"

      echo -n "  Reading of GBKFILE of REPETITION$REPETITION from $SPECIESFILE..."
      GBKFILE=$(grep GBK$REFGENOME $SPECIESFILE | cut -d":" -f2)
      echo " $GBKFILE"

      echo -n "Do you wish to create wiggle files of recombination probability using blocks (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        mkdir $RUNANALYSIS/recombprob-$REPLICATE
        echo perl pl/$FUNCNAME.pl wiggle \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa2maf $DATADIR/core_alignment.maf \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -gbk $GBKFILE \
          -ri1map $RUNANALYSIS/rimap.txt \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RUNANALYSIS/recombprob-$REPLICATE > batch.sh
      else
        echo -e "  Skipping drawing recombination probability ..." 
      fi

      echo -n "Do you wish to draw a graph of recombination probability using blocks (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -n "Which block you wish to draw a graph of recombination probability (e.g., 254) ? "
        read BLOCKID
        perl pl/$FUNCNAME.pl ps \
          -block $BLOCKID \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -ri1map $RUNANALYSIS/rimap.txt \
          -ingene $RUNANALYSIS/in.gene.$REFGENOME.block \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RUNANALYSIS/rimap-$REFGENOME
        echo "Check file $RUNANALYSIS/rimap-$REFGENOME-*.eps"
      else
        echo -e "  Skipping drawing recombination probability ..." 
      fi
      break

      echo -n "(Old version: may not work)Do you wish to draw a graph of recombination probability (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo perl pl/$FUNCNAME.pl \
          -ri1map $RUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \
          -ingene $RUNANALYSIS/in.gene \
          -clonaloriginsamplesize $NUMBER_SAMPLE \
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map
        echo "Check file $RUNANALYSIS/ri1-refgenome$REFGENOME-map.gene"
      else
        echo -e "  Skipping counting number of gene tree topology changes..." 
      fi
      break
    fi
  done
}
