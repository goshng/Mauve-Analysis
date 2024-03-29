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
# Date  : Wed Apr 27 16:45:56 EDT 2011

function map-tree-topology {
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

      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      echo -e "  The number of blocks is $NUMBER_BLOCK."

      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1|wc -l`)
      echo -e "  The posterior sample size is $NUMBER_SAMPLE."

      echo -n "  Reading TREETOPOLOGY of REPETITION$REPETITION from $SPECIESFILE..."
      TREETOPOLOGY=$(grep REPETITION$REPETITION-TREETOPOLOGY $SPECIESFILE | cut -d":" -f2)
      echo " $TREETOPOLOGY"

      echo -n "Do you wish to split xml output (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -n "  Splitting clonalorigin xml output files..."
        for h in $(eval echo {1..$NREPLICATE}); do
          mkdir -p $RUNCLONALORIGIN/output2/ri-$h
          perl pl/splitCOXMLPerIteration.pl \
            -d $RUNCLONALORIGIN/output2/$h \
            -outdir $RUNCLONALORIGIN/output2/ri-$h \
            -numberblock $NUMBER_BLOCK \
            -endblockid &
        done
        wait
        echo " done."
      else
        echo "  Skipping splitting ClonalOrigin xml output files..."
      fi

      # Find the local gene trees along each of block alignments.
      # WARGSIM=src/clonalorigin/b/wargsim
      echo -n "Do you wish to generate local trees (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Generating local trees..." 
        for h in $(eval echo {2..$NREPLICATE}); do
          mkdir -p $RUNCLONALORIGIN/output2/ri-$h-out
          for b in $(eval echo {1..$NUMBER_BLOCK}); do
            for g in $(eval echo {1..$NUMBER_SAMPLE}); do
              BLOCKSIZE=$(echo `perl pl/get-block-length.pl $RUNCLONALORIGIN/output2/ri-$h/core_co.phase3.xml.$b.$g`) 
              $WARGSIM \
                --gene-tree \
                --xml-file $RUNCLONALORIGIN/output2/ri-$h/core_co.phase3.xml.$b.$g \
                --out-file $RUNCLONALORIGIN/output2/ri-$h-out/core_co.phase3.xml.$b.$g \
                --block-length $BLOCKSIZE
                #--cmd-extract-tree \
              echo -ne "block $b - $g\r"
            done
            echo -ne "                                           \r"
          done
        done
      else
        echo -e "  Skipping generating local trees..." 
      fi
      # Combine ri-2-out's files for a block.
      # Analyze those files with a perl script.

      echo -n "Do you wish to check topology map files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {2..$NREPLICATE}); do
          for b in $(eval echo {1..$NUMBER_BLOCK}); do
            for g in $(eval echo {1..$NUMBER_SAMPLE}); do
              BLOCKSIZE=$(echo `perl pl/get-block-length.pl $RUNCLONALORIGIN/output2/ri-$h/core_co.phase3.xml.$b.$g`) 
              NUM=$(wc $RUNCLONALORIGIN/output2/ri-$h-out/core_co.phase3.xml.$b.$g|awk {'print $2'})
              if [ "$NUM" != "$BLOCKSIZE" ]; then
                echo "$b $g not okay"
              fi
            done
            echo -en "Block $b\r"
          done
        done
      else
        echo -e "  Skipping checking topology map files ..." 
      fi 

      echo -n "Do you wish to combine topology map files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          echo -e "  Combining ri-$h-out ..." 
          mkdir -p $RUNCLONALORIGIN/output2/ri-$h-combined
          RIBLOCKFILES="" 
          for b in $(eval echo {1..$NUMBER_BLOCK}); do
            RIFILES=""
            RIBLOCKFILE="$RUNCLONALORIGIN/output2/ri-$h-combined/$b"
            for g in $(eval echo {1..$NUMBER_SAMPLE}); do
              RIFILES="$RIFILES $RUNCLONALORIGIN/output2/ri-$h-out/core_co.phase3.xml.$b.$g"
            done
            RIBLOCKFILES="$RIBLOCKFILES $RIBLOCKFILE"
            cat $RIFILES > $RIBLOCKFILE
            echo -en "Block $b\r"
          done
          #paste $RIBLOCKFILES > $RUNANALYSIS/$FUNCNAME-${h}.txt
          echo "Check files in $RUNCLONALORIGIN/output2/ri-$h-combined"
        done
      else
        echo -e "  Skipping combining topology map files ..." 
      fi

##################################################################################
# This is for having another measure of recombination intensity using gene
# tree topology. This turned out to be not interesting. I am not using it.
#      echo -n "Do you wish to count gene tree topology changes (y/n)? "
#      read WISH
#      if [ "$WISH" == "y" ]; then
#        for h in $(eval echo {1..$NREPLICATE}); do
#          perl pl/$FUNCNAME.pl \
#            -ricombined $RUNCLONALORIGIN/output2/ri-$-combined \
#            -ingene $RUNANALYSIS/in.gene \
#            -treetopology $TREETOPOLOGY \
#            -verbose
#        done
#        echo "Check file $RUNANALYSIS/in.gene"
#      else
#        echo -e "  Skipping counting number of gene tree topology changes..." 
#      fi
##################################################################################

      echo -n "Do you wish to summarize gene tree topologies (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          rm -f $RUNANALYSIS/ri-$h-combined.all
          for ricombined in `ls $RUNCLONALORIGIN/output2/ri-$h-combined/*`; do 
            awk '0 == NR % 100' $ricombined >> $RUNANALYSIS/ri-$h-combined.all
          done
          map-tree-topology-rscript $RUNANALYSIS/ri-$h-combined.all
          echo "Check file $RUNANALYSIS/ri-$h-combined.all"
        done
      else
        echo -e "  Skipping counting number of gene tree topology changes..." 
      fi

      break
    fi
  done
}

function map-tree-topology-rscript {
  S2OUT=$1
  BATCH_R=$1.R
cat>$BATCH_R<<EOF

x <- scan ("$S2OUT")

y <- unlist(lapply(split(x,f=x),length)) 

y.sorted <- sort(y, decreasing=T)

print(y.sorted)

y.sum <- sum(y)

y.sorted[1]/y.sum*100

y.sorted[2]/y.sum*100

y.sorted[3]/y.sum*100

EOF
  Rscript $BATCH_R > $BATCH_R.out 
  echo "Check file $BATCH_R.out"
}
