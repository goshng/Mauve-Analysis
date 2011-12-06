KENT=/usr/local/software/kent
# DBNAMECHOICES=(recSde1 recSde2 recSdd recSpy1 recSpy2)
DBNAMECHOICES=(SdeqATCC12394 SdeqGGS124 SddyATCC27957 SpyMGAS315 SpyMGAS10750)

h=1
for i in $(eval echo {1..5}); do
  idb=$((i-1))
  DBNAME=${DBNAMECHOICES[$idb]}
  # Create wiggle files by extracting columns.
  RECOMBPROBWIG=recombprobwig-$h/$i
  for j in $(eval echo {0..8}); do
    for k in $(eval echo {0..8}); do
      WIGIN=$RECOMBPROBWIG/${j}-${k}
      WIG=$RECOMBPROBWIG/${j}-${k}.wig
      WIB=$RECOMBPROBWIG/${j}-${k}.wib

      # wigEncode   
      hgsql $DBNAME -e "drop table ri_${j}_${k}"
      hgLoadWiggle $DBNAME ri_${j}_${k} $WIG
      # rm 
      mkdir -p /gbdb_cornell/$DBNAME/wib
      cp $WIB /gbdb_cornell/$DBNAME/wib
      hgsql $DBNAME -e "update ri_${j}_${k} set file='/gbdb_cornell/$DBNAME/wib/${j}-${k}.wib'"
    done
  done
done
exit

for i in $(eval echo {1..5}); do
  idb=$((i-1))
  DBNAME=${DBNAMECHOICES[$idb]}
  mkdir /gbdb_cornell/$DBNAME/maf
  cp core_alignment.maf.$i /gbdb_cornell/$DBNAME/maf/core_alignment.maf
  MAF2=/gbdb_cornell/$DBNAME/maf/core_alignment.maf
  hgLoadMaf $DBNAME maf -loadFile=$MAF2
done
exit

for i in $(eval echo {0..4}); do
  DBNAME=${DBNAMECHOICES[$i]}
  gbToFaRa /dev/null $DBNAME.fna $DBNAME.ra $DBNAME.ta $DBNAME.gbk 
  toUpper $DBNAME.fna $DBNAME.fna.upper
  faSize $DBNAME.fna.upper
  rm $DBNAME.fna $DBNAME.ra $DBNAME.ta 
  echo ">chr1" > $DBNAME.fna
  grep -v ">" $DBNAME.fna.upper >> $DBNAME.fna
  rm $DBNAME.fna.upper

  hgFakeAgp -minContigGap=1 $DBNAME.fna $DBNAME.agp
  faToTwoBit $DBNAME.fna $DBNAME.2bit
  mkdir -p /gbdb_cornell/$DBNAME/html
  cp $DBNAME.2bit /gbdb_cornell/$DBNAME

  echo "  creating a database ..."
  twoBitInfo $DBNAME.2bit stdout | sort -k2nr > chrom.sizes
  rm -rf bed
  mkdir -p bed/chromInfo
  awk '{printf "%s\t%d\t/gbdb_cornell/DBNAME/DBNAME.2bit\n", $1, $2}' \
    chrom.sizes > bed/chromInfo/chromInfo.tab.tmp
  sed s/DBNAME/$DBNAME/g < bed/chromInfo/chromInfo.tab.tmp > bed/chromInfo/chromInfo.tab
  hgsql -e "create database $DBNAME;" mysql

  echo "  creating grp, chromInfo tables ..."
  hgsql $DBNAME < $KENT/src/hg/lib/grp.sql

  cp bed/chromInfo/chromInfo.tab /tmp/
  hgLoadSqlTab $DBNAME chromInfo $KENT/src/hg/lib/chromInfo.sql \
    /tmp/chromInfo.tab
  rm /tmp/chromInfo.tab
  hgGoldGapGl $DBNAME $DBNAME.agp

  echo "  creating GC5 track ..."
  mkdir bed/gc5Base
  hgGcPercent -wigOut -doGaps -file=stdout -win=5 -verbose=0 $DBNAME \
    $DBNAME.2bit | wigEncode stdin bed/gc5Base/gc5Base.{wig,wib}
  hgLoadWiggle -pathPrefix=/gbdb_cornell/$DBNAME/wib \
    $DBNAME gc5Base bed/gc5Base/gc5Base.wig
  mkdir -p /gbdb_cornell/$DBNAME/wib/bed/gc5Base
  cp bed/gc5Base/gc5Base.wib /gbdb_cornell/$DBNAME/wib/bed/gc5Base
  rm -rf bed



done

