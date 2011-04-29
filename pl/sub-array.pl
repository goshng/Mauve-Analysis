sub createSquareMatrix {
  my ($n) = @_;
  my @m;
  for (my $i = 0; $i < $n; $i++)
  {
    my @rowMap = (0) x $n;
    push @m, [ @rowMap ];
  }
  return @m;
}

sub printSquareMatrix {
  my ($m, $n) = @_;
  for (my $i = 0; $i < $n; $i++)
  {
    for (my $j = 0; $j < $n; $j++)
    {
      print "\t";
      print $m->[$i][$j];
    }
    print "\n";
  }
}

1;
