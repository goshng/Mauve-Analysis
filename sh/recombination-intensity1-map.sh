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
      set-more-global-variable $SPECIES $REPETITION
      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO2-NREPLICATE species/$SPECIES | cut -d":" -f2)
      NUMBER_BLOCK=$(trim $(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`))

      echo -n "Do you wish to generate rimap-#REPLICATE.txt? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$); do
          RIMAP=$RUNANALYSIS/rimap-$h.txt
          perl pl/$FUNCNAME.pl \
            -xml $RUNCLONALORIGIN/output2/${h}/core_co.phase3.xml \
            -xmfa $DATADIR/core_alignment.xmfa \
            -numberblock $NUMBER_BLOCK \
            -verbose \
            -out $RIMAP
        done
      else
        echo "  Skipping generating rimap files"
      fi
      break
 
      # echo -e "  The number of blocks is $NUMBER_BLOCK."
      # echo "-------------------------------------"
      # cat data/$SPECIES
      # echo "-------------------------------------"
      echo -n "Do you wish to generate ri1-refgenome$REFGENOME-map-$REPLICATE.txt? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -n "What is the reference genome? (e.g., 1) " 
        read REFGENOME
        GBKFILE=$(grep ^GBK$REFGENOME $SPECIESFILE | cut -d":" -f2)
        echo perl pl/$FUNCNAME.pl \
          -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
          -xmfa $DATADIR/core_alignment.xmfa \
          -refgenome $REFGENOME \
          -numberblock $NUMBER_BLOCK \
          -gbk $GBKFILE \
          -verbose \
          -out $RUNANALYSIS/ri1-refgenome$REFGENOME-map-$REPLICATE.txt
      else
        echo "  Skipping generating $RUNANALYSIS/ri1-refgenome$REFGENOME-map-$REPLICATE.txt"
      fi

      echo -n "Do you wish to generate ri1-refgenome$REFGENOME-map.wig? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -n "What is the reference genome? (e.g., 1) " 
        read REFGENOME
        echo perl pl/$FUNCNAME-wiggle.pl intensity \
          -prior 3.746 \
          -posteriorsize 1001 \
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

