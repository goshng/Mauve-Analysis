

GENOMEDATADIR=/Volumes/Elements/Documents/Projects/mauve/genomes
#/Users/goshng/Documents/Projects/mauve
BASE=$HOME/Documents/Projects/mauve
#MAUVE=$HOME/usr/bin/progressiveMauve

#MAUVE=/Applications/Mauve.app/Contents/MacOS/progressiveMauve
#MAUVE=$HOME/Applications/Mauve.app/Contents/MacOS/progressiveMauve
MAUVE=$HOME/Documents/Projects/mauve/build/mauveAligner/src/progressiveMauve

LCB=$HOME/usr/bin/stripSubsetLCBs 
GCT=$HOME/usr/bin/getClonalTree 
AUI=$HOME/usr/bin/addUnalignedIntervals 
MWF=$HOME/usr/bin/makeMauveWargFile.pl
RESULT1=1alignment
ALIGNMENT=run-mauve-genome26/output
CLONALFRAMEOUTPUT=run-clonalframe/

function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}

OTHERDIR=/Volumes/sc2265/Documents/Projects/mauve/genomes52/
# OTHERDIR=choi@swiftgen:Documents/Projects/mauve/genomes52/

function copy-genomes {
  mkdir $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_agalactiae_2603V_R_uid57943/NC_004116.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_agalactiae_A909_uid57935/NC_007432.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_agalactiae_NEM316/NC_004368.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_dysgalactiae_equisimilis_GGS_124_uid59103/NC_012891.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_equi_4047_uid59259/NC_012471.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_equi_zooepidemicus_MGCS10565_uid59263/NC_011134.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_equi_zooepidemicus_uid59261/NC_012470.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_gallolyticus_UCN34_uid46061/NC_013798.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_gordonii_Challis_substr__CH1_uid57667/NC_009785.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_mitis_B6_uid46097/NC_013853.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_mutans_NN2025_uid46353/NC_013928.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_mutans_UA159_uid57947/NC_004350.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_670_6B_uid52533/NC_014498.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_70585_uid59125/NC_012468.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_AP200_uid52453/NC_014494.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_ATCC_700669_uid59287/NC_011900.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_CGSP14_uid59181/NC_010582.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_D39_uid58581/NC_008533.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_G54_uid59167/NC_011072.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_Hungary19A_6_uid59117/NC_010380.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_JJA_uid59121/NC_012466.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_P1031_uid59123/NC_012467.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_R6_uid57859/NC_003098.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_Taiwan19F_14_uid59119/NC_012469.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_TCH8431_19A_uid49735/NC_014251.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pneumoniae_TIGR4_uid57857/NC_003028.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_M1_GAS_uid57845/NC_002737.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_Manfredo_uid57847/NC_009332.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10270_uid58571/NC_008022.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10394_uid58105/NC_006086.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10750_uid58575/NC_008024.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS2096_uid58573/NC_008023.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS315_uid57911/NC_004070.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS5005_uid58337/NC_007297.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS6180_uid58335/NC_007296.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS8232_uid57871/NC_003485.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_MGAS9429_uid58569/NC_008021.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_NZ131_uid59035/NC_011375.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_pyogenes_SSI_1_uid57895/NC_004606.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_sanguinis_SK36_uid58381/NC_009009.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_suis_05ZYH33_uid58663/NC_009442.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_suis_98HAH33_uid58665/NC_009443.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_suis_BM407_uid59321/NC_012923.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_suis_BM407_uid59321/NC_012926.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_suis_P1_7_uid32235/NC_012925.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_suis_SC84_uid59323/NC_012924.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_thermophilus_CNRZ1066_uid58221/NC_006449.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_thermophilus_LMD_9_uid58327/NC_008500.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_thermophilus_LMD_9_uid58327/NC_008501.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_thermophilus_LMD_9_uid58327/NC_008532.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_thermophilus_LMG_18311_uid58219/NC_006448.gbk $OTHERDIR
  cp $GENOMEDATADIR/Streptococcus_uberis_0140J_uid57959/NC_012004.gbk $OTHERDIR
}


#DYLD_LIBRARY_PATH=cp $DYLD_LIBRARY_PATH:cp $HOME/usr/lib cp $MAUVE --output=full_alignment.xmfa \
function run-mauve {
  START_TIME=`date +%s`
  rm -rf $RESULT1
  mkdir $RESULT1
DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
$MAUVE --output=full_alignment.xmfa \
  --output-guide-tree=strep.guide_tree \
  $GENOMEDATADIR/Streptococcus_agalactiae_2603V_R_uid57943/NC_004116.gbk \
  $GENOMEDATADIR/Streptococcus_agalactiae_A909_uid57935/NC_007432.gbk \
  $GENOMEDATADIR/Streptococcus_agalactiae_NEM316/NC_004368.gbk \
  $GENOMEDATADIR/Streptococcus_dysgalactiae_equisimilis_GGS_124_uid59103/NC_012891.gbk \
  $GENOMEDATADIR/Streptococcus_equi_4047_uid59259/NC_012471.gbk \
  $GENOMEDATADIR/Streptococcus_equi_zooepidemicus_MGCS10565_uid59263/NC_011134.gbk \
  $GENOMEDATADIR/Streptococcus_equi_zooepidemicus_uid59261/NC_012470.gbk \
  $GENOMEDATADIR/Streptococcus_gallolyticus_UCN34_uid46061/NC_013798.gbk \
  $GENOMEDATADIR/Streptococcus_gordonii_Challis_substr__CH1_uid57667/NC_009785.gbk \
  $GENOMEDATADIR/Streptococcus_mitis_B6_uid46097/NC_013853.gbk \
  $GENOMEDATADIR/Streptococcus_mutans_NN2025_uid46353/NC_013928.gbk \
  $GENOMEDATADIR/Streptococcus_mutans_UA159_uid57947/NC_004350.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_670_6B_uid52533/NC_014498.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_70585_uid59125/NC_012468.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_AP200_uid52453/NC_014494.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_ATCC_700669_uid59287/NC_011900.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_CGSP14_uid59181/NC_010582.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_D39_uid58581/NC_008533.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_G54_uid59167/NC_011072.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_Hungary19A_6_uid59117/NC_010380.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_JJA_uid59121/NC_012466.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_P1031_uid59123/NC_012467.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_R6_uid57859/NC_003098.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_Taiwan19F_14_uid59119/NC_012469.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_TCH8431_19A_uid49735/NC_014251.gbk \
  $GENOMEDATADIR/Streptococcus_pneumoniae_TIGR4_uid57857/NC_003028.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_M1_GAS_uid57845/NC_002737.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_Manfredo_uid57847/NC_009332.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10270_uid58571/NC_008022.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10394_uid58105/NC_006086.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS10750_uid58575/NC_008024.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS2096_uid58573/NC_008023.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS315_uid57911/NC_004070.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS5005_uid58337/NC_007297.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS6180_uid58335/NC_007296.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS8232_uid57871/NC_003485.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_MGAS9429_uid58569/NC_008021.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_NZ131_uid59035/NC_011375.gbk \
  $GENOMEDATADIR/Streptococcus_pyogenes_SSI_1_uid57895/NC_004606.gbk \
  $GENOMEDATADIR/Streptococcus_sanguinis_SK36_uid58381/NC_009009.gbk \
  $GENOMEDATADIR/Streptococcus_suis_05ZYH33_uid58663/NC_009442.gbk \
  $GENOMEDATADIR/Streptococcus_suis_98HAH33_uid58665/NC_009443.gbk \
  $GENOMEDATADIR/Streptococcus_suis_BM407_uid59321/NC_012923.gbk \
  $GENOMEDATADIR/Streptococcus_suis_BM407_uid59321/NC_012926.gbk \
  $GENOMEDATADIR/Streptococcus_suis_P1_7_uid32235/NC_012925.gbk \
  $GENOMEDATADIR/Streptococcus_suis_SC84_uid59323/NC_012924.gbk \
  $GENOMEDATADIR/Streptococcus_thermophilus_CNRZ1066_uid58221/NC_006449.gbk \
  $GENOMEDATADIR/Streptococcus_thermophilus_LMD_9_uid58327/NC_008500.gbk \
  $GENOMEDATADIR/Streptococcus_thermophilus_LMD_9_uid58327/NC_008501.gbk \
  $GENOMEDATADIR/Streptococcus_thermophilus_LMD_9_uid58327/NC_008532.gbk \
  $GENOMEDATADIR/Streptococcus_thermophilus_LMG_18311_uid58219/NC_006448.gbk \
  $GENOMEDATADIR/Streptococcus_uberis_0140J_uid57959/NC_012004.gbk 
  END_TIME=`date +%s`
  ELAPSED=`expr $END_TIME - $START_TIME`
  echo "FINISHED at " `date` " Elapsed time: " 
  hms $ELAPSED 
}

function run-lcb {
  #$LCB full_alignment.xmfa full_alignment.xmfa.bbcols core_alignment.xmfa 500
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $ALIGNMENT/full_alignment.xmfa $ALIGNMENT/full_alignment.xmfa.bbcols $ALIGNMENT/core_alignment.xmfa 500
}

function run-clonalframe {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  ClonalFrame -x 0 -y 0 -z 1 -t 2 $ALIGNMENT/core_alignment.xmfa \
  $CLONALFRAMEOUTPUT/core_clonalframe.out.1 > $CLONALFRAMEOUTPUT/cf_stdout.1 
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #ClonalFrame -x 10 -y 10 -z 1 $ALIGNMENT/core_alignment.xmfa $ALIGNMENT/core_clonalframe.out.1 > $ALIGNMENT/cf_stdout.1 
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #ClonalFrame -x 10000 -y 10000 -z 10 core_alignment.xmfa core_clonalframe.out.2 > cf_stdout.2 
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #ClonalFrame -x 10000 -y 10000 -z 10 core_alignment.xmfa core_clonalframe.out.3 > cf_stdout.3 
}

function run-clonalorigin-format {
  $GCT core_clonalframe.out.1 clonaltree.nwk
  perl $HOME/usr/bin/blocksplit.pl core_alignment.xmfa
}

function run-warg {
  #for i in {1..575}
  #rm -rf xml
  #mkdir xml

  PMI_RANK=$1
  PMI_START=$(( 144 * PMI_RANK + 1 ))
  PMI_END=$(( 144 * (PMI_RANK + 1) ))

  START_TIME=`date +%s`
  for (( i=${PMI_START}; i<=${PMI_END}; i++ ))
  #for i in {1..575}
  do
    if [ $i -lt 576 ]
    then
    #warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 1000000 -z 10000 clonaltree.nwk core_alignment.xmfa.$i core_co.phase2.$i.xml
    #warg -a 1,1,0.1,1,1,1,1,1,0,0,0 -w 10000 -x 10000 -y 10000 -z 10 clonaltree.nwk \
      #xmfa/core_alignment.xmfa.$i xml/core_co.phase2.$i.xml
    warg -w 10000 -x 10000 -y 10000 -z 10 \
      -D 1725.16905094905 -T 0.0386842013408279 -R 0.000773885007973949 \
      clonaltree.nwk xmfa/core_alignment.xmfa.$i xml3/core_co.phase3.$i.xml
    fi
  done
  END_TIME=`date +%s`
  ELAPSED=`expr $END_TIME - $START_TIME`
  echo "FINISHED at " `date` " Elapsed time: " 
  hms $ELAPSED 

  # lensum is 1127288
  # Median theta: 0.0386842013408279
  # Median delta: 1725.16905094905
  # Median rho: 0.000773885007973949
}

function mauve-display {
  #DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  #$AUI core_alignment.xmfa core_alignment_mauveable.xmfa

  perl $MWF xml3-cac/*
}

function run-bbfilter {
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  bbFilter $ALIGNMENT/full_alignment.xmfa.backbone 50 my_feats.bin gp
}

# Align genomes using Mauve.
#copy-genomes 
#run-mauve 

# Note that full_alignment.xmfa has the input genomes.
# Copy the genomes52 directory to /tmp/sc2265.
#run-lcb

#run-clonalframe



run-bbfilter 
