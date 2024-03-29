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
# Date  : Thu May  5 13:45:53 EDT 2011

function sim3-analyze {
  PS3="Choose the species to do $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s14" ] \
         || [ "$SPECIES" == "s16" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species

      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      PAIRM=topology

      echo -n "Do you wish to generate the true XML? (e.g., y/n) "
      read WANT
      if [ "$WANT" == "y" ]; then
        echo "Generating true XML..."

        PROCESSEDTIME=0
        TOTALITEM=$(( $HOW_MANY_REPETITION * $NUMBER_BLOCK ));
        ITEM=0
        for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
          RITRUE=$BASEDIR/$REPETITION/run-analysis/ri-yes-$PAIRM
          mkdir -p $RITRUE
          for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
            STARTTIME=$(date +%s)
            perl pl/sim3-prepare.pl \
              -pairm $PAIRM \
              -xml $BASEDIR/$REPETITION/data/core_alignment.xml.$BLOCKID \
              -ingene $BASERUNANALYSIS/in.gene.4.block \
              -blockid $BLOCKID \
              -out $RITRUE/$BLOCKID
            ENDTIME=$(date +%s)
            ITEM=$(( $ITEM + 1 ))
            ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
            PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
            REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
            REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
            echo -ne "$REPETITION/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK - more $REMAINEDTIME min to go\r"
          done
        done
        echo "Find files at $BASEDIR/REPETITION#/run-analysis/ri-yes-$PAIRM"
      else
        echo "Skipping generating true XML..."
      fi

      echo "Generating a table for plotting..."
      OUTFILE=$BASERUNANALYSIS/ri-$PAIRM.txt
      for REPETITION in $(eval echo {1..$HOW_MANY_REPETITION}); do
        RITRUE=$BASEDIR/$REPETITION/run-analysis/ri-yes-$PAIRM
        for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
          PERLCOMMAND="perl pl/$FUNCNAME.pl \
            -true $RITRUE/$BLOCKID \
            -estimate $BASEDIR/$REPETITION/run-clonalorigin/output2/$PAIRM/ri \
            -numberreplicate $HOW_MANY_REPLICATE \
            -samplesize $SAMPLESIZE \
            -block $BLOCKID \
            -ingene $BASERUNANALYSIS/in.gene.4.block \
            -out $OUTFILE"
          if [ "$REPETITION" != 1 ] || [ "$BLOCKID" != 1 ]; then
            PERLCOMMAND="$PERLCOMMAND -append"
          fi
          $PERLCOMMAND
          echo -ne "$REPETITION/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK\r"
        done
      done
      echo "Check $OUTFILE"

      RTEMP=$RANDOM.R
      EPSFILE=$BASERUNANALYSIS/ri.eps
      ROUT=$BASERUNANALYSIS/ri.out
      RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
x <- read.table ("$OUTFILE")
postscript("$EPSFILE", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(5, 4, 0.5, 0.5))
plot (x\$V2, x\$V3, xlim=c(0,9), ylim=c(0,9),cex=0.2, xlab="True value of recombination intensity", ylab="Estimates",main="")
abline(a=0,b=1,lty=2)
par(oldpar)
dev.off()
cor(x\$V2,x\$V3)
EOF
      Rscript $RTEMP >> $ROUT
      rm $RTEMP
      echo "Check $ROUT"

    fi
    break
  done
}
