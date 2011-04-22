#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extractClonalOriginParameter8.pl
#   Date: Thu Apr 21 12:42:10 EDT 2011
#   Version: 1.0
#
#   Usage:
#      perl extractClonalOriginParameter8.pl [options]
#
#      Try 'perl extractClonalOriginParameter8.pl -h' for more information.
#
#   Purpose: This is based on extractClonalOriginParameter4.pl. The detailed
#            code will be different from it. 
#            extractClonalOriginParameter8.pl help you build heat map of 
#            recombination events. 
#            This is used with simulation.
#            A heat map is a matrix of size being number of species by number of
#            species. 
# 
#            The expected number of recedges a priori is given by ClonalOrigin's
#            gui program that makes a matrix. The matrix dimension depends on
#            the number of taxa in the clonal frame. Another matrix should be
#            built and its element is an average observed recedes. I divide the
#            latter matrix by the former one element-by-element. For each block
#            I follow the computation above to obtain an odd-ratio matrix. 
#            For each element over all the blocks I weight it by the length of
#            the block to have an average odd-ratio.
#
#   Note that I started to code this based on PRINSEQ by Robert SCHMIEDER at
#   Computational Science Research Center @ SDSU, CA as a template. Some of
#   words are his not mine, and credit should be given to him. 
#===============================================================================

use strict;
use warnings;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'extractClonalOriginParameter8.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'd=s',
            'e=s',
            'n=i',
            's=i',
            'append',
            'check'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extractClonalOriginParameter8.pl - Build a heat map of recombination.

=head1 VERSION

extractClonalOriginParameter8.pl 0.1.0

=head1 SYNOPSIS

perl extractClonalOriginParameter8.pl [-h] [-help] [-version] 
  [-d xml data directory] 
  [-e per-block heat map directory] 
  [-n number of blocks] 
  [-s number of species] 

=head1 DESCRIPTION

The expected number of recedges a priori is given by ClonalOrigin's
gui program that makes a matrix. The matrix dimension depends on
the number of taxa in the clonal frame. Another matrix should be
built and its element is an average observed recedes. I divide the
latter matrix by the former one element-by-element. For each block
I follow the computation above to obtain an odd-ratio matrix. 
For each element over all the blocks I weight it by the length of
the block to have an average odd-ratio.

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

=item B<-d> <directory>

A directory that contains the 2nd phase run result from Clonal Origin.

=item B<-e> <directory>

A directory that contains files with prior expected number of recombinations.

=item B<-n> <number>

The number of blocks. Both directories must have pairs of files for each block.

=item B<-s> <number>

The number of species.

=item B<-append>

Among all of the repetition the first one is created, and the rest of them are
appended. Default is not using append option, and the output file will be
generated.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extractClonalOriginParameter8.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

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
sub get_exp_map($$);
sub get_obs_map($$);
sub get_obs_map_iteration($$$);

my $xmlDir;
my $heatDir;
my $numBlocks;
my $numSpecies;
my $append = 0;
my $check = 0;

if (exists $params{d})
{
  $xmlDir = $params{d};
}
else
{
  &printError("you did not specify a directory that contains Clonal Origin 2nd run results");
}

if (exists $params{e})
{
  $heatDir = $params{e};
}
else
{
  &printError("you did not specify a directory that contains prior number of recombination");
}

if (exists $params{n})
{
  $numBlocks = $params{n};
}
else
{
  &printError("you did not specify a number of blocks");
}

if (exists $params{s})
{
  $numSpecies = $params{s};
}
else
{
  &printError("you did not specify a number of species");
}

if (exists $params{append})
{
  $append = 1;
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

##############################################################
# Global variables
##############################################################
my $tag;
my $content;
my %recedge;
my $itercount=0;
my $xmlIteration;

##############################################################
# An initial heat map is created.
##############################################################
my $numberOfTaxa = $numSpecies;
my $numberOfLineage = 2 * $numberOfTaxa - 1;

my @heatMap;
for (my $j = 0; $j < $numberOfLineage; $j++)
{
  my @rowMap = (0) x $numberOfLineage;
  push @heatMap, [ @rowMap ];
}
my @obsMap;
for (my $j = 0; $j < $numberOfLineage; $j++)
{
  my @rowMap = (0) x $numberOfLineage;
  push @obsMap, [ @rowMap ];
}
my @expMap;
for (my $j = 0; $j < $numberOfLineage; $j++)
{
  my @rowMap = (0) x $numberOfLineage;
  push @expMap, [ @rowMap ];
}

my @blockObsMap;
my $blockLength;
my $totalLength;

if ($check == 1)
{
  print "xmlDir:$xmlDir\n";
}

##############################################################
# Find the sample size of an Clonal Origin XML.
##############################################################
my $xmlfilename = "$xmlDir/core_co.phase3.1.xml";
my $sampleSizeFirst = get_sample_size ($xmlfilename);
for (my $blockid = 2; $blockid <= $numBlocks; $blockid++)
{
  my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
  my $sampleSize = get_sample_size ($xmlfilename);
  die "The first block ($sampleSizeFirst) and the $blockid-th block ($sampleSize) are different"
    unless $sampleSizeFirst == $sampleSize;
}
if ($check == 1)
{
  print "sampleSizeFirst:$sampleSizeFirst\n";
}

##############################################################
# Find the total length of all the blocks.
##############################################################
$totalLength = 0;
for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
{
  my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
  my $blockLength = get_block_length ($xmlfilename);
  $totalLength += $blockLength;
}
if ($check == 1)
{
  print "totalLength:$totalLength\n";
}

##############################################################
# Find the expected number of recombination over all of the blocks.
##############################################################
for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
{
  my $heatfilename = "$heatDir/heatmap-$blockid.txt";
  my @expMapBlock = get_exp_map($heatfilename, $numberOfLineage);

  for my $i ( 0 .. $#expMap ) {
    for my $j ( 0 .. $#{ $expMap[$i] } ) {
      $expMap[$i][$j] += $expMapBlock[$i][$j];
    }
  }
}
if ($check == 1)
{
  print "expMap:\n";
  for my $i ( 0 .. $#expMap ) {
    print "  ";
    for my $j ( 0 .. $#{ $expMap[$i] } ) {
      print "[$i][$j] $expMap[$i][$j] ";
    }
    print "\n";
  }
}

##############################################################
# Find the observed number of recombination over all of the blocks
# and take the ratio of observed with respect to expected.
##############################################################
for (my $iterationid = 1; $iterationid <= $sampleSizeFirst; $iterationid++)
{
  
  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
    $xmlIteration = $iterationid;
    my @obsMapBlock = get_obs_map_iteration($iterationid, $xmlfilename, $numberOfLineage);

    for my $i ( 0 .. $#obsMap ) {
      for my $j ( 0 .. $#{ $obsMap[$i] } ) {
        $obsMap[$i][$j] += $obsMapBlock[$i][$j];
      }
    }

    if ($check == 1)
    {
      print "obsMapBlock (Iter: $iterationid - Block: $blockid):\n";
      for my $i ( 0 .. $#obsMapBlock ) {
        print "  ";
        for my $j ( 0 .. $#{ $obsMapBlock[$i] } ) {
          print "[$i][$j] $obsMapBlock[$i][$j] ";
        }
        print "\n";
      }
    }
    print STDERR "$iterationid - $blockid\n"
  }
}

if ($check == 1)
{
  print "obsMap before division by sampleSize:\n";
  for my $i ( 0 .. $#obsMap ) {
    print "  ";
    for my $j ( 0 .. $#{ $obsMap[$i] } ) {
      print "[$i][$j] $obsMap[$i][$j] ";
    }
    print "\n";
  }
}

for my $i ( 0 .. $#obsMap ) {
  for my $j ( 0 .. $#{ $obsMap[$i] } ) {
    $obsMap[$i][$j] /= $sampleSizeFirst;
  }
}

if ($check == 1)
{
  print "obsMap:\n";
  for my $i ( 0 .. $#obsMap ) {
    print "  ";
    for my $j ( 0 .. $#{ $obsMap[$i] } ) {
      print "[$i][$j] $obsMap[$i][$j]";
    }
    print "\n";
  }
}

for my $i ( 0 .. $#heatMap ) {
  for my $j ( 0 .. $#{ $heatMap[$i] } ) {
    if ($expMap[$i][$j] > 0)
    {
      $heatMap[$i][$j] = $obsMap[$i][$j] / $expMap[$i][$j];
    }
  }
}

if ($check == 1)
{
  print "heatMap:\n";
  for my $i ( 0 .. $#heatMap ) {
    print "  ";
    for my $j ( 0 .. $#{ $heatMap[$i] } ) {
      print "[$i][$j] $heatMap[$i][$j]";
    }
    print "\n";
  }
}

############################################################
# Compute the sample variance.
############################################################
my @heatVarMap;
for (my $j = 0; $j < $numberOfLineage; $j++)
{
  my @rowMap = (0) x $numberOfLineage;
  push @heatVarMap, [ @rowMap ];
}

for (my $iterationid = 1; $iterationid <= $sampleSizeFirst; $iterationid++)
{
  my @obsMapIteration;
  for (my $j = 0; $j < $numberOfLineage; $j++)
  {
    my @rowMap = (0) x $numberOfLineage;
    push @obsMapIteration, [ @rowMap ];
  }

  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
    $xmlIteration = $iterationid;
    my @obsMapBlock = get_obs_map_iteration($iterationid, $xmlfilename, $numberOfLineage);

    for my $i ( 0 .. $#obsMap ) {
      for my $j ( 0 .. $#{ $obsMap[$i] } ) {
        $obsMapIteration[$i][$j] += $obsMapBlock[$i][$j];
      }
    }
  }

  for my $i ( 0 .. $#heatVarMap ) {
    for my $j ( 0 .. $#{ $heatVarMap[$i] } ) {
      my $v = $obsMapIteration[$i][$j] - $obsMap[$i][$j];
      $heatVarMap[$i][$j] += ($v * $v);
    }
  }
}

for my $i ( 0 .. $#heatVarMap ) {
  for my $j ( 0 .. $#{ $heatVarMap[$i] } ) {
    if ($expMap[$i][$j] > 0)
    {
      $heatVarMap[$i][$j] = sqrt ($heatVarMap[$i][$j]/$sampleSizeFirst) / $expMap[$i][$j];
    }
  }
}

##############################################################
# Print the resulting heat map.
##############################################################
for my $i ( 0 .. $#heatMap ) {
  for my $j ( 0 .. $#{ $heatMap[$i] } ) {
    unless ($i == 0 and $j == 0) {
      print "\t";
    }
    print $heatMap[$i][$j];
  }
}
for my $i ( 0 .. $#heatVarMap ) {
  for my $j ( 0 .. $#{ $heatVarMap[$i] } ) {
    print "\t";
    print $heatVarMap[$i][$j];
  }
}
print "\n";

exit;
##############################################################
# END OF RUN OF THIS PERL SCRIPT
##############################################################

sub get_exp_map($$)
{
  my ($infilename, $numElements) = @_;
  my @expMap;

  # Count multiple hits of a short read.
  open FILE, "$infilename" or die "$! - $infilename";
  my $line;
  # Three lines of head of the heat map file.
  for (my $i = 0; $i < 3; $i++)
  {
    $line = <FILE>;
  }

  # Next lines of expected heat map values.
  for (my $i = 0; $i < $numElements; $i++)
  {
    $line = <FILE>;
#print "[ $numElements ]\n";
#print "[ $infilename ]\n";
#print "[ $line ]\n";
    chomp($line);
    my @elements = split /,/, $line;
    push @expMap, [ @elements ];    
  }
  close(FILE);
  return @expMap;
}

sub get_obs_map($$)
{
  my ($f, $numElements) = @_;

  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  @blockObsMap = ();
  for (my $j = 0; $j < $numElements; $j++)
  {
    my @rowMap = (0) x $numElements;
    push @blockObsMap, [ @rowMap ];
  }
  $itercount=0;

  my $doc;
  eval{ $doc = $parser->parsefile($f)};
  die "Unable to parse XML of $f, error $@\n" if $@;
  return @blockObsMap;
}

sub get_obs_map_iteration($$$)
{
  my ($iterationid, $f, $numElements) = @_;

  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  @blockObsMap = ();
  for (my $j = 0; $j < $numElements; $j++)
  {
    my @rowMap = (0) x $numElements;
    push @blockObsMap, [ @rowMap ];
  }
  $itercount=0;

  my $doc;
  eval{ $doc = $parser->parsefile($f)};
  die "Unable to parse XML of $f, error $@\n" if $@;
  return @blockObsMap;
}

#############################################################
# XML Parsing functions
#############################################################

sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
  $tag = $element;
  SWITCH: {
    if ($element eq "Iteration") {
      $itercount++;
      last SWITCH;
    }
  }
}

sub endElement {
  my ($p, $elt) = @_;

  if ($elt eq "efrom") {
    $recedge{efrom} = $content;
  }
  if ($elt eq "eto") {
    $recedge{eto} = $content;
  }

  if ($elt eq "recedge")
  {
    if ($xmlIteration == $itercount) {
      $blockObsMap[$recedge{efrom}][$recedge{eto}]++;
    }
  }
  
  $tag = "";
  $content = "";
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;

  if ($tag eq "efrom" or $tag eq "eto")
  {
    $content .= $data;
  }

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
    print STDERR "ERROR: ".$msg.".\n\nTry \'extractClonalOriginParameter8.pl -h\' for more information.\nExit program.\n";
    exit(0);
}

sub getLineNumber {
    my $file = shift;
    my $lines = 0;
    open(FILE,"perl -p -e 's/\r/\n/g' < $file |") or die "ERROR: Could not open file $file: $! \n";
    $lines += tr/\n/\n/ while sysread(FILE, $_, 2 ** 16);
    close(FILE);
    return $lines;
}


sub checkFileFormat {
    my $file = shift;

    open(FILE,"perl -p -e 's/\r/\n/g' < $file |") or die "ERROR: Could not open file $file: $! \n";
    while (<FILE>) {
    }
    close(FILE);

    my $format = 'map';
    return $format;
}





