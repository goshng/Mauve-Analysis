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

function receive-run-2nd-clonalorigin {
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

      echo -n "Do you wish to receive the ClonalOrigin's 2nd stage MCMC? (y/n) " 
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Receiving 2nd stage of clonalorigin-output..."
        for h in $(eval echo {1..$NREPLICATE}); do
          # mkdir -p $RUNCLONALORIGIN/output2/${h}
          # Even if a numbered directory exists, the copy will be done.
          scp -qr $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output2/${h} \
            $RUNCLONALORIGIN/output2
        done
      else
        echo "  Skipping copy of the output2 files because I've already copied them ..."
      fi

      SAMPLESIZE=$(grep ^REPETITION${REPETITION}-CO2-SAMPLESIZE species/$SPECIES | cut -d":" -f2)
      echo -n "Do you wish to find unfinished blocks in the ClonalOrigin's 2nd stage MCMC? (y/n) " 
      read WISH
      if [ "$WISH" == "y" ]; then
        echo -e "  Finding unfinished blocks ..."
        for h in $(eval echo {1..$NREPLICATE}); do
          mkdir $RUNCLONALORIGIN/summary/${h}
          perl pl/report-clonalorigin-job.pl \
            -xmlbase $RUNCLONALORIGIN/output2/$h/core_co.phase3.xml \
            -database $DATADIR/core_alignment.xmfa \
            -samplesize $SAMPLESIZE \
            > $RUNCLONALORIGIN/summary/${h}/unfinished2
        done
      else
        echo "  Skipping copy of the output files because I've already copied them ..."
      fi
      echo -e "Now, do more analysis with mauve.\n"

      break
    fi
  done
}

# The following is very old version.
# if all of my results are consistent between independent runs.
function receive-run-2nd-clonalorigin-backup {
  PS3="Choose the species to analyze with mauve, clonalframe, and clonalorigin: "
  select SPECIES in `ls species`; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      g=$REPETITION
      echo -n "Which replicate set of output files? (e.g., 1) "
      read REPLICATE
      echo -e 'What is the temporary id of mauve-analysis?'
      echo -e "You may find it in the $SPECIES/run-mauve/output/full_alignment.xmfa"
      echo -n "JOB ID: " 
      read JOBID
      set-more-global-variable $SPECIES $REPETITION
      echo -e "  Making temporary data files...."
      mkdir-tmp 


      echo -n 'Have you already downloaded and do you want to skip the downloading? (y/n) '
      read WANTSKIPDOWNLOAD
      if [ "$WANTSKIPDOWNLOAD" == "y" ]; then
        echo "  Skipping copy of the output files because I've already copied them ..."
      else
        echo -e "  Receiving 2nd stage of clonalorigin-output..."
        mkdir -p $RUNCLONALORIGIN/output2/${REPLICATE}
        scp -q $CAC_USERHOST:$CAC_RUNCLONALORIGIN/output2/${REPLICATE}/* \
          $RUNCLONALORIGIN/output2/${REPLICATE}/
      fi
      echo -e "  Zipping output2"
      for f in $RUNCLONALORIGIN/output2/${REPLICATE}/*phase*; do
        bzip2 $f
      done

      # Directory is needed: /tmp/1074429.scheduler.v4linux/input/SdeqATCC12394.gbk
      echo -n "  Doing AUI ..."
      DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
        $AUI $DATADIR/core_alignment.xmfa $DATADIR/core_alignment_mauveable.xmfa
      echo -e " done!" 
      echo -n "  Doing MWF ..."
      perl pl/makeMauveWargFile.pl $RUNCLONALORIGIN/output2/${REPLICATE}/*phase3*.bz2
      echo -e " done!"
      rmdir-tmp
      echo -e "  Unzipping output2"
      for f in $RUNCLONALORIGIN/output2/${REPLICATE}/*phase*; do
        bunzip2 $f
      done
      echo -e "Now, do more analysis with mauve.\n"
      break
    fi
  done
}

