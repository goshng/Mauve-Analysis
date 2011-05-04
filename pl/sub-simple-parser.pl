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

# Get length of all of the blocks.
sub get_length_all_blocks ($)
{
  my ($prefix) = @_;
  my $r = 0;
  my $blockID = 1;
  my $f = "$prefix.$blockID";
  while (-e $f)
  {
    $r += get_block_length ($f);
    $blockID++;
    $f = "$prefix.$blockID";
  }
  $blockID--;
  return $r; 
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

sub get_header_coxml ($) {
  my ($f) = @_;
  my $v = "";
  my $l;
  open IN, $f or die "$!: $f is not found";
  while ($l = <IN>)
  {
    if (/^<Iteration>/)
    {
      last;
    }
    $v .= $l;
  }
  close IN;
  return $v;
}

# Get the species tree of a block.
sub get_species_tree ($)
{
  my ($f) = @_;
  my $r;
  open XML, $f or die "$f $!";
  while (<XML>)
  {
    if (/^<Tree>/)
    {
      $r = <XML>;
      chomp ($r);
      last;
    }
  } 
  close (XML); 
  die "The $f does not contain a species tree" unless defined $r;
  return $r;
}

sub get_genome_length ($)
{
  my ($f) = @_;
  open GENBANK, $f or die "$f could not be opened";
  my $l = <GENBANK>;
  my @e = split /\s+/, $l;
  close GENBANK;
  return $e[2];
}

1;
