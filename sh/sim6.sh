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

function sim6 {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s18" ]; then 
      read-species

      OUTPUTBASE=output/$SPECIES
      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      NUMBER_BLOCK=$(grep NUMBER_BLOCK $SPECIESFILE | cut -d":" -f2)
      NUMBER_REPLICATE=$(grep NUMBER_REPLICATE $SPECIESFILE | cut -d":" -f2)
      THETA_PER_SITE=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      RHO_PER_SITE=$(grep RhoPerSite $SPECIESFILE | cut -d":" -f2)
      DELTA=$(grep Delta $SPECIESFILE | cut -d":" -f2)
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
      TREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      XMLBASEDIR=$(grep XMLBASEDIR $SPECIESFILE | cut -d":" -f2)

      echo -n "Do you wish to simulate data using recombinant trees (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Simulating data using recombinant trees..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$BASEDIR/$g/data
          rm -rf $DATADIR
          mkdir -p $DATADIR
          $WARGSIM --cmd-sim-given-tree \
            --tree-file data/$TREE \
            --block-file data/$INBLOCK \
            --out-file $DATADIR/core_alignment.$g \
            --number-data $HOW_MANY_REPLICATE \
            -T s$THETA_PER_SITE -R s$RHO_PER_SITE -D $DELTA
          echo -ne "Repetition $g\r"
        done
      else
        echo -e "  Skipping generating data ..." 
      fi

      echo -n "Do you wish to split the single XMFA file (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Splitting the single XMFA file ..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$BASEDIR/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            rm -f $DATADIR/core_alignment.$g.$h.xmfa.*
            if [ -e $DATADIR/core_alignment.$g.$h.xmfa ]; then
              perl pl/blocksplit.pl $DATADIR/core_alignment.$g.$h.xmfa
            else
              echo "No such file $DATADIR/core_alignment.$g.$h.xmfa"
            fi
          done
          echo -ne "Repetition $g\r"
        done
      else
        echo -e "  Skipping splitting single XMFA files ..." 
      fi

      echo -n "Do you wish to check the simulate data for gap characters (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Checking data using recombinant trees..."

        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
            DATADIR=$BASEDIR/$g/data
            for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
              XMFA=$DATADIR/core_alignment.$g.$h.xmfa.$b
              perl pl/checkxmfa.pl $XMFA
            done
          done
        done
      else
        echo -e "  Skipping checking the simulated data files ..." 
      fi

      echo -n "Do you wish to create jobidfile for submission (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Creating the jobidfile ..."
        JOBIDFILE=$BASEDIR/jobidfile
        rm -f $JOBIDFILE
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=output/$SPECIES/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            for b in $(eval echo {1..$NUMBER_BLOCK}); do
              XMFA=$DATADIR/core_alignment.$g.$h.xmfa.$b
              XML=output/$SPECIES/$g/run-clonalorigin/output2/$h/core_co.phase3.xml.$b
              echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
                -x $BURNIN -y $CHAINLENGTH -z $THIN \
                -T s$THETA_PER_SITE -D $DELTA \
                -R s$RHO_PER_SITE $TREE $XMFA $XML >> $JOBIDFILE
            done
          done
        done
      else
        echo -e "  Skipping creating jobidfile ..." 
      fi

      # g for REPETITION
      # h for REPLICATE
      # b for BLOCK
      echo -n "Do you wish to get the output result files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$OUTPUTBASE/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            mkdir -p $OUTPUTBASE/$g/run-clonalorigin/output2/$h
            for b in $(eval echo {1..$NUMBER_BLOCK}); do
              XML=$OUTPUTBASE/$g/run-clonalorigin/output2/$h/core_co.phase3.xml.$b
              scp -q cac:run/mauve/102411/$XML $XML
            done
            echo -ne "block $g - $h\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping copying output2 result files ..." 
      fi

      echo -n "Do you wish to count recombinant edges (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          RUNCLONALORIGIN=$BASEDIR/$g/run-clonalorigin
          RUNANALYSIS=$BASEDIR/$g/run-analysis
          mkdir $RUNANALYSIS
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            perl pl/count-observed-recedge.pl obsonly \
              -d $RUNCLONALORIGIN/output2/${h} \
              -n $NUMBER_BLOCK \
              -endblockid \
              -obsonly \
              -out $RUNANALYSIS/obsonly-recedge-$h.txt
          done
          echo -ne "Repetition $g\r"
        done
      else
        echo -e "  Skipping counting recombinant edges ..." 
      fi

      echo -n "Do you wish to combine all of the obsonly-recedge (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        BASERUNANALYSIS=$BASEDIR/run-analysis
        mkdir $BASERUNANALYSIS
        rm -f $BASERUNANALYSIS/obsonly-recedge.txt
        touch $BASERUNANALYSIS/obsonly-recedge.txt
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          RUNANALYSIS=$BASEDIR/$g/run-analysis
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            cat $RUNANALYSIS/obsonly-recedge-$h.txt \
              >> $BASERUNANALYSIS/obsonly-recedge.txt
          done
        done
        echo -e "Check $BASERUNANALYSIS/obsonly-recedge.txt"
        echo -e "Compare it with the real data analysis"
        echo -e "e.g., output/cornellf/3/run-analysis/obsonly-recedge-1.txt"
      fi

      break

      #######################################################
      # Now we can compare this with prior expected numbers.
      #######################################################

      echo -n "Do you wish to copy the recombinant trees to prior (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
          RUNCLONALORIGINOUTPUT=$BASEDIR/$REPETITION/run-clonalorigin/prior
          mkdir $RUNCLONALORIGINOUTPUT
          for b in $(eval echo {1..$NUMBER_BLOCK}); do
            DATADIR=$BASEDIR/$REPETITION/data
            g=$(($REPETITION * 10 + 1))
            cp $XMLBASEDIR/core_co.phase3.xml.$b.$g $RUNCLONALORIGINOUTPUT/core_co.phase3.xml.$b
          done
        done
        echo -e "See run-clonalorigin/prior"
      fi

      echo -n "Do you wish to count the prior recombinant trees (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        BASERUNANALYSIS=$BASEDIR/run-analysis
        rm -f $BASERUNANALYSIS/obsonly-recedge-prior.txt
        touch $BASERUNANALYSIS/obsonly-recedge-prior.txt
        for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
          RUNCLONALORIGIN=$BASEDIR/$REPETITION/run-clonalorigin
          RUNANALYSIS=$BASEDIR/$REPETITION/run-analysis

          perl pl/count-observed-recedge.pl obsonly \
            -d $RUNCLONALORIGIN/prior \
            -n $NUMBER_BLOCK \
            -endblockid \
            -obsonly \
            -out $RUNANALYSIS/obsonly-recedge-prior.txt

          cat $RUNANALYSIS/obsonly-recedge-prior.txt \
            >> $BASERUNANALYSIS/obsonly-recedge-prior.txt
          echo -ne "$REPETITION\r"
        done
      fi

      break
    fi
  done
}
