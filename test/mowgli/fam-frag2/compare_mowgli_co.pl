# perl compare_mowgli_co.pl > compare_mowgli_co.txt

# Files:
# fam-frag2.part.txt
# famid-events.txt
# famid-gene.txt
# rimap.gene.txt

# Events are counted for gene families.
# Recombination intensities are scored for SPY genes.
# Gene families could have multiple SPY genes. 
# 1. Find the list of families and the number recombining events form famid-events.txt
# 2. Find the list of genes and recombination intensity from rimap.gene.txt
# 3. Map gene names to gene family names using famid-gene.txt.
# 4. For each gene in the second list from the step 2, find the gene family, for
# which find the number of recombining events from the first list from the step
# 1. Print gene name, recombination intensity, and the number of recombining
# gene transfer.

# Step 1
my %famidEvent;
my %famidHgtEvent;
open FAMILY, "famid-events.txt";
while (<FAMILY>)
{
  chomp;
  my @e = split /\t/;
  $famidEvent{$e[0]} = $e[4];
  $famidHgtEvent{$e[0]} = $e[3];
}
close FAMILY;

# Step 2
my %geneRI;
open RI, "rimap.gene.txt";
my $l = <RI>;
while (<RI>)
{
  chomp;
  my @e = split /\t/;
  $geneRI{$e[0]} = $e[2];
}
close RI;

# Step 3
my %geneToFamily;
open GENETOFAM, "famid-gene.txt";
while (<GENETOFAM>)
{
  chomp;
  my @e = split /\t/;
  if (exists $geneToFamily{$e[1]})
  {
    my $a = $geneToFamily{$e[1]};
    push @$a, $e[0];
  }
  else
  {
    my @a;
    push @a, $e[0];
    $geneToFamily{$e[1]} = [ @a ];
  }
  
}
close GENETOFAM;

# Step 4
foreach my $g (keys %geneRI)
{
  my $f = $geneToFamily{$g};
  foreach my $fid (@$f)
  {
    if (exists $famidEvent{$fid})
    {
      print "$g\t$geneRI{$g}\t$famidEvent{$fid}\t$famidHgtEvent{$fid}\t$fid\n";
    }
  }
}

