#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombination-intensity3.pl
#   Date: 2011-04-27
#   Version: 1.0
#
#   Usage:
#      perl recombination-intensity3.pl [options]
#
#      Try 'perl recombination-intensity3.pl -h' for more information.
#
#   Purpose: recombination-intensity3.pl help you compute recombinant edge counts
#            along a genome. This was based on recombination-intensity.pl.
#            Use one of genomes as a reference for genomic positions. For each
#            site I test if it is affected by any recombinant edge.
#            I have realized that this is harder than I thought. I am given a
#            gene and its genomic location. I need to find their position in the
#            mauve alignment. Using the location I can see if the gene
#            experienced recombinant edges. I need to take the genome alignment
#            as input. 
#            1. Find the block that a gene is in. Stop if no blocks contain the
#            gene.
#            2. Use the DNA sequence of the reference gene to locate sites that
#            are covered by the gene. I could extract DNA sequences to double
#            check the gene is correctly identified.
#            3. Use the located sites to check how often the gene experienced
#            recombinant edges.
#
#   Note that I started to code this based on PRINSEQ by Robert SCHMIEDER at
#   Computational Science Research Center @ SDSU, CA as a template. Some of
#   words are his not mine, and credit should be given to him. 
#===============================================================================
use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'recombination-intensity3.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'd=s',
            'xmfa=s',
            'r=i',
            'coords=s',
            'check',
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombination-intensity3.pl - Compute probability of recombination along a
reference genome.

=head1 VERSION

recombination-intensity3.pl 1.0

=head1 SYNOPSIS

perl recombination-intensity3.pl [-h] [-help] [-version] 
  [-d xmlfile basename] [-r reference genome]

=head1 DESCRIPTION

Matt suggests a measure of probability of recombination of a gene. It is rather
intuitive compared with counting number of types of recombinant edges. I check
if a site is affected by any recombinant edges. One of the genomes is a
reference for genomic location.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-man>

Print the full documentation; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-d> <xmlfile base name>

The clonal origin output XML files share a base name: e.g.,
cornellf/3/run-clonalorigin/output2/1a/core_co.phase3.xml. The XML file names
are suffixed by dot and block ID.

=item B<-xmfa> <xmfa alignment base name>

The clonal origin input alignment files share a base name: e.g.,
cornellf/3/data/core_alignment.xmfa.
The XMFA file names are suffixed by dot and block ID.

=item B<-r> <reference genome>

The XML files contain a clonal frame. I use one of genomes in the clonal frame
as a reference genome for genomic locations.

=item B<-coords> <gene coordinates file>

The file is tab delimited with columns
1. geneid
2. start (1 indexed)
3. end (inclusive)
4. strand (1 -1)

For example,
SDE12394_00005  2       1357    1    
SDE12394_00010  1511    2647    1    
SDE12394_00015  2721    2918    1

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make recombination-intensity3.pl better.

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

require "pl/sub-simple-parser.pl";
require "pl/sub-newick-parser.pl";

sub get_length_all_blocks ($);
sub locate_gene_in_block ($$$$);

#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $xmlDir;
my $xmfaBasename;
my $refGenome;
my $coordsFile;
my $check = 0;
if (exists $params{d})
{
  $xmlDir = $params{d};
}
else
{
  &printError("you did not specify a XML file base name of Clonal Origin 2nd stage");
}

if (exists $params{xmfa})
{
  $xmfaBasename = $params{xmfa};
}
else
{
  &printError("you did not specify a XMFA file base name");
}

if (exists $params{r})
{
  $refGenome = $params{r};
}
else
{
  &printError("you did not specify a reference genome");
}

if (exists $params{coords})
{
  $coordsFile = $params{coords};
}
else
{
  &printError("you did not specify a coordinate file that contains genes");
}

if (exists $params{check})
{
  $check = 1;
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

################################################################################
# Global variables.
################################################################################
my @sites;
my $isRecombined;
my $countRecombined;
my $tag;
my $content;
my %recedge;
my $itercount=0;

my @xmlFiles = <$xmlDir.*>; # The pair of double quotaton marks are critical.
my $numberBlock = $#xmlFiles + 1;

################################################################################
# Find coordinates of the reference genome.
################################################################################

my @blockLocationGenome;
for (my $i = 1; $i <= $numberBlock; $i++)
{
  my $xmfaFile = "$xmfaBasename.$i";
  open XMFA, $xmfaFile or die "Could not open $xmfaFile";
  while (<XMFA>) 
  {
    if (/^>\s+$refGenome:(\d+)-(\d+)/)
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

if ($check == 1)
{
  for (my $i = 0; $i <= $#blockLocationGenome; $i++)
  {
    my $href = $blockLocationGenome[$i];
    print "$i:$href->{start} - $href->{end}\n"; 
  }
}


# 1. Find the block that a gene is in. Stop if no blocks contain the gene.
# For example,
# SDE12394_00005        2       1357    1
open COORD, "$coordsFile" or die "Could not open $coordsFile";
while (<COORD>)
{
  chomp;
  my @columns = split /\t/;
  my $nameGene = $columns[0];
  my $startGene = $columns[1];
  my $endGene = $columns[2];
  my $strandGene = $columns[3];
  my $blockidGene = -1;
  for (my $i = 0; $i <= $#blockLocationGenome; $i++)
  {
    my $href = $blockLocationGenome[$i];
    if ($href->{start} <= $startGene and $endGene <= $href->{end})
    {
      $blockidGene = $i + 1;
      last;
    }
  }
  if ($blockidGene > 0)
  {
    my $href = $blockLocationGenome[$blockidGene - 1];
    if ($check == 1) {
      print "$nameGene ($startGene,$endGene) in $blockidGene:$href->{start} - $href->{end}\t"; 
    }
    # 2. Use the DNA sequence of the reference gene to locate sites that
    # are covered by the gene. I could extract DNA sequences to double
    # check the gene is correctly identified.
    @sites = locate_gene_in_block ("$xmfaBasename.$blockidGene",
                                   $refGenome, 
                                   $startGene,
                                   $endGene);
    # 3. Use the located sites to check how often the gene experienced
    # recombinant edges.
    my $f = "$xmlDir.$blockidGene";
    my $parser = new XML::Parser();
    $parser->setHandlers(Start => \&startElement,
                         End => \&endElement,
                         Char => \&characterData,
                         Default => \&default);
    $itercount = 0;
    $countRecombined = 0;
    my $doc;
    eval{ $doc = $parser->parsefile($f)};
    print "Unable to parse XML of $f, error $@\n" if $@;
    my $prob = $countRecombined / $itercount;
    if ($check == 1) {
      print "($sites[0],$sites[$#sites]) $prob\n";
    }
    print "$nameGene\t$startGene\t$endGene\t$strandGene\t$prob\n";
  }
  else
  {
    if ($check == 1) {
      print "$nameGene was not found in the blocks\n";
    }
    my $prob = -1;
    print "$nameGene\t$startGene\t$endGene\t$strandGene\t$prob\n";
  }
}
close COORD;

exit;
#
################################################################################
## END OF DATA PROCESSING
################################################################################
#

#
################################################################################
## FUNCTION DEFINITION
################################################################################
#

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

sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
  $tag = $element;
  SWITCH: {
    if ($element eq "Iteration") 
    {
      $itercount++;
      $isRecombined = 0;
      last SWITCH;
    }
    if ($element eq "recedge") {
      last SWITCH;
    }
  }
}

sub endElement {
  my ($p, $elt) = @_;

  if ($elt eq "start") {
    $recedge{start} = $content;
  }
  if ($elt eq "end") {
    $recedge{end} = $content;
  }
  if ($elt eq "efrom") {
    $recedge{efrom} = $content;
  }
  if ($elt eq "eto") {
    $recedge{eto} = $content;
  }
  if ($elt eq "afrom") {
    $recedge{afrom} = $content;
  }
  if ($elt eq "ato") {
    $recedge{ato} = $content;
  }

  if ($elt eq "recedge")
  {
    if ($isRecombined == 0)
    {
      for (my $i = 0; $i <= $#sites; $i++)
      {
        if ($recedge{start} <= $sites[$i] and $sites[$i] < $recedge{end})
        {
          $isRecombined = 1;
          last;
        }
      }
    }
  }

  if ($elt eq "Iteration") 
  {
    if ($isRecombined == 1)
    {
      $countRecombined++;
    }
  }
  $content = "";
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;

  $content .= $data;
}

sub default {
}

##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'recombination-intensity3.pl -h\' for more information.\nExit program.\n";
    exit(0);
}

sub locate_gene_in_block ($$$$)
{
  my ($f, $r, $s, $e) = @_;
  my @v;
  my $startGenome;
  my $endGenome;
  my $line;
  my $sequence = "";
  my $geneSequence = "";
  open XMFA, $f or die "Could not open $f";
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>\s+$r:(\d+)-(\d+)/)
    {
      $startGenome = $1;
      $endGenome = $2;
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

#print STDERR "\n$s-$e-$startGenome-$endGenome-$f\n";
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
      if ($s <= $pos and $pos <= $e)
      {
        push @v, $i;
        $geneSequence .= $nucleotides[$i];
      }
      $j++;
    }
  }
  #print "\n$geneSequence\n";

  close XMFA;
  return @v;
}

