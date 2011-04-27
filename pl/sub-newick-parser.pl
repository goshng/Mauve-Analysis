# Author: Sang Chul Choi
# Date  : Wed Apr 27 13:24:04 EDT 2011

# Find the number of leaves of a rooted tree.
# (((0:4.359500e-02,1:4.359500e-02)5:1.951410e-01,2:2.387360e-01)7:8.480900e-02,(3:7.356900e-02,4:7.356900e-02)6:2.499760e-01)8:0.000000e+00; 
sub get_number_leave ($)
{
  my ($newickTree) = @_;
  my $r = 0;
  my $s = $newickTree;
  print $s, "\n";
  my @elements = split (/[\(\),]/, $s);
  for (my $i = 0; $i <= $#elements; $i++)
  {
    if (length $elements[$i] > 0)
    {
      $r++;
    }
  }
  $r = ($r + 1) / 2;

  return $r;
}



1;
