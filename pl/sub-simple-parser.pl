# Author: Sang Chul Choi
# Date  : Thu Apr 21 13:08:50 EDT 2011

# Some parts of Clonal Origin XML output files can be parsed by searching
# line-by-line without using XML parser such as expat.

# Gets the length of a block.
sub get_block_length($) {
  my ($f) = @_;
  my $v = 0;
  open IN, $f or die "$!: $f is not found";
  while (<IN>)
  {
    if (/^<Blocks>/)
    {
      my $line = <IN>;
      chomp $line;
      $line =~ s/.+\,//g;
      $v = $line;
      last;
    }
  }
  close IN;
  return $v;
}

sub get_sample_size($) {
  my ($f) = @_;
  my $v = 0;
  open IN, $f or die "$!: $f is not found";
  while (<IN>)
  {
    if (/^<Iteration>/)
    {
      $v++;
    }
  }
  close IN;
  return $v;
}


1;
