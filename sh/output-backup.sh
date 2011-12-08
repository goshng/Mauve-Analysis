DIR1=output
DIR2=output-backup

cp -pr $DIR1/go $DIR2
exit

cp -p $DIR1/cornellf/3/run-analysis/* $DIR2/cornellf/3/run-analysis

for i in matt virulence; do
  cp -pr $DIR1/$i $DIR2/
done

cp -p $DIR1/cornellf/3/data/core_alignment.maf.* $DIR2/cornellf/3/data
cp -p $DIR1/cornellf/3/data/core_alignment.xmfa $DIR2/cornellf/3/data
cp -p $DIR1/cornellf/3/data/core_alignment.xmfa.* $DIR2/cornellf/3/data

cp -pr $DIR1/cornellf/3/run-mauve/output $DIR2/cornellf/3/run-mauve
cp -pr $DIR1/cornellf/3/run-clonalframe/output $DIR2/cornellf/3/run-clonalframe
cp -pr $DIR1/cornellf/3/run-clonalorigin/summary $DIR2/cornellf/3/run-clonalorigin
cp -p $DIR1/cornellf/3/run-clonalorigin/clonaltree.nwk $DIR2/cornellf/3/run-clonalorigin
cp -pr $DIR1/s15/run-analysis $DIR2/s15
cp -pr $DIR1/s16/run-analysis $DIR2/s16
cp -pr $DIR1/s17/run-analysis $DIR2/s17
cp -pr $DIR1/s18/run-analysis $DIR2/s18

for i in {1..2}; do
  cp -pr $DIR1/cornellf/3/run-clonalorigin/output/$i $DIR2/cornellf/3/run-clonalorigin/output
done

for i in {1..4}; do
  cp -pr $DIR1/cornellf/3/run-clonalorigin/output2/$i $DIR2/cornellf/3/run-clonalorigin/output
done

for i in {1..4}; do
  rm -rf $DIR2/cornellf/3/run-analysis/recombprobwig-$i
  cp -pr $DIR1/cornellf/3/run-analysis/recombprobwig-$i $DIR2/cornellf/3/run-analysis
done

