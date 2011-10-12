#!/bin/bash
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

###############################################################################
# Global variables.
###############################################################################
MAUVEANALYSISDIR=`pwd`
source sh/copyright.sh
source sh/conf.sh
source sh/read-species.sh
conf

CLONALFRAMEREPLICATE=1
REPLICATE=1
REPETITION=1

# Perl scripts
PERLGUIPERL=pl/findBlocksWithInsufficientConvergence.pl

SIMULATIONS=$(ls species|grep ^s)
SPECIESS=$(ls species|grep -v ^s)

source sh/utility.sh
source sh/hms.sh
source sh/set-more-global-variable.sh
source sh/mkdir-species.sh
source sh/read-species-file.sh 
source sh/clonalorigin-common.sh
source sh/trash.sh
source sh/progressbar.sh
source sh/init-file-system.sh
source sh/choose-simulation.sh 
source sh/choose-species.sh 
source sh/simulate-data-clonalorigin1-prepare.sh
source sh/simulate-data-clonalorigin1-receive.sh 
source sh/simulate-data-clonalorigin1-analyze.sh
source sh/receive-run-2nd-clonalorigin.sh
source sh/prepare-mauve-alignment.sh
source sh/scatter-plot-parameter.sh
source sh/plot-number-recombination-within-blocks.sh
source sh/compute-prior-count-recedge.sh
source sh/recombination-count.sh
source sh/compute-global-median.sh
source sh/simulate-data-clonalorigin2-prepare.sh 
source sh/sim2-analyze.sh 
source sh/divide-simulated-xml-data.sh
source sh/divide-simulated-xmfa-data.sh
source sh/simulate-data-clonalorigin2.sh
source sh/receive-run-clonalorigin.sh 
source sh/prepare-run-2nd-clonalorigin.sh
source sh/simulate-data-clonalorigin2-from-xml.sh
source sh/probability-recombination.sh
source sh/map-tree-topology.sh
source sh/compute-heatmap-recedge.sh
source sh/prepare-run-compute-heatmap-recedge.sh
source sh/analyze-run-clonalorigin2-simulation2.sh 
source sh/sim3-prepare.sh 
source sh/sim3-receive.sh 
source sh/sim3-analyze.sh 
source sh/sim5-prepare.sh 
source sh/create-ingene.sh
source sh/convert-gff-ingene.sh 
source sh/locate-gene-in-block.sh
source sh/list-gene-go.sh
source sh/clonalorigin2-simulation3.sh
source sh/sim4-prepare.sh
source sh/sim4-receive.sh
source sh/sim4-analyze.sh
source sh/sim4-each-block.sh
source sh/extract-species-tree.sh
source sh/compute-block-length.sh
source sh/simulate-data-clonalorigin1.sh
source sh/summarize-clonalorigin1.sh 
source sh/recombination-intensity1-map.sh 
source sh/recombination-intensity1-genes.sh 
source sh/recombination-intensity1-probability.sh 
source sh/probability-recedge-gene.sh
source sh/receive-mauve-alignment.sh
source sh/prepare-run-clonalframe.sh
source sh/receive-run-clonalframe.sh
source sh/filter-blocks.sh
source sh/prepare-run-clonalorigin.sh 
source sh/manuscript.sh
source sh/summary-core-alignment.sh
# source sh/ucsc-load-genome.sh
source sh/batch.sh

#####################################################################
# Main part of the script.
#####################################################################
short-notice
PS3="Select what you want to do with mauve-analysis: "
CHOICES=( init-file-system \
          choose-simulation \
          ---SIMULATION1---\
          simulate-data-clonalorigin1 \
          simulate-data-clonalorigin1-prepare \
          simulate-data-clonalorigin1-receive \
          simulate-data-clonalorigin1-analyze \
          ---SIMULATION2---\
          simulate-data-clonalorigin2 \
          simulate-data-clonalorigin2-prepare \
          sim2-receive \
          sim2-analyze \
          simulate-data-clonalorigin2-analyze \
          analyze-run-clonalorigin2-simulation \
          ---SIMULATION3---\
          analyze-run-clonalorigin2-simulation2 \
          sim3-prepare \
          sim3-receive \
          sim3-analyze \
          ---SIMULATION5---\
          sim5-prepare \
          # ---SIMULATION4---\
          # clonalorigin2-simulation3 \
          # sim4-prepare \
          # sim4-receive \
          # sim4-analyze \
          # sim4-each-block \
          # ---SIMULATION5---\
          # clonalorigin2-simulation4 \
          # ---SIMULATION5---\
          # simulate-data-clonalorigin2-from-xml \
          ---REAL-DATA-ALIGNMENT---\
          choose-species \
          prepare-mauve-alignment \
          copy-mauve-alignment \
          receive-mauve-alignment \
          ---REAL-DATA-CLONALFRAME---\
          filter-blocks \
          summary-core-alignment \
          prepare-run-clonalframe \
          receive-run-clonalframe \
          ---CLONALORIGIN1---\
          prepare-run-clonalorigin \
          receive-run-clonalorigin \
          ---THREE-PARAMETERS---\
          summarize-clonalorigin1 \
          scatter-plot-parameter \
          plot-number-recombination-within-blocks \
          ---CLONALORIGIN2---\
          prepare-run-2nd-clonalorigin \
          receive-run-2nd-clonalorigin \
          ---RECOMBINATION-COUNT---\
          recombination-count \
          # count-observed-recedge \
          # compute-prior-count-recedge \
          # compute-heatmap-recedge \
          # prepare-run-compute-heatmap-recedge \
          ---RECOMBINATION-INTENSITY---\
          recombination-intensity1-map \
          convert-gff-ingene \
          locate-gene-in-block \
          recombination-intensity1-genes \
          recombination-intensity1-probability \
          probability-recedge-gene \
          ---TREE-TOPOLOGY---\
          # recombination-intensity2-map \
          map-tree-topology \
          ---GENE-ANNOTATION---\
          list-gene-go \
          ---DELETE-THESE-MENU---\
          create-ingene \
          probability-recombination \
          ---UTILITIES---\
          compute-watterson-estimate-for-clonalframe \
          compute-block-length \
          compute-global-median \
          extract-species-tree \
          ---UCSC-GENOME-BROWSER---\
          ucsc-load-genome-not-yet-implemented \
          ---MANUSCRIPT---\
          batch \
          manuscript \
          warranty \
          copyright \
          quit )
select CHOICE in ${CHOICES[@]}; do 
  if [ "$CHOICE" == "" ];  then
    echo -e "You need to enter something\n"
    continue
  elif [ "$CHOICE" == "init-file-system" ]; then $CHOICE; break
  elif [ "$CHOICE" == "choose-simulation" ]; then $CHOICE; break
  elif [ "$CHOICE" == "copy-mauve-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-mauve-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "receive-mauve-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "filter-blocks" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-clonalframe" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-watterson-estimate-for-clonalframe" ]; then $CHOICE; break
  elif [ "$CHOICE" == "receive-run-clonalframe" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-clonalorigin" ]; then $CHOICE; break
  elif [ "$CHOICE" == "receive-run-clonalorigin" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-2nd-clonalorigin" ]; then $CHOICE; break
  elif [ "$CHOICE" == "receive-run-2nd-clonalorigin" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim2-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-block-length" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin2-from-xml" ]; then $CHOICE; break
  elif [ "$CHOICE" == "scatter-plot-parameter" ]; then $CHOICE; break
  elif [ "$CHOICE" == "plot-number-recombination-within-blocks" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-prior-count-recedge" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-count" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-global-median" ]; then $CHOICE; break
  elif [ "$CHOICE" == "divide-simulated-xml-data" ]; then $CHOICE; break
  elif [ "$CHOICE" == "divide-simulated-xmfa-data" ]; then $CHOICE; break
  elif [ "$CHOICE" == "probability-recombination" ]; then $CHOICE; break
  elif [ "$CHOICE" == "compute-heatmap-recedge" ]; then $CHOICE; break
  elif [ "$CHOICE" == "prepare-run-compute-heatmap-recedge" ]; then $CHOICE; break
  elif [ "$CHOICE" == "map-tree-topology" ]; then $CHOICE; break
  elif [ "$CHOICE" == "analyze-run-clonalorigin2-simulation2" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim3-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim3-receive" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim3-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim5-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "create-ingene" ]; then $CHOICE; break
  elif [ "$CHOICE" == "convert-gff-ingene" ]; then $CHOICE; break
  elif [ "$CHOICE" == "locate-gene-in-block" ]; then $CHOICE; break
  elif [ "$CHOICE" == "list-gene-go" ]; then $CHOICE; break
  elif [ "$CHOICE" == "clonalorigin2-simulation3" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-receive" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim4-each-block" ]; then $CHOICE; break
  elif [ "$CHOICE" == "extract-species-tree" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin2" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1-prepare" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1-receive" ]; then $CHOICE; break
  elif [ "$CHOICE" == "sim2-receive" ]; then
    simulate-data-clonalorigin1-receive Clonal2ndPhase
    break
  elif [ "$CHOICE" == "simulate-data-clonalorigin1-analyze" ]; then $CHOICE; break
  elif [ "$CHOICE" == "simulate-data-clonalorigin2-prepare" ];  then
    simulate-data-clonalorigin2-prepare Clonal2ndPhase
    break
  elif [ "$CHOICE" == "summarize-clonalorigin1" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-intensity1-genes" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-intensity1-probability" ]; then $CHOICE; break
  elif [ "$CHOICE" == "probability-recedge-gene" ]; then $CHOICE; break
  elif [ "$CHOICE" == "recombination-intensity1-map" ]; then $CHOICE; break
  elif [ "$CHOICE" == "batch" ]; then $CHOICE; break
  elif [ "$CHOICE" == "manuscript" ]; then $CHOICE; break
  elif [ "$CHOICE" == "ucsc-load-genome" ]; then $CHOICE; break
  elif [ "$CHOICE" == "summary-core-alignment" ]; then $CHOICE; break
  elif [ "$CHOICE" == "warranty" ]; then $CHOICE; break
  elif [ "$CHOICE" == "copyright" ]; then $CHOICE; break
  elif [ "$CHOICE" == "choose-species" ]; then $CHOICE; break
  elif [ "$CHOICE" == "quit" ]; then break
  else
    echo -e "You need to enter something\n"
    continue
  fi
done

