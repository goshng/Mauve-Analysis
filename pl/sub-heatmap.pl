require "pl/sub-array.pl";

sub read_mean_obs_map($$)
{
  my ($infilename, $numElements) = @_;
  my @m = createSquareMatrix($numElements); 

  # Count multiple hits of a short read.
  open FILE, "$infilename" or die "$! - $infilename";
  my $line = <FILE>;
  my @elements = split /\s+/, $line;

  for my $i ( 0 .. $#m ) {
    for my $j ( 0 .. $#{ $m[$i] } ) {
      $m[$i][$j] = $elements[$i * $numElements + $j];
    }
  }
  
  close FILE;

  return @m;
}

1;
