Rscript famsizes.R
Rscript compare_mowgli_co.R
echo Convert famsizes.ps compareMowgliCoHgt.ps compareMowgliCoRecombining.ps
echo to PDF files, and move them to figures directory for type-setting.
exit
mv *.pdf /Users/goshng/Documents/siepel-lab/writing/papers/strep-recomb/figures
mv *.ps /Users/goshng/Documents/siepel-lab/writing/papers/strep-recomb/figures
