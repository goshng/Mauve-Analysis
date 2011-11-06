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

function recombination-count {
  PS3="Choose the species for $FUNCNAME: "
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
      NUMBER_SPECIES=$(echo `grep gbk data/$SPECIES|wc -l`)
      echo -e "The number of blocks is $NUMBER_BLOCK."
      echo -e "The number of species is $NUMBER_SPECIES."
      echo "NUMBER_BLOCK and NUMBER_SAMPLE must be checked"

      echo -n "Do you wish to count recombination events across blocks (or obsiter) (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          perl pl/count-observed-recedge.pl obsiter \
            -d $RUNCLONALORIGIN/output2/${h} \
            -n $NUMBER_BLOCK \
            -out $RUNANALYSIS/obsiter-recedge-$h.txt &
        done
        wait
        echo "Check $NREPLICATE files $RUNANALYSIS/obsiter-recedge-#.txt"
      fi

      echo -n "Do you wish to count recombination events (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          perl pl/count-observed-recedge.pl obsonly \
            -d $RUNCLONALORIGIN/output2/${h} \
            -n $NUMBER_BLOCK \
            -endblockid \
            -obsonly \
            -out $RUNANALYSIS/obsonly-recedge-$h.txt &
        done
        wait
        echo "Check $NREPLICATE files $RUNANALYSIS/obsonly-recedge-#.txt"
      fi

      echo -n "Do you wish to compute the prior expected number of recombination events (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        CO2REPLICATE=$(grep ^REPETITION${REPETITION}-CA1-CO2ID species/$SPECIES | cut -d":" -f2)
        h=$CO2REPLICATE
        PRIORCOUNTDIR=$RUNCLONALORIGIN/output2/priorcount
        mkdir $PRIORCOUNTDIR
        rm 3
        JOBIDFILE=$RUNCLONALORIGIN/rc.jobidfile
        rm -f $JOBIDFILE
        for i in $(eval echo {1..$NUMBER_BLOCK}); do
          # echo "$RUNCLONALORIGIN/output2/${h}/core_co.phase3.xml.$i"
          if [ -f "$RUNCLONALORIGIN/output2/${h}/core_co.phase3.xml.$i" ]; then
            echo "src/warggui/b/gui \
              $RUNCLONALORIGIN/output2/$h/core_co.phase3.xml.$i \
              > $PRIORCOUNTDIR/$i.txt" >> 3 
#           $GUI -b \
#             -o $RUNCLONALORIGIN/output2/${h}/core_co.phase3.xml.$i \
#             -H 3 \
#             > $PRIORCOUNTDIR/$i.txt
          else
            echo "Block: $i was not found" 1>&2
          fi
          echo -ne "  Block: $i\r";
        done 

      fi

      echo -n "Do you wish to compute heatmaps (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          PRIORCOUNTDIR=$RUNCLONALORIGIN/output2/priorcount-2-original
          perl pl/count-observed-recedge.pl heatmap \
            -d $RUNCLONALORIGIN/output2/${h} \
            -e $PRIORCOUNTDIR \
            -endblockid \
            -n $NUMBER_BLOCK \
            -out $RUNANALYSIS/heatmap-recedge-${h}.txt &
            # -s $NUMBER_SPECIES \
        done
        wait
      fi

      echo -n "Do you wish to count recombination events only for the SPY and SDE (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          perl pl/count-observed-recedge.pl obsonly \
            -d $RUNCLONALORIGIN/output2/${h} \
            -n $NUMBER_BLOCK \
            -endblockid \
            -lowertime 0.045556 \
            -out $RUNANALYSIS/obsonly-recedge-time-$h.txt
          echo "Check file $RUNANALYSIS/obsonly-recedge-time-$h.txt"
        done
      fi

      break
    fi
  done
}


