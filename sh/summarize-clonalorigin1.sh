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

function summarize-clonalorigin1 {
  PS3="Choose the species to analyze real data for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION

      echo -n "Which replicate set of output files? (e.g., 1) "
      read REPLICATE
      set-more-global-variable $SPECIES $REPETITION
      mkdir -p $RUNCLONALORIGIN/summary/${REPLICATE}

      echo "  Reporting status of jobs ..."
      UNFINISHED=$RUNCLONALORIGIN/summary/${REPLICATE}/unfinished
      perl pl/report-clonalorigin-job.pl \
        -xmlbase $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml \
        -database $DATADIR/core_alignment.xmfa \
        > $UNFINISHED
      echo "The following $UNFINISHED is"
      echo "----"
      cat $UNFINISHED
      echo "----"

      echo -e "  Computing the global medians of theta, rho, and delta ..."
      MEDIAN=$RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
      perl pl/computeMedians.pl \
        $RUNCLONALORIGIN/output/${REPLICATE}/core_co.phase2.xml.* \
        | grep ^Median > $MEDIAN
      echo -e "This is the summary of the first stage of clonal origin run:"
      echo "The following $MEDIAN is"
      echo "----"
      cat $MEDIAN
      echo "----"

      echo -e "Prepare 2nd run using prepare-run-2nd-clonalorigin menu!"
      break
    fi
  done
}

