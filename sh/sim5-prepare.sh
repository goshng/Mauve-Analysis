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

function sim5-prepare {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s17" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      NUMBER_BLOCK=$(grep NUMBER_BLOCK $SPECIESFILE | cut -d":" -f2)
      NUMBER_REPLICATE=$(grep NUMBER_REPLICATE $SPECIESFILE | cut -d":" -f2)
      THETA_PER_SITE=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      XMLBASEDIR=$(grep XMLBASEDIR $SPECIESFILE | cut -d":" -f2)
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
      TREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)


      echo -n "Do you wish to simulate data using recombinant trees (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Simulating data using recombinant trees..."

        # mkdir -p $RUNCLONALORIGIN/output2/ri-$REPLICATE-out

        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
            DATADIR=$BASEDIR/$REPETITION/data
            g=$(($REPETITION * 10 + 1))
            BLOCKSIZE=$(echo `perl pl/get-block-length.pl $XMLBASEDIR/core_co.phase3.xml.$b.$g`) 

            $WARGSIM --cmd-sim-given-rectree \
              --xml-file $XMLBASEDIR/core_co.phase3.xml.$b.$g \
              --block-length $BLOCKSIZE \
              --out-file $DATADIR/core_alignment.$b.$g \
              --number-data $HOW_MANY_REPLICATE \
              -T s$THETA_PER_SITE

            echo -ne "block $b - $g\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping generating local trees..." 
      fi

      echo -n "Do you wish to create jobidfile for submission (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Simulating data using recombinant trees..."

        JOBIDFILE=$BASEDIR/jobidfile
        rm -f $JOBIDFILE

        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
            DATADIR=output/s17/$REPETITION/data
            g=$(($REPETITION * 10 + 1))
            for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
              XMFA=$DATADIR/core_alignment.$b.$g.$REPLICATE.xmfa
              XML=output/s17/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$b
              echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
                -x $BURNIN -y $CHAINLENGTH -z $THIN \
                -T s$THETA_PER_SITE -D $DELTA \
                -R s$RHO_PER_SITE $TREE $XMFA $XML >> $JOBIDFILE
            done
            echo -ne "block $b - $g\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping creating jobidfile ..." 
      fi

      echo -n "Do you wish to get the output result files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
            DATADIR=output/s17/$REPETITION/data
            g=$(($REPETITION * 10 + 1))
            for REPLICATE in $(eval echo {1..$HOW_MANY_REPLICATE}); do
              mkdir -p output/s17/$REPETITION/run-clonalorigin/output2/$REPLICATE
              XML=output/s17/$REPETITION/run-clonalorigin/output2/$REPLICATE/core_co.phase3.xml.$b
              scp -q cac:run/mauve/100311/$XML $XML
            done
            echo -ne "block $b - $g\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping creating jobidfile ..." 
      fi

      break
    fi
  done
}
