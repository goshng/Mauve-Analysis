open IN, "famsizes.txt" or die "cannot open famsizes.txt $!";
my %famsize;
while (<IN>)
{
  chomp;
  my @e = split /\s+/;
  my $n = $e[1];
  my $g = $e[2];
  $g =~ s/(-\d)//; 
  if (exists $famsize{$g})
  {
    unless ($famsize{$g} == $n)
    {
      print STDERR "The family has two fragments with different sizes $g - $famsize{$g} vs $n\n" 
    }
    # die "The family has two fragments with different sizes $g" 
      # unless $famsize{$g} == $n;
  }
  else
  {
    $famsize{$g} = $n;
  }
}
close IN;

open OUT, ">famsizes-only.txt" or die "cannot open famsizes-only.txt $!";
for my $i (keys %famsize)
{
  print OUT "$i\t$famsize{$i}\n";
}
close OUt;


=comment
     59 ORTHOMCL0-1
     59 ORTHOMCL0-2
      5 ORTHOMCL1000
      6 ORTHOMCL100-1
      6 ORTHOMCL1001-1
=comment
