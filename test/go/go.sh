for h in {1..4}; do
  sed s/REPLICATE/$h/g < go.R > go.R.temp
  Rscript go.R.temp > go.R.$h
done
rm go.R.temp
