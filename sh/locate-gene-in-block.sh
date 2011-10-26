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
# Date  : Fri May  6 23:14:34 EDT 2011

function locate-gene-in-block {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      INGENE=$RUNANALYSIS/in.gene
      COREALIGNMENT=$(grep ^COREALIGNMENT conf/README | cut -d":" -f2)
      REFGENOME=$(grep ^REPETITION${REPETITION}-REFGENOME $SPECIESFILE | cut -d":" -f2)
      FNA=$(grep ^REPETITION${REPETITION}-FNA $SPECIESFILE | cut -d":" -f2)

      echo -n "Do you wish to locate genes of $INGENE in the $REFGENOME ...? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/$FUNCNAME.pl \
          locate \
          -fna $FNA \
          -ingene $INGENE \
          -xmfa $DATADIR/$COREALIGNMENT \
          -refgenome $REFGENOME \
          -printseq \
          -out $INGENE.$REFGENOME.block
      echo "File $INGENE.$REFGENOME.block is created from $INGENE"
      else
        echo "  Skipping locating genes of $INGENE in the $REFGENOME ..."
      fi

      echo -n "Do you wish to find virulence genes from virulence gene list? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/virulence.pl \
          subset \
          -virulence output/virulence/virulent_genes.txt \
          -out output/virulence/virulent_genes.txt.spy1
      echo "File $INGENE.$REFGENOME.block is created from $INGENE"
      else
        echo "  Skipping locating genes of $INGENE in the $REFGENOME ..."
      fi

      echo -n "Do you wish to subset virulence genes? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        perl pl/virulence.pl \
          extract \
          -in $INGENE.$REFGENOME.block \
          -gene output/virulence/virulent_genes.txt.spy1 \
          -out $RUNANALYSIS/in.virulence.gene.$REFGENOME.block
      echo "File $INGENE.$REFGENOME.block is created from $INGENE"
      else
        echo "  Skipping subsetting genes of $INGENE in the $REFGENOME ..."
      fi

      break
    fi
  done
}

