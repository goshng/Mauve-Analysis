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

function sim3 {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ]; then
      echo -e "You need to enter something\n"
      continue
    else
      read-species

      OUTPUTBASE=output/$SPECIES
      CBASEDIR=output/$SPECIES
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
              XML=output/$SPECIES/$g/run-clonalorigin/output2/$h/core_co.phase3.xml.$b
              echo ./warg -a 1,1,0.1,1,1,1,1,1,0,0,0 \
                -x $BURNIN -y $CHAINLENGTH -z $THIN \
                -T s$THETA_PER_SITE -D $DELTA \
                -R s$RHO_PER_SITE $TREE $XMFA $XML >> $JOBIDFILE
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
      mkdir -p \$CLONALORIGINDIR/output2/\$h
      mkdir -p \$PBS_O_WORKDIR/\$CLONALORIGINDIR/output2/\$h
    done
  done
}

function retrieve-data {

  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=\$BASEDIR/\$g
    CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
    for h in \$(eval echo {1..$NREPLICATE}); do
      cp \$CLONALORIGINDIR/output2/\$h/* \$PBS_O_WORKDIR/\$CLONALORIGINDIR/output2/\$h
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

      ######################################################################
      # Receive the result.
      echo -n "Do you wish to get the output result files (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          DATADIR=$OUTPUTBASE/$g/data
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            mkdir -p $OUTPUTBASE/$g/run-clonalorigin/output2/$h
            for b in $(eval echo {1..$NUMBER_BLOCK}); do
              XML=$OUTPUTBASE/$g/run-clonalorigin/output2/$h/core_co.phase3.xml.$b
              scp -q cac:$CACWORKDIR/$XML $XML
            done
            echo -ne "block $g - $h\r"
          done
          echo -ne "                                           \r"
        done
      else
        echo -e "  Skipping copying output result files ..." 
      fi

      ######################################################################
      # Analyze the result.
      BASERUNANALYSIS=$BASEDIR/run-analysis
      PAIRM=all # all notopology topology
      mkdir $BASERUNANALYSIS
      echo -n 'Do you wish to extract recombination intensity from the estimate? (y/n) '
      read WISH
      if [ "$WISH" == "y" ]; then

        ######################################################################
        # Receive the result.
        echo -n "Do you wish to get the output result ri files (y/n)? "
        read WISH
        if [ "$WISH" == "y" ]; then
          # for p in all topology notopology; do
          for p in all notopology; do
            for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
              echo scp -qr cac:$CACWORKDIR/$g/run-clonalorigin/output2/$p \
                $OUTPUTBASE/$g/run-clonalorigin/output2
              scp -qr cac:$CACWORKDIR/$g/run-clonalorigin/output2/$p \
                $OUTPUTBASE/$g/run-clonalorigin/output2
            done
          done
          break
        else
          echo -e "  Skipping copying output result files ..." 
        fi

        JOBIDFILE=jobidfile2
        rm -f $JOBIDFILE
        echo -n 'Do you wish to run a batch in the cluster? (y/n) '
        read WISH2
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          if [ "$WISH2" == "y" ]; then
            NUMBERDIR=$CBASEDIR/$g
          else
            NUMBERDIR=$BASEDIR/$g
          fi
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          for h in $(eval echo {1..$HOW_MANY_REPLICATE}); do
            mkdir -p $RUNCLONALORIGIN/output2/$PAIRM/ri-$h
            for b in $(eval echo {1..$NUMBER_BLOCK}); do
              for p in all topology notopology; do
                PAIRM=$p
                PERLCOMMAND="perl pl/sim3-prepare.pl \
                  -pairm $PAIRM \
                  -xml $RUNCLONALORIGIN/output2/$h/core_co.phase3.xml.$b \
                  -ingene data/in.gene.4.block \
                  -blockid $b \
                  -out $RUNCLONALORIGIN/output2/$PAIRM/ri-$h/$b"
                if [ "$WISH2" == "y" ]; then
                  echo $PERLCOMMAND >> $JOBIDFILE
                else
                  $PERLCOMMAND
                fi
              done
            done 
            echo -ne "Repeition $g - $h\r"
          done
        done

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
BASEDIR=output/$SPECIES

function copy-data {
  cd \$TMPDIR
  cp \$PBS_O_WORKDIR/batchjob.sh .
  cp -r \$PBS_O_WORKDIR/pl .
  cp -r \$PBS_O_WORKDIR/data .

  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=\$BASEDIR/\$g
    CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
    mkdir -p \$CLONALORIGINDIR/output2
    for h in \$(eval echo {1..$NREPLICATE}); do
      cp -r \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/\$h \\
        \$CLONALORIGINDIR/output2
      for p in all topology notopology; do
        mkdir -p \$CLONALORIGINDIR/output2/\$p/ri-\$h
      done 
    done
  done
}

function retrieve-data {
  for g in \$(eval echo {1..$HOW_MANY_REPETITION}); do
    NUMBERDIR=\$BASEDIR/\$g
    CLONALORIGINDIR=\$NUMBERDIR/run-clonalorigin
    for h in \$(eval echo {1..$NREPLICATE}); do
      for p in all topology notopology; do
        cp -r \$CLONALORIGINDIR/output2/\$p/ri-\$h \\
          \$PBS_O_WORKDIR/\$g/run-clonalorigin/output2/\$p
      done
    done
  done
}

function process-data {
  cd \$TMPDIR
  CORESPERNODE=8
  for (( i=1; i<=CORESPERNODE; i++))
  do
    bash batchjob.sh \\
      \$i \\
      \$PBS_O_WORKDIR/$JOBIDFILE \\
      \$PBS_O_WORKDIR/lockfile& 
  done
}

copy-data
process-data; wait
retrieve-data
cd \$PBS_O_WORKDIR
rm -rf \$TMPDIR
EOF
        ssh -x $CAC_USERHOST mkdir -p $CACWORKDIR/data
        scp -q $JOBIDFILE cac:$CACWORKDIR
        scp -q cac/sim/batch_task.sh cac:$CACWORKDIR/batchjob.sh
        scp -q data/in.gene.4.block cac:$CACWORKDIR/data
        scp -q cac/sim/run.sh cac:$CACWORKDIR/run.sh
        scp -qr pl cac:$CACWORKDIR
        scp -q $BASEDIR/batch.sh cac:$CACWORKDIR

      else
        echo "  Skipping extracting recombination intensity ..."
      fi

      echo -n 'Do you wish to divide true recombination? (y/n) '
      read WISH
      if [ "$WISH" == "y" ]; then
        echo "  Dividing the true value of recombination..."
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          perl pl/extractClonalOriginParameter9.pl \
            -xml $DATADIR/core_alignment.xml
        done
      else
        echo "  Skipping ..."
      fi 

      echo -n 'Do you wish to extract recombination intensity from the true recombinant tree? (y/n) '
      read WANT
      if [ "$WANT" == "y" ]; then
        echo "  Generating true XML..."
        PROCESSEDTIME=0
        TOTALITEM=$(( $HOW_MANY_REPETITION * $NUMBER_BLOCK ));
        ITEM=0
        for p in all notopology; do
          PAIRM=$p
          for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
            RITRUE=$BASEDIR/$g/run-analysis/ri-yes-$PAIRM
            mkdir -p $RITRUE
            for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
              STARTTIME=$(date +%s)
              perl pl/sim3-prepare.pl \
                -pairm $PAIRM \
                -xml $BASEDIR/$g/data/core_alignment.xml.$BLOCKID \
                -ingene data/in.gene.4.block \
                -blockid $BLOCKID \
                -out $RITRUE/$BLOCKID
              ENDTIME=$(date +%s)
              ITEM=$(( $ITEM + 1 ))
              ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
              PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
              REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
              REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
              echo -ne "$g/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK - more $REMAINEDTIME min to go\r"
            done
          done
          echo "Find files at $BASEDIR/REPETITION#/run-analysis/ri-yes-$PAIRM"
        done
      fi

      echo -n 'Do you wish to plot recombination intensity from the true recombinant tree? (y/n) '
      read WANT
      if [ "$WANT" == "y" ]; then
        NUMBER_SAMPLE=$(echo `grep number $BASEDIR/1/run-clonalorigin/output2/1/core_co.phase3.xml.1|wc -l`)
        # for p in all topology notopology; do
        for p in all notopology; do
          PAIRM=$p
          echo "Generating a table for plotting..."
          OUTFILE=$BASERUNANALYSIS/ri-$PAIRM.txt
          for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
            RITRUE=$BASEDIR/$g/run-analysis/ri-yes-$PAIRM
            for BLOCKID in $(eval echo {1..$NUMBER_BLOCK}); do
              PERLCOMMAND="perl pl/sim3-analyze.pl \
                -true $RITRUE/$BLOCKID \
                -estimate $BASEDIR/$g/run-clonalorigin/output2/$PAIRM/ri \
                -numberreplicate $HOW_MANY_REPLICATE \
                -samplesize $NUMBER_SAMPLE \
                -block $BLOCKID \
                -ingene data/in.gene.4.block \
                -out $OUTFILE"
              if [ "$g" != 1 ] || [ "$BLOCKID" != 1 ]; then
                PERLCOMMAND="$PERLCOMMAND -append"
              fi
              $PERLCOMMAND
              echo -ne "$g/$HOW_MANY_REPETITION - $BLOCKID/$NUMBER_BLOCK\r"
            done
          done
          echo "Check $OUTFILE"

          echo "  Plotting ..."
          RTEMP=$RANDOM.R
          EPSFILE=$BASERUNANALYSIS/ri-$PAIRM.ps
          ROUT=$BASERUNANALYSIS/ri-$PAIRM.out
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
        done
      else
        echo "Skipping analyzing true XML..."
      fi

      break
    fi
  done
}

