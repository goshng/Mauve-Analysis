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
  next if ($_ eq "GO:0008150" or $_ eq "GO:0005575" or $_ eq "GO:0003674");
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
  if ($term->name =~ /transcription/
      or $term->name =~ /translation/
      or $term->name =~ /replication/)
  {
    $isInformational = 1;
  }

  if ($isInformational == 0)
  {
    my $ancestor_terms = $graph->get_recursive_child_terms($term->acc);
    foreach my $desc_term (@$ancestor_terms) {
      if ($desc_term->name =~ /transcription/
          or $desc_term->name =~ /translation/
          or $desc_term->name =~ /replication/)
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

