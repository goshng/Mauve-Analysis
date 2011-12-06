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

function ucsc-genome {
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
      NUMBERSPECIES=$(grep ^REPETITION$REPETITION-NumberSpecies $SPECIESFILE | cut -d":" -f2)
      CO2SAMPLESIZE=$(grep ^REPETITION$REPETITION-CO2-SAMPLESIZE $SPECIESFILE | cut -d":" -f2)
      NUMBERSPECIESMINUSONE=$((NUMBERSPECIES - 1))
      NUMBERBRANCH=$((NUMBERSPECIES * 2 - 1))
      NUMBERBRANCHMINUSONE=$((NUMBERSPECIES * 2 - 2))

      # See test/recombprob/batch.sh
      echo -n "Do you wish to create WIB and WIG? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
          mkdir $RUNANALYSIS/recombprobwig-$h
          for i in $(eval echo {1..$NUMBERSPECIES}); do
            # Create wiggle files by extracting columns.
            RECOMBPROB=$RUNANALYSIS/recombprob-$h-ref$i
            RECOMBPROBWIG=$RUNANALYSIS/recombprobwig-$h/$i
            for j in $(eval echo {0..$NUMBERBRANCHMINUSONE}); do
              for k in $(eval echo {0..$NUMBERBRANCHMINUSONE}); do
                WIGIN=$RECOMBPROBWIG/${j}-${k}
                WIGOUT=$RECOMBPROBWIG/${j}-${k}.n
                WIG=$RECOMBPROBWIG/${j}-${k}.wig
                WIB=$RECOMBPROBWIG/${j}-${k}.wib
                rm -f $WIG
                rm -f $WIB
                perl pl/snippet-wig-divide-sample-size.pl $CO2SAMPLESIZE $WIGIN $WIGOUT
                wigEncode $WIGOUT $WIG $WIB &
                # hgLoadWiggle $DBNAME ri_${j}_${k} $WIG
                # rm $WIG
                # mkdir -p /gbdb/$DBNAME/wib
                # mv $WIB /gbdb/$DBNAME/wib
                #hgsql $DBNAME -e "update ri_${j}_${k} set file='/gbdb/$DBNAME/wib/${j}-${k}.wib'"
              done
              wait
            done
          done
        done
      fi

      # Need to convert XMFA to MAF and edit it so that it can be loaded 
      # to a UCSC genome browser.
      echo -n "Do you wish to create MAF? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        XMFA=$DATADIR/core_alignment.xmfa
        MAF=$DATADIR/core_alignment.maf
        echo "Create the same directory structure for genome files in the following file"
        echo "  $XMFA"
        echo "e.g., mkdir -p /tmp/1081728.scheduler.v4linux/input"
        echo "Copy all of the genome files in the directory"
        TEMPINPUTDIR=/tmp/1081728.scheduler.v4linux/input
        mkdir -p $TEMPINPUTDIR
        for i in $(eval echo {1..$NUMBERSPECIES}); do
          GBKFILE=$(grep ^GBK$i\: $SPECIESFILE | cut -d":" -f2)
          cp $GBKFILE $TEMPINPUTDIR
        done
        xmfa2maf $XMFA $MAF
        rm -rf $TEMPINPUTDIR

        # Edit the MAF2 file more.
        MAF2=$MAF.sde1
        perl pl/xmfaToMaf.pl ucsc -xmfa2maf $MAF \
          -rename strDeq1.chr1,strDeq2.chr1,strDdy1.chr1,strPyg1.chr1,strPyg2.chr1 \
          -out $MAF2
        # hgLoadMaf strDeq1 maf -loadFile=$MAF2

        DBNAMECHOICES=(SdeqATCC12394 SdeqGGS124 SddyATCC27957 SpyMGAS315 SpyMGAS10750)
        REORDERCHOICES=("1,2,3,4,5" "2,1,3,4,5" "3,2,1,4,5" "4,2,3,1,5" "5,2,3,4,1")
        for i in $(eval echo {0..$NUMBERSPECIESMINUSONE}); do
          DBNAME=${DBNAMECHOICES[$i]}
          # DBMAF=/gbdb/$DBNAME/maf
          # mkdir -p $DBMAF
          # MAF=output/cornellf/3/data/core_alignment.maf
          iplusone=$((i + 1))
          MAF2=$MAF.$iplusone
          perl pl/xmfaToMaf.pl ucsc -xmfa2maf $MAF \
            -rename SdeqATCC12394,SdeqGGS124,SddyATCC27957,SpyMGAS315,SpyMGAS10750 \
            -reorder ${REORDERCHOICES[$i]} \
            -out $MAF2
          scp $MAF2 compgen:public_html/strep-recomb/
          #III hgLoadMaf $DBNAME maf -loadFile=$MAF2
        done
      fi

      echo "Load alignment and recombination probability to a UCSC genome browser."
      DBNAMECHOICES=(recSde1 recSde2 recSdd recSpy1 recSpy2)
      echo -n "Do you wish to copy gbk file to ucsc genome browser host? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        for i in $(eval echo {1..$NUMBERSPECIES}); do
          iminusone=$((i - 1))
          DBNAME=${DBNAMECHOICES[$iminusone]}
          GBKFILE=$(grep ^GBK$i\: $SPECIESFILE | cut -d":" -f2)
          scp $GBKFILE compgen:public_html/strep-recomb/$DBNAME.gbk
        done
      fi

cat>$NUMBERDIR/ucsc-matt.sh<<EOF
KENT=/usr/local/software/kent
# DBNAMECHOICES=(recSde1 recSde2 recSdd recSpy1 recSpy2)
DBNAMECHOICES=(SdeqATCC12394 SdeqGGS124 SddyATCC27957 SpyMGAS315 SpyMGAS10750)
SPECIESNAMES=(sde1 sde2 sdd spy1 spy2)

for i in \$(eval echo {1..$NUMBERSPECIES}); do
  idb=\$((i-1))
  DBNAME=\${DBNAMECHOICES[\$idb]}
  SPECIESNAME=\${SPECIESNAMES[\$idb]}
  hgsql \$DBNAME -e "drop table fam"
  echo hgLoadBed -bedDetail -renameSqlTable -trimSqlTable -tab -nobin -sqlTable=$KENT/src/hg/lib/bedDetail.sql \$DBNAME fam \$SPECIESNAME.bed
done
EOF

cat>$NUMBERDIR/ucsc.sh<<EOF
KENT=/usr/local/software/kent
# DBNAMECHOICES=(recSde1 recSde2 recSdd recSpy1 recSpy2)
DBNAMECHOICES=(SdeqATCC12394 SdeqGGS124 SddyATCC27957 SpyMGAS315 SpyMGAS10750)

h=1
for i in \$(eval echo {1..$NUMBERSPECIES}); do
  idb=\$((i-1))
  DBNAME=\${DBNAMECHOICES[\$idb]}
  # Create wiggle files by extracting columns.
  RECOMBPROBWIG=recombprobwig-\$h/\$i
  for j in \$(eval echo {0..$NUMBERBRANCHMINUSONE}); do
    for k in \$(eval echo {0..$NUMBERBRANCHMINUSONE}); do
      WIGIN=\$RECOMBPROBWIG/\${j}-\${k}
      WIG=\$RECOMBPROBWIG/\${j}-\${k}.wig
      WIB=\$RECOMBPROBWIG/\${j}-\${k}.wib

      # wigEncode $WIGIN $WIG $WIB
      hgsql \$DBNAME -e "drop table ri_\${j}_\${k}"
      hgLoadWiggle \$DBNAME ri_\${j}_\${k} \$WIG
      # rm $WIG
      mkdir -p /gbdb_cornell/\$DBNAME/wib
      cp \$WIB /gbdb_cornell/\$DBNAME/wib
      hgsql \$DBNAME -e "update ri_\${j}_\${k} set file='/gbdb_cornell/\$DBNAME/wib/\${j}-\${k}.wib'"
    done
  done
done

for i in \$(eval echo {1..$NUMBERSPECIES}); do
  idb=\$((i-1))
  DBNAME=\${DBNAMECHOICES[\$idb]}
  mkdir /gbdb_cornell/\$DBNAME/maf
  cp core_alignment.maf.\$i /gbdb_cornell/\$DBNAME/maf/core_alignment.maf
  MAF2=/gbdb_cornell/\$DBNAME/maf/core_alignment.maf
  hgLoadMaf \$DBNAME maf -loadFile=\$MAF2
done
exit

for i in \$(eval echo {0..$NUMBERSPECIESMINUSONE}); do
  DBNAME=\${DBNAMECHOICES[\$i]}
  gbToFaRa /dev/null \$DBNAME.fna \$DBNAME.ra \$DBNAME.ta \$DBNAME.gbk 
  toUpper \$DBNAME.fna \$DBNAME.fna.upper
  faSize \$DBNAME.fna.upper
  rm \$DBNAME.fna \$DBNAME.ra \$DBNAME.ta 
  echo ">chr1" > \$DBNAME.fna
  grep -v ">" \$DBNAME.fna.upper >> \$DBNAME.fna
  rm \$DBNAME.fna.upper

  hgFakeAgp -minContigGap=1 \$DBNAME.fna \$DBNAME.agp
  faToTwoBit \$DBNAME.fna \$DBNAME.2bit
  mkdir -p /gbdb_cornell/\$DBNAME/html
  cp \$DBNAME.2bit /gbdb_cornell/\$DBNAME

  echo "  creating a database ..."
  twoBitInfo \$DBNAME.2bit stdout | sort -k2nr > chrom.sizes
  rm -rf bed
  mkdir -p bed/chromInfo
  awk '{printf "%s\\t%d\\t/gbdb_cornell/DBNAME/DBNAME.2bit\\n", \$1, \$2}' \\
    chrom.sizes > bed/chromInfo/chromInfo.tab.tmp
  sed s/DBNAME/\$DBNAME/g < bed/chromInfo/chromInfo.tab.tmp > bed/chromInfo/chromInfo.tab
  hgsql -e "create database \$DBNAME;" mysql

  echo "  creating grp, chromInfo tables ..."
  hgsql \$DBNAME < \$KENT/src/hg/lib/grp.sql

  cp bed/chromInfo/chromInfo.tab /tmp/
  hgLoadSqlTab \$DBNAME chromInfo \$KENT/src/hg/lib/chromInfo.sql \\
    /tmp/chromInfo.tab
  rm /tmp/chromInfo.tab
  hgGoldGapGl \$DBNAME \$DBNAME.agp

  echo "  creating GC5 track ..."
  mkdir bed/gc5Base
  hgGcPercent -wigOut -doGaps -file=stdout -win=5 -verbose=0 \$DBNAME \\
    \$DBNAME.2bit | wigEncode stdin bed/gc5Base/gc5Base.{wig,wib}
  hgLoadWiggle -pathPrefix=/gbdb_cornell/\$DBNAME/wib \\
    \$DBNAME gc5Base bed/gc5Base/gc5Base.wig
  mkdir -p /gbdb_cornell/\$DBNAME/wib/bed/gc5Base
  cp bed/gc5Base/gc5Base.wib /gbdb_cornell/\$DBNAME/wib/bed/gc5Base
  rm -rf bed



done

EOF

cat<<EOF
1. Set up a UCSC genome browser or use one.
2. Decide database names for each species.
3. Copy $NUMBERDIR/ucsc.sh to UCSC genome browser host: 
   e.g., compgen:public_html/strep-recomb at Siepel Lab
4. bash ucsc.sh
5. svn co \$SVNROOT/local_tracks/trunk local_tracks
EOF
      scp $NUMBERDIR/ucsc.sh compgen:public_html/strep-recomb
      # break

# The following menus are combined into one menu here.
#          recombination-intensity1-map \
#          convert-gff-ingene \
#          locate-gene-in-block \
#          recombination-intensity1-genes \
#          recombination-intensity1-probability \
#          probability-recedge-gene \

      # Current directory structures.
      COUTPUTDIR=output
      CBASEDIR=$COUTPUTDIR/$SPECIES
      CBASERUNANALYSIS=$CBASEDIR/run-analysis
      CBASEDATADIR=$CBASEDIR/data
      CNUMBERDIR=$CBASEDIR/$REPETITION
      CDATADIR=$CNUMBERDIR/data
      CRUNMAUVE=$CNUMBERDIR/run-mauve
      CRUNCLONALORIGINDIR=$CNUMBERDIR/run-clonalorigin
      CRUNANALYSIS=$CNUMBERDIR/run-analysis

      NREPLICATE=$(grep ^REPETITION${REPETITION}-CO2-NREPLICATE species/$SPECIES | cut -d":" -f2)
      NUMBER_BLOCK=$(trim $(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`))

      GFFFILE=$(grep REPETITION${REPETITION}-GFF $SPECIESFILE | cut -d":" -f2)
      OUT=$CRUNANALYSIS/in.gene
      INGENE=$CRUNANALYSIS/in.gene
      COREALIGNMENT=$(grep ^COREALIGNMENT conf/README | cut -d":" -f2)
      REFGENOME=$(grep ^REPETITION${REPETITION}-REFGENOME $SPECIESFILE | cut -d":" -f2)
      FNAFILE=$(grep ^REPETITION${REPETITION}-FNA $SPECIESFILE | cut -d":" -f2)
      NUMBER_SAMPLE=$(trim $(echo `grep number $RUNCLONALORIGIN/output2/1/core_co.phase3.xml.1|wc -l`))
      REFGENOME=$(grep REPETITION$REPETITION-REFGENOME $SPECIESFILE | cut -d":" -f2)
      NUMBERSPECIES=$(grep ^REPETITION$REPETITION-NumberSpecies $SPECIESFILE | cut -d":" -f2)
      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)  
      NUMBER_SAMPLE=$(echo `grep number $RUNCLONALORIGIN/output2/$REPLICATE/core_co.phase3.xml.1|wc -l`)
      TREETOPOLOGY=$(grep ^REPETITION$REPETITION-TREETOPOLOGY $SPECIESFILE | cut -d":" -f2)
      REFGENOME=$(grep ^REPETITION$REPETITION-REFGENOME $SPECIESFILE | cut -d":" -f2)
      GBKFILE=$(grep ^GBK$REFGENOME $SPECIESFILE | cut -d":" -f2)
      
      NUMBERBRANCH=$((NUMBERSPECIES * 2 - 1))
      NUMBERBRANCHMINUSONE=$((NUMBERSPECIES * 2 - 2))
      
      echo -n "Do you wish to download rimap-#REPLICATE.txt? (e.g., y/n) "
      read WISH
      if [ "$WISH" == "y" ]; then
        for h in $(eval echo {1..$NREPLICATE}); do
        # for h in 1 3 4; do
#          scp -qr \
#            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-analysis/rimap-$h \
#            $RUNANALYSIS
#          scp -q \
#            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-analysis/rimap-$h.txt \
#            $RUNANALYSIS/rimap-$h.txt.cluster
#          scp -q \
#            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-analysis/ri-virulence-list-$h.out \
#            $RUNANALYSIS
          scp -q \
            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-analysis/rimap-$h-gene.* \
            $RUNANALYSIS
#          scp -q \
#            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-analysis/recombprob-$h-ref* \
#            $RUNANALYSIS
#          scp -qr \
#            $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-analysis/recombprobwig-$h \
#            $RUNANALYSIS
        done
        break
      fi


      # Copy things from here to CAC.
      GFF=$(basename $GFFFILE)
      FNA=$(basename $FNAFILE)
      GBK=$(basename $GBKFILE)
      for i in $(eval echo {1..$NUMBERSPECIES}); do
        GBKFILE=$(grep ^GBK$i\: $SPECIESFILE | cut -d":" -f2)
        scp -q $GBKFILE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      done
      scp -q $GFFFILE \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -q $FNAFILE \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -qr pl \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -q $CDATADIR/core_alignment.maf \
        $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/data

      rm -f $RUNCLONALORIGIN/job-probability-recombination
      for i in $(eval echo {1..$NUMBERSPECIES}); do
        GBKFILE=$(grep ^GBK$i\: $SPECIESFILE | cut -d":" -f2)
        GBK=$(basename $GBKFILE)
        echo "GBK$i=$GBK" >> $RUNCLONALORIGIN/job-probability-recombination
      done

cat>>$RUNCLONALORIGIN/job-probability-recombination<<EOF
cp -r \$PBS_O_WORKDIR/../run-analysis/rimap-\$1 $CRUNANALYSIS
cp -r \$PBS_O_WORKDIR/output2/\$1 $CRUNCLONALORIGINDIR/output2

perl pl/convert-gff-ingene.pl -gff $CRUNCLONALORIGINDIR/$GFF \\
  -out $CRUNANALYSIS/in.gene
perl pl/convert-gff-ingene.pl -gff $CRUNCLONALORIGINDIR/$GFF \\
  -withdescription -out $CRUNANALYSIS/in.gene.description

perl pl/locate-gene-in-block.pl \\
  locate \\
  -fna $CRUNCLONALORIGINDIR/$FNA \\
  -ingene $CRUNANALYSIS/in.gene \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -refgenome $REFGENOME \\
  -printseq \\
  -out $CRUNANALYSIS/in.gene.$REFGENOME.block



RIMAP=$CRUNANALYSIS/rimap-\$1.txt

# We did this before.
#perl pl/recombination-intensity1-map.pl \\
#  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
#  -xmfa $CDATADIR/core_alignment.xmfa \\
#  -numberblock $NUMBER_BLOCK \\
#  -verbose \\
#  -out \$RIMAP

NUMBER_BLOCK=$NUMBER_BLOCK
rm -f \$RIMAP
for b in \$(eval echo {1..\$NUMBER_BLOCK}); do
  cat $CRUNANALYSIS/rimap-\$1/\$b >> \$RIMAP
done

RIMAPGENE=$CRUNANALYSIS/rimap-\$1-gene
perl pl/ri-virulence.pl \\
  rimap \\
  -pairm all \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.all&

perl pl/ri-virulence.pl \\
  rimap \\
  -pairm topology \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.topology&
perl pl/ri-virulence.pl \\
  rimap \\
  -pairm notopology \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.notopology&
perl pl/ri-virulence.pl \\
  rimap \\
  -pairm pair \\
  -pairs 0,3:0,4:1,3:1,4 \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.sde2spy&
perl pl/ri-virulence.pl \\
  rimap \\
  -pairm pair \\
  -pairs 3,0:3,1:4,0:4,1 \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.spy2sde&
perl pl/ri-virulence.pl \\
  rimap \\
  -pairm pair \\
  -pairs 0,3:0,4:1,3:1,4:5,3:5,4:5,6 \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.matt.sde2spy&
perl pl/ri-virulence.pl \\
  rimap \\
  -pairm pair \\
  -pairs 3,0:3,1:3,5:4,0:4,1:4,5:6,0:6,1:6,5 \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -xmfa $CDATADIR/core_alignment.xmfa \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -samplesize $NUMBER_SAMPLE \\
  -out \$RIMAPGENE.matt.spy2sde&

# This can be used to find genes with high posterior probability
# of recombination.
# This rimap-1 is a directory, not a file.
perl pl/ri-virulence.pl list \\
  -ri $CRUNANALYSIS/rimap-\$1 \\
  -ingene $CRUNANALYSIS/in.gene.$REFGENOME.block \\
  -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
  -out $CRUNANALYSIS/ri-virulence-list-\$1.out&

#######################################################################
# Note: we need to have -xmfa2maf $CDATADIR/core_alignment.maf 
#       from core_alignment.xmfa.
for i in $(eval echo {1..$NUMBERSPECIES}); do
  OUTFILE=$CRUNANALYSIS/recombprob-\$1-ref\$i
  GBK=GBK\$i
  perl pl/recombination-intensity1-probability.pl wiggle \\
    -xml $CRUNCLONALORIGINDIR/output2/\$1/core_co.phase3.xml \\
    -xmfa2maf $CDATADIR/core_alignment.maf \\
    -xmfa $CDATADIR/core_alignment.xmfa \\
    -refgenome \$i \\
    -gbk $CRUNCLONALORIGINDIR/\${!GBK} \\
    -ri $CRUNANALYSIS/rimap-\$1 \\
    -clonaloriginsamplesize $NUMBER_SAMPLE \\
    -out \$OUTFILE&
done
wait

#######################################################################
# See test/recombprob/batch.sh
mkdir $CRUNANALYSIS/recombprobwig-\$1
for i in $(eval echo {1..$NUMBERSPECIES}); do
  # Create wiggle files by extracting columns.
  RECOMBPROB=$CRUNANALYSIS/recombprob-\$1-ref\$i
  RECOMBPROBWIG=$CRUNANALYSIS/recombprobwig-\$1/\$i
  mkdir \$RECOMBPROBWIG
  for j in {0..$NUMBERBRANCHMINUSONE}; do
    for k in {0..$NUMBERBRANCHMINUSONE}; do
      c=\$((j * NUMBERBRANCH + k + 3))
      echo -e "track type=wiggle_0\\nfixedStep chrom=chr1 start=1 step=1 span=1" > \$RECOMBPROBWIG/\$j-\$k 
      cut -f \$c \$RECOMBPROB >> \$RECOMBPROBWIG/\$j-\$k &
    done
    wait
  done
done

echo gene > 0;       cut -f1 \$RIMAPGENE.all >> 0
echo all > 1;        cut -f12 \$RIMAPGENE.all >> 1
echo topology > 2;   cut -f12 \$RIMAPGENE.topology >> 2
echo notopology > 3; cut -f12 \$RIMAPGENE.notopology >> 3
echo sde2spy > 4;    cut -f12 \$RIMAPGENE.sde2spy >> 4
echo spy2sde > 5;    cut -f12 \$RIMAPGENE.spy2sde >> 5 
echo mattsde2spy > 6;    cut -f12 \$RIMAPGENE.matt.sde2spy >> 6
echo mattspy2sde > 7;    cut -f12 \$RIMAPGENE.matt.spy2sde >> 7
paste 0 1 2 3 4 5 6 7 > \$RIMAPGENE.txt
rm 0 1 2 3 4 5 6 7
        # Change this so that we could use ri
#        perl pl/probability-recedge-gene.pl \\
#          -ri1map $CRUNANALYSIS/ri1-refgenome$REFGENOME-map.txt \\
#          -clonaloriginsamplesize $NUMBER_SAMPLE \\
#          -genbank $GENOMEDATADIR/$GENBANK \\
#          -out $CRUNANALYSIS/probability-recombination.txt

EOF
      ############################################################################
      #
      probability-recombination-cluster

      ###############################################################


      # Recombination intensity simulation
#      echo perl pl/probability-recombination.pl \
#        -d $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml \
#        -xmfa $DATADIR/core_alignment.xmfa \
#        -r 1 \
#        -coords simulation/sde1.coords.txt \
#        $RUNANALYSIS/$FUNCNAME.txt
        #> $RUNANALYSIS/recombination-intensity.txt
      echo "Use R/gene-list.R to list genes with RI above a threshold"
      break
    fi
  done
}

function probability-recombination-cluster {
      echo "  Creating jobidfile..."
      WALLTIME=$(grep ^REPETITION${REPETITION}-CA1-WALLTIME species/$SPECIES | cut -d":" -f2)
      NUMBER_BLOCK=$(echo `ls $DATADIR/core_alignment.xmfa.*|wc -l`)
      JOBIDFILE=$RUNCLONALORIGIN/rimap.jobidfile
      CRUNCLONALORIGINDIR=output/$SPECIES/$REPETITION/run-clonalorigin
      rm -f $JOBIDFILE
      for h in $(eval echo {1..$NREPLICATE}); do
        for b in $(eval echo {1..$NUMBER_BLOCK}); do
          echo "perl pl/recombination-intensity1-map.pl block \
            -xml $CRUNCLONALORIGINDIR/output2/$h/core_co.phase3.xml \
            -xmfa $CDATADIR/core_alignment.xmfa \
            -blockid $b \
            -numberblock $NUMBER_BLOCK \
            -out $CRUNANALYSIS/rimap-$h/$b" >> $JOBIDFILE 
        done
      done

      scp -q $JOBIDFILE \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -q cac/sim/batch_task_gui.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/batchjob.sh
      scp -q cac/sim/run2.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin/run.sh

cat>$RUNCLONALORIGIN/batch.sh<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-CA1
#PBS -q ${QUEUENAME}
#PBS -m e
# #PBS -M ${BATCHEMAIL}
#PBS -t 1-PBSARRAYSIZE

function copy-data {
  cd \$TMPDIR
  # Copy excutables
  cp -r \$PBS_O_WORKDIR/pl .
  # Copy shell scripts
  cp \$PBS_O_WORKDIR/batchjob.sh .
  # Create directories
  mkdir -p $CRUNCLONALORIGINDIR/output2
  mkdir -p $CRUNANALYSIS
  cp -r \$PBS_O_WORKDIR/../data $CNUMBERDIR
  for h in \$(eval echo {1..$NREPLICATE}); do
    cp -r \$PBS_O_WORKDIR/output2/\$h $CRUNCLONALORIGINDIR/output2
    mkdir -p $CRUNANALYSIS/rimap-\$h
  done
  # Create a status directory
  mkdir \$PBS_O_WORKDIR/status/\$PBS_ARRAYID
}

function retrieve-data {
  for h in \$(eval echo {1..$NREPLICATE}); do
    cp -r $CRUNANALYSIS/rimap-\$h \$PBS_O_WORKDIR/../run-analysis
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
      \$PBS_O_WORKDIR/rimap.jobidfile \\
      \$PBS_O_WORKDIR/rimap.lockfile \\
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
      scp -q $RUNCLONALORIGIN/batch.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin

cat>$RUNCLONALORIGIN/batch2.sh<<EOF
#!/bin/bash
#PBS -l walltime=${WALLTIME}:00:00,nodes=1
#PBS -A ${BATCHACCESS}
#PBS -j oe
#PBS -N $PROJECTNAME-CA1
#PBS -q ${QUEUENAME}
#PBS -m e
# #PBS -M ${BATCHEMAIL}
#PBS -t 1-$NREPLICATE

# Copy things from the CAC's working directory to the compute node.
function copy-data {
  cd \$TMPDIR
  # Copy excutables

  # Copy shell scripts
  cp -r \$PBS_O_WORKDIR/pl .
  cp \$PBS_O_WORKDIR/job-probability-recombination .

  # Create directories
  mkdir -p $CRUNCLONALORIGINDIR/output2
  mkdir -p $CRUNANALYSIS
  cp \$PBS_O_WORKDIR/$GFF $CRUNCLONALORIGINDIR
  cp \$PBS_O_WORKDIR/$FNA $CRUNCLONALORIGINDIR
  cp \$PBS_O_WORKDIR/*.gbk $CRUNCLONALORIGINDIR
  cp -r \$PBS_O_WORKDIR/../data $CNUMBERDIR

  # for h in $(eval echo {1..$NREPLICATE}); do
    # cp -r \$PBS_O_WORKDIR/../run-analysis/rimap-\$h $CRUNANALYSIS
  # done

  # Create a status directory
  mkdir \$PBS_O_WORKDIR/status/\$PBS_ARRAYID
}

function retrieve-data {
  cp $CRUNANALYSIS/rimap*gene* \$PBS_O_WORKDIR/../run-analysis
  cp $CRUNANALYSIS/rimap-\$PBS_ARRAYID.txt  \$PBS_O_WORKDIR/../run-analysis
  cp $CRUNANALYSIS/recombprob-\$PBS_ARRAYID-ref* \$PBS_O_WORKDIR/../run-analysis
  cp -r $CRUNANALYSIS/recombprobwig-\$PBS_ARRAYID \$PBS_O_WORKDIR/../run-analysis
  cp $CRUNANALYSIS/ri-virulence-list-\$PBS_ARRAYID.out \$PBS_O_WORKDIR/../run-analysis

  #for h in $(eval echo {1..$NREPLICATE}); do
    #cp $CRUNANALYSIS/rimap-\$h.txt  \$PBS_O_WORKDIR/../run-analysis
    #cp -r $CRUNANALYSIS/recombprobwig-\$h \$PBS_O_WORKDIR/../run-analysis
  #done

  # Remove the status directory.
  rm -rf \$PBS_O_WORKDIR/status/\$PBS_ARRAYID
}

function process-data {
  cd \$TMPDIR
  bash job-probability-recombination \$PBS_ARRAYID
}

copy-data
process-data; wait
retrieve-data
cd \$PBS_O_WORKDIR
rm -rf \$TMPDIR
EOF
      scp -q $RUNCLONALORIGIN/batch2.sh \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      scp -q $RUNCLONALORIGIN/job-probability-recombination \
          $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin
      echo "Go to $CAC_MAUVEANALYSISDIR/output/$SPECIES/$REPETITION/run-clonalorigin"
      echo "$ bash run.sh"
      echo "$ nsub batch2.sh"
}
