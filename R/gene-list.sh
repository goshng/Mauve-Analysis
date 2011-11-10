for h in {1..4}; do
  for t in 50 60 70 80 90; do
    sed s/REPLICATE/$h/g < R/gene-list.R > R/gene-list.R.temp
    sed s/THRESHOLD/$t/g < R/gene-list.R.temp > R/gene-list.R.temp2
    Rscript R/gene-list.R.temp2 > R/gene-list.R.$t.$h
  done
done
rm R/gene-list.R.temp
rm R/gene-list.R.temp2
