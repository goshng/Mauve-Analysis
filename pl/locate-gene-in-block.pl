#!/usr/bin/perl
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: locate-gene-in-block.pl
#   Date: Fri May  6 23:16:57 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'locate-gene-in-block.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'ingene=s',
            'xmfa=s',
            'refgenome=i',
            'printseq'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

locate-gene-in-block.pl

=head1 VERSION

locate-gene-in-block.pl 1.0

=head1 SYNOPSIS

perl locate-gene-in-block.pl.pl [-h] [-help] [-version] [-verbose]
  [-ingene file] 
  [-xmfa core_alignment.xmfa] 
  [-refgenome number] 

=head1 DESCRIPTION

locate-gene-in-block.pl locates genes in blocks.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-ingene> <file>

An ingene file name.

=item B<-xmfa> <core_alignment.xmfa>

An input core alignment file.

=item B<-refgenome> <number>

An reference genome.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make locate-gene-in-block.pl better.

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

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $verbose = 0;
my $ingene;
my $xmfa;
my $refgenome;
my $printseq = 0;
if (exists $params{ingene}) {
  $ingene = $params{ingene};
} else {
  &printError("you did not specify a ingene file name");
}

if (exists $params{xmfa}) {
  $xmfa = $params{xmfa};
} else {
  &printError("you did not specify an xmfa file name");
}

if (exists $params{refgenome}) {
  $refgenome = $params{refgenome};
} else {
  &printError("you did not specify an refgenome file name");
}

if (exists $params{verbose}) {
  $verbose = 1;
}

if (exists $params{printseq}) {
  $printseq = 1;
}

################################################################################
## DATA PROCESSING
################################################################################

sub locate_gene($$$$$);
sub find_coordinates_refgenome ($$);
sub get_number_block ($);
sub locate_gene_in_block($$$); 

locate_gene_in_block($ingene, $xmfa, $refgenome); 

sub locate_gene_in_block($$$) {
  my ($ingene, $xmfa, $r) = @_;

  my $ingene2 = "$ingene.temp";
  open OUT, ">$ingene2" or die "$ingene2 could not be opened"; 

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
    push @genes, $rec;
  }
  close INGENE;

  my @blockLocationGenome = find_coordinates_refgenome ($xmfa, $r);
  if ($verbose == 1)
  {
    for (my $i = 0; $i <= $#blockLocationGenome; $i++)
    {
      my $h = $blockLocationGenome[$i];
      print STDERR "$i\t$h->{start}\t$h->{end}\n";
    }
  }
   
  for (my $i = 0; $i <= $#genes; $i++)
  {
    my $h = $genes[$i];
    my $blockidGene = -1;
    for (my $j = 0; $j <= $#blockLocationGenome; $j++)
    {
      my $g = $blockLocationGenome[$j];
      if ($g->{start} <= $h->{start} and $h->{end} <= $g->{end})
      {
        $blockidGene = $j + 1;
        last;
      }
    }

    if ($blockidGene > 0)
    {
      my $href = $blockLocationGenome[$blockidGene - 1];
      # 2. Use the DNA sequence of the reference gene to locate sites that
      # are covered by the gene. I could extract DNA sequences to double
      # check the gene is correctly identified.
      my ($s, $e, $seq, $gap) = locate_gene ($xmfa, $blockidGene,
                                             $r, 
                                             $h->{start},
                                             $h->{end});
      my $lenSeq = length $seq;
      if ($verbose == 1) {
        print STDERR "$h->{gene}\t$h->{start}\t$h->{end}\t$h->{strand}\t$blockidGene\t$s\t$e\n";
      }
      print OUT "$h->{gene}\t$h->{start}\t$h->{end}\t$h->{strand}\t$blockidGene\t$s\t$e";
      if ($printseq == 1)
      {
        #print OUT "\t$seq\t$lenSeq\t$gap\n";
        print OUT "\t$lenSeq\t$gap\n";
      }
      else
      {
        print OUT "\n";
      }
    }
    else
    {
      if ($verbose == 1) {
        print STDERR "$h->{gene} was not found in the blocks\n";
      }
    }
  }

  close OUT;

  rename $ingene2, $ingene;
}

################################################################################
# Find coordinates of the reference genome.
################################################################################

sub find_coordinates_refgenome ($$)
{
  my ($f, $r) = @_;
  my @blockLocationGenome;
  my $numberBlock = get_number_block ($f);

  my $v = 1;
  open XMFA, $f or die "$f could not be opened";
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


sub get_number_block ($)
{
  my ($f) = @_;
  my $v = 0;
  open XMFA, $f or die "$f could not be opened";
  while (<XMFA>)
  {
    if (/^=/)
    {
      $v++;
    }
  }
  close XMFA;
  return $v;
}

# Gene position in the block is 0-based location.
sub locate_gene($$$$$)
{
  my ($f, $blockid, $r, $s, $e) = @_;
  my $startGenome;
  my $endGenome;
  my $sequence = "";

  my $v = 1;
  open XMFA, $f or die "Could not open $f";
  while (<XMFA>)
  {
    if (/^=/)
    {
      $v++;
    }

    if (/^>\s+$r:(\d+)-(\d+)/ and $v == $blockid)
    {
      $startGenome = $1;
      $endGenome = $2;
      last;
    }
  }
  die "The gene is not in the block"
    unless $startGenome <= $s and $e <= $endGenome;

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

  my $geneStartBlock = -1;
  my $geneEndBlock = -1;
  my $j = 0;
  my @nucleotides = split //, $sequence;
  for (my $i = 0; $i <= $#nucleotides; $i++)
  {
    if ($nucleotides[$i] eq 'a' 
        or $nucleotides[$i] eq 'c' 
        or $nucleotides[$i] eq 'g' 
        or $nucleotides[$i] eq 't') 
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
  return ($geneStartBlock, $geneEndBlock, $geneSequence, $percentageGap); 
}


