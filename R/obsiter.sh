for h in {1..4}; do
  sed s/REPLICATE/$h/g < R/obsiter.R > R/obsiter.R.temp
  Rscript R/obsiter.R.temp > R/obsiter.R.$h
done
rm R/obsiter.R.temp
