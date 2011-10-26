for i in {1..25}; do
perl pl/virulence.pl extract -random \
  -in /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/in.gene.4.block \
  -gene output/virulence/virulent_genes.txt.spy1 \
  -out /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/in.random.gene.4.block.$1

perl pl/ri-virulence.pl heatmap \
  -ri /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/rimap-2 \
  -ingene /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/in.random.gene.4.block.$1 \
  -xml /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-clonalorigin/output2/2/core_co.phase3.xml \
  -out /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/ri-random-heatmap.out.$1

perl pl/ri-virulence.pl heatmap \
  -ri /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/rimap-2 \
  -ingene /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/in.random.gene.4.block.$1.not \
  -xml /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-clonalorigin/output2/2/core_co.phase3.xml \
  -out /Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/ri-random-heatmap.out.not.$1

Rscript vir-random.R.$1
done
