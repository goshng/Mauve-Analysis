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
use strict;
use warnings;

require "pl/sub-array.pl";

my $verbose = 1;

sub maRiParse ($)
{
  my ($f) = @_;
  my $line;
  my $n1 = 0;
  open RI, $f or die "cannot open < $f: $!";
  $line = <RI>;
  $n1++;
  my @e = split /\t/, $line;
  my $n2 = sqrt($#e); # Matrix size
  while (<RI>)
  {
    $n1++;
  }
  close RI;

  # print STDERR "Creating rimap ..." if $verbose == 1;
  my @rimap = create3DMatrix ($n1, $n2, $n2, -1); 
  # print STDERR " done\n" if $verbose == 1;
  my $i = 0;
  open RI, $f or die "cannot open < $f: $!";
  while ($line = <RI>)
  {
    my @e = split /\t/, $line;
    for (my $j = 0; $j < $n2; $j++)
    {
      for (my $k = 0; $k < $n2; $k++)
      {
        $rimap[$i][$j][$k] = $e[1 + $j * $n2 + $k];
      }
    }
    $i++;
  }
  close RI;
  return \@rimap;
}

sub maRiPrint ($)
{
  
}

sub maRiGetGenes ($$$$$)
{
  my ($genes, $rimap, $blockStart, $pairM, $pairMSize) = @_;
  my $verbose = 1;
  # print STDERR "Parsing $rimap..." if $verbose == 1;
  my $riM = maRiParse ($rimap);
  # print STDERR "done" if $verbose == 1;

  for (my $i = 0; $i <= $#$genes; $i++)
  {
    # print STDERR "Gene $i/$#$genes\r" if $verbose == 1;
    my $g = $genes->[$i];
    my $blockidGene = $g->{blockidGene};
# gene start end strand blockidGene blockStart blockEnd 
# geneStartInBlock geneEndInBlock lenSeq gap

    my $ri1PerGene = 0;
    my $blockStartInAllBlock = $blockStart->[$blockidGene-1];
    for (my $j = $g->{blockStart}; $j < $g->{blockEnd}; $j++)
    {
      my $valuePerSite = 0; 
      for (my $k = 0; $k < $pairMSize; $k++)
      {
        for (my $l = 0; $l < $pairMSize; $l++)
        {
          if ($pairM->[$k][$l] == 1)
          {
            $valuePerSite += $riM->[$blockStartInAllBlock+$j][$k][$l];
          }
        }
      }
      $ri1PerGene += $valuePerSite; 
    }
    $g->{ri} = $ri1PerGene;
  }
}

1;
__END__

=head1 NAME

sub-ri.pl - Parsers of recombination intensity map files

=head1 SYNOPSIS

  my $fnaSequence = maFastaParse ($fna);

=head1 VERSION

v1.0, Sat Jul 16 15:41:17 EDT 2011

=head1 DESCRIPTION

Recombination intensity map file parser.

=head1 FUNCTIONS

=over 4

=item sub maRiParse ($)

  Argument 1: Recombination intesnity map file
  Return: Three dimensional matrix with values

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

