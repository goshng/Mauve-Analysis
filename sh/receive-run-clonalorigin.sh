###############################################################################
# Copyright (C) 2011, 2012 Sang Chul Choi
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

function receive-run-clonalorigin {
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

      CFREPLICATE=$(grep ^REPETITION${REPETITION}-CF-REPLICATE species/$SPECIES | cut -d":" -f2)
      CFID=$(grep ^REPETITION${REPETITION}-CO1-CFID $SPECIESFILE | cut -d":" -f2)
      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO1-NREPLICATE species/$SPECIES | cut -d":" -f2)
      WALLTIME=$(grep ^REPETITION${REPETITION}-CO1-WALLTIME species/$SPECIES | cut -d":" -f2)
      COIBURNIN=$(grep ^REPETITION${REPETITION}-CO1-BURNIN $SPECIESFILE | cut -d":" -f2)
      COICHAINLENGTH=$(grep ^REPETITION${REPETITION}-CO1-CHAINLENGTH $SPECIESFILE | cut -d":" -f2)
      COITHIN=$(grep ^REPETITION${REPETITION}-CO1-THIN $SPECIESFILE | cut -d":" -f2)
      SAMPLESIZE=$((COICHAINLENGTH/COITHIN + 1))


      for h in $(eval echo {1..$NREPLICATE}); do
        mkdir -p $RUNCLONALORIGIN/summary/${h}
      done

      echo -n "Do you wish to receive the ClonalOrigin's 1st stage MCMC? (y/n) " 
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Receiving 1st stage of clonalorigin-output..."
        for h in $(eval echo {1..$NREPLICATE}); do
          mkdir -p $RUNCLONALORIGIN/output/${h}
          scp -q $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output/${h}/* \
            $RUNCLONALORIGIN/output/${h}/
        done
      else
        echo "  Skipping copy of the output files because I've already copied them ..."
      fi

      echo -n "Do you wish to find unfinished blocks in the ClonalOrigin's 1st stage MCMC? (y/n) " 
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Finding unfinished blocks ..."
        for h in $(eval echo {1..$NREPLICATE}); do
          perl pl/report-clonalorigin-job.pl \
            -samplesize $SAMPLESIZE \
            -xmlbase $RUNCLONALORIGIN/output/$h/core_co.phase2.xml \
            -database $DATADIR/core_alignment.xmfa \
            > $RUNCLONALORIGIN/summary/${h}/unfinished
        done
      else
        echo "  Skipping copy of the output files because I've already copied them ..."
      fi

      echo -n "Do you wish to compute the three global parameter estimates? (y/n) " 
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          echo -e "  Computing the global medians of theta, rho, and delta ... for replicate # $h"
          perl pl/computeMedians.pl \
            $RUNCLONALORIGIN/output/${h}/core_co.phase2.xml.* \
            | grep ^Median > $RUNCLONALORIGIN/summary/${h}/median.txt
          echo -e "This is the summary of the first stage of clonal origin run:"
          cat $RUNCLONALORIGIN/summary/${h}/median.txt
          echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
        done
      else
        echo "  Skipping computing the global parameter estimate..."
      fi
      break
    fi
  done
}

