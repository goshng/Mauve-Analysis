# For the revision.
for h in cornell1 cornell2 cornell3 cornell4 cornellfx5 cornellfx6 cornellfx7 cornellfx8 cornellfx9 cornellfx10 ; do
  sed s/SPECIESNAME/$h/g < R/obsiter.R > R/obsiter.R.temp
  Rscript R/obsiter.R.temp > R/obsiter.R.$h
done
rm R/obsiter.R.temp

# For the submitted version
#for h in {1..4}; do
#  sed s/REPLICATE/$h/g < R/obsiter.R > R/obsiter.R.temp
#  Rscript R/obsiter.R.temp > R/obsiter.R.$h
#done
#rm R/obsiter.R.temp
