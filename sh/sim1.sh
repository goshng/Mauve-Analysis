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

function sim1 {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ]; then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      OUTPUTBASE=output/$SPECIES
      BASEDIR=$OUTPUTDIR/$SPECIES
      BASERUNANALYSIS=$BASEDIR/run-analysis
      THETA_PER_SITE=$(grep ThetaPerSite $SPECIESFILE | cut -d":" -f2)
      RHO_PER_SITE=$(grep RhoPerSite $SPECIESFILE | cut -d":" -f2)
      DELTA=$(grep Delta $SPECIESFILE | cut -d":" -f2)
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      HOW_MANY_REPLICATE=$(grep Replicate $SPECIESFILE | cut -d":" -f2)
      NREPLICATE=$HOW_MANY_REPLICATE
      TREE=$(grep SpeicesTree $SPECIESFILE | cut -d":" -f2)
      INBLOCK=$(grep InBlock $SPECIESFILE | cut -d":" -f2)
      NUMBER_BLOCK=$(trim $(echo `cat data/$INBLOCK|wc -l`))
      CACWORKDIR=$(grep ^CACWORKDIR $SPECIESFILE | cut -d":" -f2)

      echo -n "Do you wish to simulate data using recombinant trees (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then

        echo "  Simulating Jukes-Canto model for creating XMFA files ..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$BASEDIR/$g/data
          rm -rf $DATADIR
          mkdir -p $DATADIR
          $WARGSIM --cmd-sim-given-tree \
            --tree-file data/$TREE \
            --block-file data/$INBLOCK \
            --out-file $DATADIR/core_alignment \
            --number-data $HOW_MANY_REPLICATE \
            -T s$THETA_PER_SITE -R s$RHO_PER_SITE -D $DELTA
          echo -ne "Repetition $g\r"
        done

        echo "  Splitting the single XMFA file ..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$BASEDIR/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            rm -f $DATADIR/core_alignment.$h.xmfa.*
            if [ -e $DATADIR/core_alignment.$h.xmfa ]; then
              perl pl/blocksplit.pl $DATADIR/core_alignment.$h.xmfa
            else
              echo "No such file $DATADIR/core_alignment.$h.xmfa"
            fi
          done
          echo -ne "Repetition $g\r"
        done

        echo "  Checking if there are weird characters that not A, C, G, or T in data ..."
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
            DATADIR=$BASEDIR/$g/data
            for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
              XMFA=$DATADIR/core_alignment.$h.xmfa.$b
              perl pl/checkxmfa.pl $XMFA
            done
          done
          echo -ne "Block $b\r"
        done

        echo "  Creating a jobidfile ..."
        JOBIDFILE=$BASEDIR/jobidfile
        rm -f $JOBIDFILE
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=output/$SPECIES/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            for b in $(eval echo {1..$NUMBER_BLOCK}); do
              XMFA=$DATADIR/core_alignment.$h.xmfa.$b
              XML=output/$SPECIES/$g/run-clonalorigin/output/$h/core_co.phase2.xml.$b
              echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
                -x $BURNIN -y $CHAINLENGTH -z $THIN \
                $TREE $XMFA $XML >> $JOBIDFILE
            done
          done
        done

        ssh -x $CAC_USERHOST mkdir -p $CACWORKDIR/output
        scp -qr $BASEDIR cac:$CACWORKDIR/output
        scp -q $JOBIDFILE cac:$CACWORKDIR
        scp -q cac/sim/batch_task2.sh cac:$CACWORKDIR/batchjob.sh
        scp -q cac/sim/run2.sh cac:$CACWORKDIR/run.sh
        scp -q data/$TREE cac:$CACWORKDIR

cat>$BASEDIR/batch.sh<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-$SPECIES
#PBS -q ${QUEUENAME}
#PBS -m e
# #PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

# The full path of the clonal origin executable.
WARG=\$HOME/usr/bin/warg
BASEDIR=output/$SPECIES

function copy-data {
  cd \$TMPDIR
  cp \$WARG .
  cp \$PBS_O_WORKDIR/batchjob.sh .
  cp -r \$PBS_O_WORKDIR/output .
  cp \$PBS_O_WORKDIR/$SPECIESTREE .

  # Create the status directory.
  mkdir -p \$PBS_O_WORKDIR/status/\$PBS_ARRAYID

  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=\$BASEDIR/\$g
    CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
    for h in \$(eval echo {1..$NREPLICATE}); do
      mkdir -p \$CLONALORIGINDIR/output/\$h
      mkdir -p \$PBS_O_WORKDIR/\$CLONALORIGINDIR/output/\$h
    done
  done
}

function retrieve-data {

  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=\$BASEDIR/\$g
    CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
    for h in \$(eval echo {1..$NREPLICATE}); do
      cp \$CLONALORIGINDIR/output/\$h/* \$PBS_O_WORKDIR/\$CLONALORIGINDIR/output/\$h
    done
  done

  # Remove the status directory.
  rm -rf \$PBS_O_WORKDIR/status/\$PBS_ARRAYID
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batchjob.sh \\
      \$i \\
      \$PBS_O_WORKDIR/jobidfile \\
      \$PBS_O_WORKDIR/lockfile \\
      \$PBS_O_WORKDIR/status/\$PBS_ARRAYID \\
      PBSARRAYSIZE&
  done
}

copy-data
process-data; wait
retrieve-data
cd \$PBS_O_WORKDIR
rm -rf \$TMPDIR
EOF
      scp -q $BASEDIR/batch.sh cac:$CACWORKDIR

      echo -e "Go to cac:$CACWORKDIR"
      echo -e "Submit a job using a different command."
      echo -e "$ bash run.sh"

      else
        echo -e "  Skipping generating data ..." 
      fi

      echo -n "Do you wish to get the output result files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$OUTPUTBASE/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            mkdir -p $OUTPUTBASE/$g/run-clonalorigin/output/$h
            for b in $(eval echo {1..$NUMBER_BLOCK}); do
              XML=$OUTPUTBASE/$g/run-clonalorigin/output/$h/core_co.phase2.xml.$b
              scp -q cac:$CACWORKDIR/$XML $XML
            done
            echo -ne "block $g - $h\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping copying output result files ..." 
      fi

      echo -n "Do you wish to extract mu, delta, rho (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        mkdir -p $BASEDIR/run-analysis
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

          # Files that we need to compare.
          for b in $(eval echo {1..$NUMBER_BLOCK}); do
            ECOP="pl/extractClonalOriginParameter5.pl \
              -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.$b \
              -withblocksize \
              -out $BASEDIR/run-analysis/out"
            FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.$b)
            if [[ "$FINISHED" =~ "outputFile" ]]; then
              if [ "$g" == 1 ] && [ "$b" == 1 ]; then
                ECOP="$ECOP -nonewline"
                #echo perl $ECOP
                #continue
              else
                if [ "$b" == $NUMBER_BLOCK ]; then
                  ECOP="$ECOP -firsttab -append"
                elif [ "$b" != 1 ]; then
                  ECOP="$ECOP -firsttab -nonewline -append" 
                elif [ "$b" == 1 ]; then
                  ECOP="$ECOP -nonewline -append" 
                else
                  echo "Not possible block $b"
                  exit
                fi
              fi
              perl $ECOP
              echo -ne "$g/$HOW_MANY_REPETITION $b/$NUMBER_BLOCK done\r"
            else
              LENGTHBLOCK=$(perl pl/compute-block-length.pl \
                -base $DATADIR/core_alignment.$REPLICATE.xmfa \
                -block $b)
              echo "NOTYETFINISHED $g $b $LENGTHBLOCK" >> 1
            fi
          done
        done

        NUMBER_SAMPLE=$(echo `grep number $BASEDIR/1/run-clonalorigin/output/1/core_co.phase2.xml.1|wc -l`)
        perl pl/simulate-data-clonalorigin1-analyze.pl \
          -in $BASEDIR/run-analysis/out \
          -numbersample $NUMBER_SAMPLE \
          -out $BASEDIR/run-analysis/out.summary
        echo "See $BASEDIR/run-analysis/out.summary"
      else
        echo "Skipping extracting mu, delta, rho"
      fi
      echo "  done in reading!"

      break
    fi
  done
}

