
sub parse_in_gene ($) {
  my ($ingene) = @_;
  my @genes;
  open INGENE, "$ingene" or die "$ingene could be not opened";
  while (<INGENE>)
  {
    chomp;
    my @e = split /\t/;
    my $rec = {};
    $rec->{gene} = $e[0]; 
    $rec->{start} = $e[1]; 
    $rec->{end} = $e[2]; 
    $rec->{strand} = $e[3]; 
    $rec->{block} = $e[4]; 
    $rec->{blockstart} = $e[5]; 
    $rec->{blockend} = $e[6]; 
    $rec->{genelength} = $e[7]; 
    $rec->{proportiongap} = $e[8]; 
    push @genes, $rec;
  }
  close INGENE;
  return @genes;
}

sub print_in_gene ($$)
{
  my ($ingene, $genes) = @_;
  
  open INGENE, ">$ingene.temp" or die "$ingene.temp could be not opened";
  for (my $i = 0; $i < scalar @{ $genes }; $i++)
  {
    my $rec = $genes->[$i];
    print INGENE "$rec->{gene}\t";
    print INGENE "$rec->{start}\t";
    print INGENE "$rec->{end}\t";
    print INGENE "$rec->{strand}\t";
    print INGENE "$rec->{block}\t";
    print INGENE "$rec->{blockstart}\t";
    print INGENE "$rec->{blockend}\t";
    print INGENE "$rec->{genelength}\t";
    print INGENE "$rec->{proportiongap}\t";
    print INGENE "$rec->{ri}\t";
    print INGENE "$rec->{ri2}\t";
    print INGENE "$rec->{ri3}\n";
  }
  close INGENE;
  rename "$ingene.temp", $ingene
}

1;
