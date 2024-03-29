sub createSquareMatrix ($) {
  my ($n) = @_;
  my @m;
  for (my $i = 0; $i < $n; $i++)
  {
    my @rowMap = (0) x $n;
    push @m, [ @rowMap ];
  }
  return @m;
}

sub printSquareMatrix ($$) {
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

sub create3DMatrix ($$$$) {
  my ($d1, $d2, $d3, $initialValue) = @_;

  my @m;
  for (my $i = 0; $i < $d1; $i++)
  {
    my @mapPerLineage;
    for (my $j = 0; $j < $d2; $j++)
    {
      my @asinglemap = ($initialValue) x ($d3);
      push @mapPerLineage, [ @asinglemap ];
    }
    push @m, [ @mapPerLineage ];
  }
  return @m;
}

sub peachArrayCreate2DMatrix ($$$) {
  my ($d1, $d2, $initialValue) = @_;

  my @m;
  for (my $i = 0; $i < $d1; $i++)
  {
    my @mapPerLineage = ($initialValue) x ($d2);
    push @m, [ @mapPerLineage ];
  }
  return @m;
}
1;
