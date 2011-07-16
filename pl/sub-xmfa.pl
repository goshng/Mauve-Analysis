###############################################################################
# Copyright (C) 2011 Sang Chul Choi
#
# This file is part of Mauve Analysis.
# 
# Mauve Analysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mauve Analysis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mauve Analysis.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

sub maXmfaDotNumberGetSequence ($$)
{
  my ($f,$r) = @_;
  my $line;
  my $sequence = "";
  open XMFA, $f or die "Could not open $f $!";
  while ($line = <XMFA>)
  {
    chomp $line;
    next if $line =~ /^#/;
    last if $line =~ /^>\s+$r:(\d+)-(\d+)/;
  }
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>/)
    {
      last;
    }
    $sequence .= $line; 
  }
  close (XMFA);
  return $sequence;
}

sub maXmfaGetCoordinatesRefgenome ($$)
{
  my ($f, $r) = @_;
  my @blockLocationGenome;

  my $v = 1;
  open XMFA, $f or die "cannot open $f: $!";
  while (<XMFA>)
  {
    if (/^=/)
    {
      $v++;
    }

    if (/^>\s+$r:(\d+)-(\d+)/)
    {
      my $startGenome = $1;
      my $endGenome = $2;
      my $rec = {};
      $rec->{start} = $startGenome;
      $rec->{end} = $endGenome;
      push @blockLocationGenome, $rec;
    }
  }
  close XMFA;
  return @blockLocationGenome;
}

sub maXmfaLocateGene ($$$$$$)
{
  my ($f, $blockid, $r, $s, $e, $strand) = @_;
  my $startGenome;
  my $endGenome;
  my $strandGenome;
  my $sequence = "";

  die "Problems in gene coordinate $s < $e" unless $s < $e;
  my $b = {};

  my $v = 1;
  open XMFA, $f or die "cannot open $f: $!";
  while (<XMFA>)
  {
    if (/^=/)
    {
      $v++;
    }

    if (/^>\s+$r:(\d+)-(\d+)\s+([+-])\s+/ and $v == $blockid)
    {
      $startGenome = $1;
      $endGenome = $2;
      $strandGenome = $3;
      last;
    }
  }
  $b->{start} = $startGenome;
  $b->{end} = $endGenome;
  $b->{strand} = $strandGenome;
  die "strand must be + or -" 
    unless $strandGenome eq '+' or $strandGenome eq '-';
  $g->{start} = $s;
  $g->{end} = $e;

  # Block        |--------------------|
  # Tyep 1:          <---->
  # Type 2: <----------------------------->
  # Type 3:   <------>
  # Type 4:                        <----->
  # Type 5: <-->                           <----->
  my $gType;
  if (($b->{start} <= $g->{start} and $g->{start} <= $b->{end}) and
      ($b->{start} <= $g->{end} and $g->{end} <= $b->{end}))
  {
    $gType = 1;
  }
  elsif ($g->{start} < $b->{start} and $b->{end} < $g->{end})
  {
    $gType = 2;
    $s = $b->{start};
    $e = $b->{end};
  }
  elsif ($g->{start} < $b->{start} and 
         ($b->{start} <= $g->{end} and $g->{end} <= $b->{end}))
  {
    $gType = 3;
    $s = $b->{start};
  }
  elsif (($b->{start} <= $g->{start} and $g->{start} <= $b->{end}) and
         $b->{end} < $g->{end})
  {
    $gType = 4;
    $e = $b->{end};
  }
  elsif ($g->{end} < $b->{start} or $b->{end} < $g->{start})
  {
    $gType = 5;
  }
  else
  {
    die "Impossible type of gene location w.r.t. blocks";
  }
  die "The gene must be in the block" if $gType == 5;

  # gene's strand does not matter because I need gene's position.
  # genome + and gene +
  # genome + and gene -
  # genome - and gene +
  # genome - and gene -

  # $sequence is obtained for the reference genome.
  my $line;
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>/)
    {
      last;
    }
    $sequence .= $line;
  }
  close XMFA;

  # I am ready to find the position of the gene in the block.
  my $geneStartBlock = -1;
  my $geneEndBlock = -1;
  my $j = 0;
  my $blockLength = length $sequence;
  my @nucleotides = split //, $sequence;
  if ($strandGenome eq '-')
  {
    @nucleotides = reverse @nucleotides; 
  }
  for (my $i = 0; $i <= $#nucleotides; $i++)
  {
    if ($nucleotides[$i] =~ /^[acgtACGT]$/)
    #if ($nucleotides[$i] eq 'a' 
        #or $nucleotides[$i] eq 'c' 
        #or $nucleotides[$i] eq 'g' 
        #or $nucleotides[$i] eq 't') 
    {
      my $pos = $startGenome + $j;   
      if ($e == $pos && $geneStartBlock > -1)
      {
        $geneEndBlock = $i;
        last;
      }
      if ($s == $pos && $geneStartBlock == -1)
      {
        $geneStartBlock = $i;
      }

      $j++;
    }
  }
  if ($strandGenome eq '-')
  {
    my $geneBlockTemp = $geneStartBlock;
    $geneStartBlock = $blockLength - $geneEndBlock - 1;
    $geneEndBlock = $blockLength - $geneBlockTemp - 1;
  }
  my $lenGene = $geneEndBlock - $geneStartBlock + 1;
  my $geneSequence = substr $sequence, $geneStartBlock, $lenGene;

  my $percentageGap;
  my %count;
  $count{$_}++ foreach split //, $geneSequence;
  if (exists $count{"-"})
  {
    $percentageGap = $count{"-"} / $lenGene;
  }
  else
  {
    $percentageGap = 0;
  }

  $geneSequence =~ s/-//g;
  return ($geneStartBlock, $geneEndBlock, $geneSequence, $percentageGap, 
          $s, $e, $strandGenome); 
}

sub locateBlockGenome ($$)
{
  my ($f, $r) = @_;
  my $startGenome;
  my $endGenome;
  my $strand;

  open XMFA, $f or die "Could not open $f $!";
  while (<XMFA>)
  {
    chomp; 
    if (/^>\s+$r:(\d+)-(\d+)\s+([+-])/)
    {
      $startGenome = $1;
      $endGenome = $2;
      $strand = $3;
      last;
    }
  }
  close XMFA;
  return ($startGenome, $endGenome, $strand);
}

sub getMidPosition ($)
{
  my ($f) = @_;
  my $v;
  open XMFA, $f or die $!;
  while (<XMFA>) {
    if (/^>\s+(\d+):(\d+)-(\d+)/) {
      die "$1 is not 1" unless $1 == 1;
      $v = ($2 + $3)/2;
      last;
    }
  }
  close XMFA;
  return $v;
}

sub locateNucleotideBlock ($$)
{
  my ($f, $r) = @_;
  my @v;
  my $startGenome;
  my $endGenome;
  my $line;
  my $sequence = "";
  my $geneSequence = "";
  my $strand;
  open XMFA, $f or die "Could not open $f";
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>\s+$r:(\d+)-(\d+)\s+([+-])/)
    {
      $startGenome = $1;
      $endGenome = $2;
      $strand = $3;
      last;
    }
  }
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>/)
    {
      last;
    }
    $sequence .= $line;
  }
  close XMFA;

  my @nucleotides = split //, $sequence;
  return @nucleotides;
}

sub xmfaLengthBlock ($)
{
  my ($f) = @_;
  my $line;
  my $sequence = "";
  open XMFA, $f or die "Could not open $f $!";
  while ($line = <XMFA>)
  {
    chomp $line;
    next if $line =~ /^#/;
    last if $line =~ /^>/;
  }
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>/)
    {
      last;
    }
    $sequence .= $line; 
  }
  close (XMFA);
  return length($sequence);
}

sub xmfaLengthAllBlock ($)
{
  my ($f) = @_;
  my $line;
  my $sequence = "";
  open XMFA, $f or die "Could not open $f $!";
  while ($line = <XMFA>)
  {
    chomp $line;
    next if $line =~ /^#/;
    if ($line =~ /^>/)
    {
      while ($line = <XMFA>)
      {
        chomp $line;
        if ($line =~ /^>/)
        {
          last;
        }
        $sequence .= $line; 
      }

      while ($line = <XMFA>)
      {
        chomp $line;
        last if $line =~ /^=/;
      }
    }
  }
  close (XMFA);
  return length($sequence);
}

sub xmfaNumberBlock ($)
{
  my ($f) = @_;
  my $line;
  my $c = 0;
  open XMFA, $f or die "Could not open $f $!";
  while ($line = <XMFA>)
  {
    if ($line =~ /^=/)
    {
      $c++;
    }
  }
  return $c;
}

sub xmfaBlockSize ($)
{
  my ($f) = @_;
  my $line;
  my $blockSize = "";
  my $sequence = "";
  open XMFA, $f or die "Could not open $f $!";
  while ($line = <XMFA>)
  {
    chomp $line;
    next if $line =~ /^#/;
    if ($line =~ /^>/)
    {
      while ($line = <XMFA>)
      {
        chomp $line;
        if ($line =~ /^>/)
        {
          last;
        }
        $sequence .= $line; 
      }
      $blockSize = sprintf ("%s %d", $blockSize, length($sequence));
      $sequence = "";

      while ($line = <XMFA>)
      {
        chomp $line;
        last if $line =~ /^=/;
      }
    }
  }
  close (XMFA);
  return $blockSize;
}

# 
sub getBlockConfiguration ($$$)
{
  my ($refgenome, $xmfa, $numberblock) = @_;
  my @blockLocationGenome;
  for my $i (1 .. $numberblock)
  {
    my $xmfaFile = "$xmfa.$i";
    open XMFA, $xmfaFile or die "Could not open $xmfaFile";
    while (<XMFA>) 
    {
      if (/^>\s+$refgenome:(\d+)-(\d+)/)
      {
        my $startGenome = $1;
        my $endGenome = $2;
        my $rec = {};
        $rec->{start} = $startGenome;
        $rec->{end} = $endGenome;
        push @blockLocationGenome, $rec;
        last;
      }
    }
    close XMFA;
  }
  return @blockLocationGenome;
}

sub getBlockSizeConfiguration ($$)
{
  my ($xmfa, $numberblock) = @_;
  my @blockLocationGenome;
  my $currentPosition = 1; # Points to the first base of the DNA sequence 
  for my $i (1 .. $numberblock)
  {
    my $xmfaFile = "$xmfa.$i";
    my $blockSize = xmfaBlockSize ($xmfaFile);

    my $startGenome = $currentPosition;
    $currentPosition += $blockSize;
    my $endGenome = $currentPosition - 1;
    my $rec = {};
    $rec->{start} = $startGenome;
    $rec->{end} = $endGenome;
    push @blockLocationGenome, $rec;
  }
  # The end of the last block is equal to the size of the total blocks.
  return @blockLocationGenome;
}

sub maXmfaGetBlockStart ($)
{
  my ($xmfa) = @_;
  my $numberblock = xmfaNumberBlock ($xmfa);
  my @blockStart;
  my $currentPosition = 0;
  for my $i (1 .. $numberblock)
  {
    push @blockStart, $currentPosition;
    my $xmfaFile = "$xmfa.$i";
    my $blockSize = xmfaBlockSize ($xmfaFile);
    $currentPosition += $blockSize;
  }
  return @blockStart;
}

1;
__END__
=head1 NAME

sub-xmfa.pl - Parsers of XMFA files

=head1 SYNOPSIS

  my @blockLocationGenome = maXmfaGetCoordinatesRefgenome ($xmfa, $r);

=head1 VERSION

v1.0, Sun May 15 18:11:38 EDT 2011

=head1 DESCRIPTION

An XMFA file is a version of FASTA format file. It is generated by a sequence
alignment called mauve. The header of a sequence starts with a bracket `>' and
includes the index of a sequence and positions in the genome. The following is
an exmaple.

  > 1:3424-8780 + /tmp/1081728.scheduler.v4linux/input/CP002215.gbk

=head1 FUNCTIONS

=over 4

=item sub maXmfaGetBlockStart ($)

  Argument 1: XMFA file name
  Return: Array of indices of start position of blocks in the total blocks.

=item sub maXmfaGetCoordinatesRefgenome ($$)

  Argument 1: XMFA file name
  Argument 2: Reference genome ID
  Return: Array of genome coordinates of all the blocks

=item sub maXmfaLocateGene ($$$$$)

  Argument 1: XMFA file name
  Argument 2: Block ID 1-base
  Argument 3: Reference genome ID
  Argument 4: Start of the gene
  Argument 4: End of the gene
  Return: start and end positions in the block, sequence of the gene, and
          proportion of gap in the sequence 

=item sub locateBlockGenome ($$)

  Argument 1: XMFA file name
  Argument 2: Index of a sequence
  Return: an array of start position, end poisition, and its strand

=item sub locateNucleotideBlock ($$)

  Argument 1: XMFA file name
  Argument 2: Index of a sequence
  Return: the sequence in PERL array

=item sub getBlockConfiguration ($$$)

  Argument 1: Reference genome ID
  Argument 2: XMFA file base name with .[number].
  Argument 3: Number of blocks

=item sub getBlockSizeConfiguration ($$)

  Argument 1: XMFA file base name with .[number].
  Argument 2: Number of blocks

=item sub maXmfaDotNumberGetSequence ($$)

  Argument 1: XMFA.# file
  Argument 2: Reference genome index
  Return: Sequence

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 COPYRIGHT

Copyright (C) 2011 Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

