use strict;
# perl from-go-perl.pl gene_ontology.1_2.obo go-list.txt > go-list.txt.out
my $oboFilename = $ARGV[0];
my $goFilename = $ARGV[1];

use GO::Parser;

# Read gene ontology terms.
my @goTerm;
open GO, $goFilename or die "cannot open < $goFilename $!";
while (<GO>)
{
  chomp;
  push @goTerm, $_;
}
close GO;

# Parse the obo file.
my $parser = new GO::Parser({handler=>'obj'}); # create parser object
$parser->parse($oboFilename); # parse file -> objects
my $graph = $parser->handler->graph;  # get L<GO::Model::Graph> object

# Find terms.
my $i = 0;
my $n = scalar (@goTerm);
my %goTermInfomational;
foreach my $aTerm (@goTerm)
{
  $i++;
  my $term = $graph->get_term($aTerm);   # fetch a term by ID
  unless (defined $term)
  {
    print STDERR "$aTerm is not in the oboFilename\n";
    next;
  }
  my $isInformational = 0;

  if ($term->acc eq "GO:0006351"
      or $term->acc eq "GO:0001172"
      or $term->acc eq "GO:0006260"
      or $term->acc eq "GO:0006412"
      or $term->acc eq "GO:0043039")
  {
    $isInformational = 1;
  }

  if ($isInformational == 0)
  {
    my $ancestor_terms = $graph->get_recursive_parent_terms($term->acc);
    foreach my $desc_term (@$ancestor_terms) {
      if ($desc_term->acc eq "GO:0006351"
          or $desc_term->acc eq "GO:0001172"
          or $desc_term->acc eq "GO:0006260"
          or $desc_term->acc eq "GO:0006412"
          or $desc_term->acc eq "GO:0043039")
      {
        $isInformational = 1;
      }
      last if ($isInformational == 1);
    }
  }
  $goTermInfomational{$aTerm} = $isInformational;

  print STDERR "$i/$n\r";
}

foreach my $k (keys %goTermInfomational)
{
  print "$k\t$goTermInfomational{$k}\n"
}

