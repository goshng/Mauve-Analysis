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
# 6. Prepare the first stage of clonalorigin.
# -------------------------------------------
# A few variables need explanation before describing the first stage of
# ClonalOrigin.
# CLONALFRAMEREPLICATE: multiple replicates of clonal frame are possible.
# RUNID: multiple runs in each replicate of clonal frame run are available.
# Choose clonal frame replicate first, and then run identifier later. This
# combination represents a species tree using the core alignment blocks.
# REPLICATE: multiple replicates of clonal origin are avaiable. I also need to
# check the convergence before proceeding with the second stage of clonal
# origin. 
# I used split core alignments into blocks. I did it for estimating Watterson's
# estimate. Each block was in FASTA format. I modified the perl script,
# blocksplit.pl, to generate FASTA formatted files. I just use blocksplit.pl to
# split the core alignments into blocks that ClonalOrigin can read in. I delete
# all the core alignment blocks that were generated before, and recreate them so
# that I let ClonalOrigin read its expected formatted blocks.
#
function prepare-run-clonalorigin {
  PS3="Choose the species to analyze with clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -e "Which replicate set of ClonalFrame output files?"
      echo -n "ClonalFrame REPLICATE ID: " 
      read CLONALFRAMEREPLICATE
      echo -e "Which replicate set of ClonalOrigin output files?"
      echo -n "ClonalOrigin REPLICATE ID: " 
      read REPLICATE
      echo -e "Preparing clonal origin analysis..."
      set-more-global-variable $SPECIES $REPETITION

      REFGENOME=$(grep REPETITION${REPETITION}-REFGENOME $SPECIESFILE | cut -d":" -f2)

      echo -n "  Reading WALLTIME from $SPECIESFILE..."
      WALLTIME=$(grep REPETITION${REPETITION}-Walltime $SPECIESFILE | cut -d":" -f2)
      echo " $WALLTIME"

      echo -n "  Reading WALLTIME from $SPECIESFILE..."
      BURNIN=$(grep REPETITION${REPETITION}-Burnin $SPECIESFILE | cut -d":" -f2)
      echo " $BURNIN"

      echo -n "  Reading WALLTIME from $SPECIESFILE..."
      CHAINLENGTH=$(grep REPETITION${REPETITION}-ChainLength $SPECIESFILE | cut -d":" -f2)
      echo " $CHAINLENGTH"

      echo -n "  Reading WALLTIME from $SPECIESFILE..."
      THIN=$(grep REPETITION${REPETITION}-Thin $SPECIESFILE | cut -d":" -f2)
      echo " $THIN"

      echo -n "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      echo " $HOW_MANY_REPETITION"

      echo -e "  Creating an input directory for a species tree..."
      mkdir -p $RUNCLONALORIGIN/input/${REPLICATE}
      echo -e "  Creating an output directory for the 1st stage of ClonalOrigin..." 
      mkdir $RUNCLONALORIGIN/output
      echo -e "  Creating an output directory for the 2nd stage of ClonalOrigin..." 
      mkdir $RUNCLONALORIGIN/output2
      echo -e "  Creating an input directory in the cluster..."
      CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
      ssh -x $CAC_USERHOST \
        mkdir -p $CAC_RUNCLONALORIGIN/input/${REPLICATE}

      echo -n "Which clonal frame is used for a phylogeny? (e.g., 1) "
      read RUNID
      SPECIESTREE=clonaltree.nwk
      perl pl/getClonalTree.pl \
        $RUNCLONALFRAME/output/${CLONALFRAMEREPLICATE}/core_clonalframe.out.${RUNID} \
        $RUNCLONALORIGIN/input/${REPLICATE}/$SPECIESTREE
      echo -e "  Splitting alignment into one file per block..."
      CORE_ALIGNMENT=core_alignment.xmfa
      rm $DATADIR/core_alignment.xmfa.*
      perl pl/blocksplit.pl $DATADIR/$CORE_ALIGNMENT

      echo "  Copying the split alignments..."
      scp -q $DATADIR/$CORE_ALIGNMENT.* \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/data

      echo "  Copying the input species tree..."
      scp -q $RUNCLONALORIGIN/input/${REPLICATE}/$SPECIESTREE \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$g/run-clonalorigin/input/${REPLICATE}

      # Some script.
      echo "  Creating job files..."
      make-run-list-repeat $g \
        $OUTPUTDIR/$SPECIES \
        $REPLICATE \
        $SPECIESTREE \
        > $RUNCLONALORIGIN/jobidfile
      scp -q $OUTPUTDIR/$SPECIES/$g/run-clonalorigin/jobidfile \
        $CAC_USERHOST:$CAC_OUTPUTDIR/$SPECIES/$g/run-clonalorigin

      copy-batch-sh-run-clonalorigin $g \
        $OUTPUTDIR/$SPECIES \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES \
        $SPECIES \
        $SPECIESTREE \
        $REPLICATE
      echo -e "Go to CAC's output/$SPECIES run-clonalorigin"
      echo -e "Submit a job using a different command."
      echo -e "$ bash batch.sh 3 to use three computing nodes"
      echo -e "Check the output if there are jobs that take longer"
      echo -e "tail -n 1 output/*> 1"
      echo -e "Create a file named remain.txt with block IDs, and then run"
      echo -e "$ bash batch_remain.sh 3"
      echo -e "The number of computing nodes is larger than the number of"
      echo -e "remaining jobs divided by 8"
      break
    fi
  done
}

