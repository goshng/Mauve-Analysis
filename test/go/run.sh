# OBSOLETE: perl from-go-perl.pl gene_ontology.1_2.obo go-list.txt > go-list.txt.out
# cut -f 1 SpyMGAS315_go_category_names.txt | sort > go-list.txt
# perl from-go-perl-ancestor.pl gene_ontology.1_2.obo go-list.txt > go-list.txt.out
perl from-go-perl-2nd.pl go-list.txt.out SpyMGAS315_go_bacteria.txt > go-list.txt.out2.new

