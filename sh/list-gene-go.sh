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
# Date  : Wed Jun  8 09:48:51 EDT 2011

function list-gene-go {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      set-more-global-variable $SPECIES $REPETITION
      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO2-NREPLICATE species/$SPECIES | cut -d":" -f2)

      NREPLICATE=1
      for h in $(eval echo {1..$NREPLICATE}); do
        Rscript R/mannwhitney.R $RUNANALYSIS $h \
          > $RUNANALYSIS/mannwhitney-$h.R.out
      done
      echo "Check output/cornellf/3/run-analysis/mannwhitney_results.txt"
      echo "Check output/cornellf/3/run-analysis/significant.txt"

      break


      INGENE=$RUNANALYSIS/in.gene
      COREALIGNMENT=$(grep COREALIGNMENT conf/README | cut -d":" -f2)
      REFGENOME=$(grep REPETITION${REPETITION}-REFGENOME $SPECIESFILE | cut -d":" -f2)

      # Put these in the config or cornellf
      if [ "$SPECIES" != "cornellf" ]; then
        echo "SPECIES must be cornellf"
        break
      fi

      echo -n "What is the gene ontology term (use double quotations if spaces are needed)? (e.g., \"rRNA binding\") "
      read GODESC

      DESC2GO=data/SpyMGAS315_go_category_names.txt
      GO2GENE=data/SpyMGAS315_go_bacteria.txt
      GENE2PRODUCT=data/NC_004070.gbk

      echo "Locating genes of $INGENE in the $REFGENOME ..."
      echo perl pl/list-gene-go.pl \
        -godesc $GODESC \
        -desc2go $DESC2GO \
        -go2gene $GO2GENE \
        -gene2product $GENE2PRODUCT 
      break
    fi
  done
}


