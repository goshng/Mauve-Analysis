#!/opt/local/bin/perl -w
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
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: count-observed-recedge.pl
#   Date: Fri Apr 29 14:54:00 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);
require "pl/sub-error.pl";
require "pl/sub-simple-parser.pl";
require "pl/sub-array.pl";
require "pl/sub-heatmap.pl";
require "pl/sub-newick-parser.pl";
sub makeXMLFilename($$$$);
sub get_exp_map($$);
sub get_obs_map_iteration($$);

my $cmd = ""; 
sub process {
  my ($a) = @_; 
  $cmd = $a; 
}
$| = 1; # Do not buffer output
my $VERSION = 'count-observed-recedge.pl 1.0';
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
            'out=s',
            'meanonly',
            'meanfile=s',
            'xmlbasename=s',
            'endblockid',
            'append',
            'obsonly',
            'check',
            '<>' => \&process
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $xmlDir;
my $heatDir = "";
my $numBlocks;
my $numSpecies;
my $obsonly = 0;
my $meanonly = 0;
my $meanfile = "";
my $append = 0;
my $check = 0;
my $xmlBasename = "core_co.phase3";
my $endblockid = 0;
my $outfile;

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

if (exists $params{n})
{
  $numBlocks = $params{n};
}


if (exists $params{s})
{
  $numSpecies = $params{s};
}

if (exists $params{append})
{
  $append = 1;
}

if (exists $params{meanonly})
{
  $meanonly = 1;
}

if (exists $params{meanfile})
{
  $meanfile = $params{meanfile};
}

if (exists $params{check})
{
  $check = 1;
}

if (exists $params{xmlbasename})
{
  $xmlBasename = $params{xmlbasename};
}

if (exists $params{endblockid})
{
  $endblockid = 1;
}

if (exists $params{out})
{
  open ($outfile, ">", $params{out}) or die "cannot open > $params{out}: $!";
}
else
{
  $outfile = *STDOUT;   
}

if ($cmd eq "obsonly")
{
  $obsonly = 1;
  unless ($heatDir eq "")
  {
    &printError("obsonly is used without -e option");
  }
  unless (exists $params{n})
  {
    &printError("you did not specify a number of blocks");
  }
}

################################################################################
## DATA PROCESSING
################################################################################

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

# Find the first XML file to get the species tree.
my $blockid = 1;
my $xmlfilename = makeXMLFilename($xmlDir, $xmlBasename, $blockid, $endblockid);
my $treeString = get_species_tree ($xmlfilename);
$numSpecies = get_number_leave ($treeString);
# Find the number of XML files.
while (-e $xmlfilename)
{
  $blockid++;
  $xmlfilename = makeXMLFilename($xmlDir, $xmlBasename, $blockid, $endblockid);
}
unless ($numBlocks == $blockid - 1)
{
  die "-n $numBlocks and $blockid - 1 are not equal";
}

# Create matrices.
my $numberOfTaxa = $numSpecies;
my $numberOfLineage = 2 * $numberOfTaxa - 1;
my $sizeOfMatrix = $numberOfLineage * $numberOfLineage; 
my @heatMap = createSquareMatrix ($numberOfLineage);
my @obsMap = createSquareMatrix ($numberOfLineage);
my @expMap = createSquareMatrix ($numberOfLineage);
my @matrixXML;
my @matrixXMLPerBlock;
my @matrixXMLPerBlockPerIteration;
my @blockObsMap;
my $blockLength;
my $totalLength;

if ($check == 1)
{
  print "xmlDir:$xmlDir\n";
}

##############################################################
# Find the sample size of an Clonal Origin XML. All of the XML files are check
# if they have the same posterior sample size.
##############################################################
$xmlfilename = makeXMLFilename($xmlDir, $xmlBasename, 1, $endblockid);
my $sampleSizeFirst = get_sample_size ($xmlfilename);
for (my $blockid = 2; $blockid <= $numBlocks; $blockid++)
{
  $xmlfilename = makeXMLFilename($xmlDir, $xmlBasename, $blockid, $endblockid);
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
  $xmlfilename = makeXMLFilename($xmlDir, $xmlBasename, $blockid, $endblockid);
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
if ($obsonly == 0)
{
  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    my $heatfilename = "$heatDir/$blockid.txt";
    my @expMapBlock = get_exp_map($heatfilename, $numberOfLineage);

    for my $i ( 0 .. $#expMap ) {
      for my $j ( 0 .. $#{ $expMap[$i] } ) {
        $expMap[$i][$j] += $expMapBlock[$i][$j];
      }
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
# For each of iteration and blocks I count the number of recombinant edges for
# all of the pairs of species branches. obsMap is the sum of all of the observed
# recombinant edges over all. 
#
# NOTE: Compare it with that of
# extractClonalOriginParameter12.pl. I do not have a for-loop for iteration.
#
# Preparation of a matrix. 
# ------------------------
# I need a matrix of size being
# (number of blocks) x (MCMC sample size) 
# x (number of species) x (number of species).
# @matrixXML contains these. The following code could have been done in the mean
# computation above. I repeat it anyway.
##############################################################
if ($meanfile eq "")
{
  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    $xmlfilename = makeXMLFilename($xmlDir, $xmlBasename, $blockid, $endblockid);
    $xmlIteration = -1; # Note $xmlIteration is a global.
    @matrixXMLPerBlock = ();
    my @obsPerBlockPerIteration = get_obs_map_iteration($xmlfilename, $numberOfLineage);
    push @matrixXML, [ @matrixXMLPerBlock ];

    for my $i ( 0 .. $#obsMap ) {
      for my $j ( 0 .. $#{ $obsMap[$i] } ) {
        $obsMap[$i][$j] += $obsPerBlockPerIteration[$i][$j];
      }
    }

    if ($check == 1)
    {
      for my $i ( 0 .. $#obsPerBlockPerIteration ) {
        print "  ";
        for my $j ( 0 .. $#{ $obsPerBlockPerIteration[$i] } ) {
          print "[$i][$j] $obsPerBlockPerIteration[$i][$j] ";
        }
        print "\n";
      }
    }
    print STDERR "Block: $blockid\r";
  }
  print STDERR "Sample mean - Finished!\n";

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

}
else
{
  # I have to read obsMap only. 
  @obsMap = read_mean_obs_map($meanfile, $numberOfLineage);
}

if ($obsonly == 0)
{
  for my $i ( 0 .. $#heatMap ) {
    for my $j ( 0 .. $#{ $heatMap[$i] } ) {
      if ($expMap[$i][$j] > 0)
      {
        $heatMap[$i][$j] = $obsMap[$i][$j] / $expMap[$i][$j];
      }
    }
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

  print "heatMap:\n";
  for my $i ( 0 .. $#heatMap ) {
    print "  ";
    for my $j ( 0 .. $#{ $heatMap[$i] } ) {
      print "[$i][$j] $heatMap[$i][$j]";
    }
    print "\n";
  }
}

if ($meanonly == 1)
{
  if ($obsonly == 0)
  {
    for my $i ( 0 .. $#heatMap ) {
      for my $j ( 0 .. $#{ $heatMap[$i] } ) {
        unless ($i == 0 and $j == 0) {
          print "\t";
        }
        print $heatMap[$i][$j];
      }
    }
    print "\n";
  }
  else
  {
    for my $i ( 0 .. $#obsMap ) {
      for my $j ( 0 .. $#{ $obsMap[$i] } ) {
        unless ($i == 0 and $j == 0) {
          print "\t";
        }
        print $obsMap[$i][$j];
      }
    }
    print "\n";
  }
  exit;
}

############################################################
# Compute the sample variance.
############################################################
my @heatVarMap = createSquareMatrix ($numberOfLineage);
my @obsVarMap = createSquareMatrix ($numberOfLineage);

for (my $iterationid = 1; $iterationid <= $sampleSizeFirst; $iterationid++)
{
  my @obsMapIteration = createSquareMatrix ($numberOfLineage);

  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    for my $i ( 0 .. $#obsMap ) {
      for my $j ( 0 .. $#{ $obsMap[$i] } ) {
        $obsMapIteration[$i][$j] += $matrixXML[$blockid - 1][$iterationid - 1][$i][$j];
      }
    }
    print STDERR "$iterationid - $blockid\r"
  }

  for my $i ( 0 .. $#obsVarMap ) {
    for my $j ( 0 .. $#{ $obsVarMap[$i] } ) {
      my $v = $obsMapIteration[$i][$j] - $obsMap[$i][$j];
      $obsVarMap[$i][$j] += ($v * $v);
    }
  }
}
print STDERR "Sample variance - Finished!\n";

for my $i ( 0 .. $#obsVarMap ) {
  for my $j ( 0 .. $#{ $obsVarMap[$i] } ) {
    $obsVarMap[$i][$j] /= $sampleSizeFirst;
  }
}

for my $i ( 0 .. $#heatVarMap ) {
  for my $j ( 0 .. $#{ $heatVarMap[$i] } ) {
    if ($obsonly == 0)
    {
      if ($expMap[$i][$j] > 0)
      {
        $heatVarMap[$i][$j] = sqrt ($obsVarMap[$i][$j]) / $expMap[$i][$j];
      }
    }
    else
    {
      $obsVarMap[$i][$j] = sqrt ($obsVarMap[$i][$j]);
    }
  }
}

##############################################################
# Print the resulting heat map.
##############################################################

if ($obsonly == 0)
{
  for my $i ( 0 .. $#heatMap ) {
    for my $j ( 0 .. $#{ $heatMap[$i] } ) {
      unless ($i == 0 and $j == 0) {
        print $outfile "\t";
      }
      print $heatMap[$i][$j];
    }
  }
  for my $i ( 0 .. $#heatVarMap ) {
    for my $j ( 0 .. $#{ $heatVarMap[$i] } ) {
      print $outfile "\t";
      print $outfile $heatVarMap[$i][$j];
    }
  }
  print $outfile "\n";
}
else
{
  for my $i ( 0 .. $#obsMap ) {
    for my $j ( 0 .. $#{ $obsMap[$i] } ) {
      unless ($i == 0 and $j == 0) {
        print $outfile "\t";
      }
      print $outfile $obsMap[$i][$j];
    }
  }
  for my $i ( 0 .. $#obsVarMap ) {
    for my $j ( 0 .. $#{ $obsVarMap[$i] } ) {
      print $outfile "\t";
      print $outfile $obsVarMap[$i][$j];
    }
  }
  print $outfile "\n";
}

exit;
##############################################################
# END OF RUN OF THIS PERL SCRIPT
##############################################################

# XML file name is completed by combining the directory name, base name, and
# block ID. The position of block ID relative to xml file extension is
# determined by the 4th argument.
sub makeXMLFilename($$$$) {
  my ($xmlDir, $xmlBasename, $i, $endblockid) = @_;
  my $xmlfilename = "$xmlDir/$xmlBasename.$i.xml";
  if ($endblockid == 1)
  {
    $xmlfilename = "$xmlDir/$xmlBasename.xml.$i";
  }
  return $xmlfilename;
}

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
    chomp($line);
    my @elements = split /,/, $line;
    push @expMap, [ @elements ];    
  }
  close(FILE);
  return @expMap;
}

sub get_obs_map_iteration($$)
{
  my ($f, $numElements) = @_;

  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  # @blockObsMap and $itercount are global.
  @blockObsMap = createSquareMatrix ($numElements);
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
      @matrixXMLPerBlockPerIteration = createSquareMatrix ($numberOfLineage);
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
    if ($xmlIteration == -1 or $xmlIteration == $itercount) {
      $blockObsMap[$recedge{efrom}][$recedge{eto}]++;
    }
    $matrixXMLPerBlockPerIteration[$recedge{efrom}][$recedge{eto}]++;
  }

  if ($elt eq "Iteration")
  {
    push @matrixXMLPerBlock, [ @matrixXMLPerBlockPerIteration ];
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

__END__
=head1 NAME

count-observed-recedge.pl - Count the number of recombinant edges

=head1 VERSION

count-observed-recedge.pl 1.0

=head1 SYNOPSIS

perl count-observed-recedge.pl [-h] [-help] [-version] 
  [-d xml data directory] 
  [-e per-block heat map directory] 
  [-n number of blocks] 
  [-s number of species] 
  [-xmlbasename filename]
  [-endblockid]
  [-obsonly]
  [-meanonly]
  [-append]
  [-meanfile an output file from meanonly option]

perl pl/count-observed-recedge.pl obsonly -d output -endblockid -obsonly -n 274 -s 5

=head1 DESCRIPTION

This is almost the same as extractClonalOriginParameter8.pl except that this
actually uses the prior expected number of recombinant edges. It may be possible
to have a single script by combining this and extractClonalOriginParameter8.pl.
I do not know exactly how I can deal with the prior.

The expected number of recedges a priori is given by ClonalOrigin's
gui program that makes a matrix. The matrix dimension depends on
the number of taxa in the clonal frame. Another matrix should be
built and its element is an average observed recedes. I divide the
latter matrix by the former one element-by-element. For each block
I follow the computation above to obtain an odd-ratio matrix. 
For each element over all the blocks I weight it by the length of
the block to have an average odd-ratio.

Input XML files: <xml directory>/<xml basename>.[blockid] are read. 

Situation 1: I wish to compute the average number of recombinant edges just
by counting and averaging it by the number of sample size or iterations in the
ClonalOrigin MCMC XML output.

-meanonly -obsonly

Situation 2: I wish to compute the ratio of average number of recombinant edges
relative to the prior expected number of recombinant edges.

-meanonly

Situation 3: I wish to compute the average number of recombination and its
standard deviation across MCMC sample.

-obsonly

Situation 4: I wish to compute the average number of recombination and its
standard deviation across MCMC sample by considering prior expected number of
recombinant edges.

Default options (or neither meanonly nor obsonly).

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

=item B<-d> <xml directory>

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

=item B<-obsonly>

Prior expected numbers of recombinant edges are ignored.

=item B<-meanonly>

Average numbers of recombinant edges are computed.

=item B<-meanfile> <file>

An output file from meanonly option.

=item B<-endblockid>

The clonal origin XML file names can be
s8_1_core_alignment.xml.1 or
core_co.phase3.1.xml.
The base names are s8_1_core_alignment or core_co.phase3. 
The block id can follow xml or precede it. Default is to precede it: i.e.,
core_co.phase3.1.xml is the default.

=item B<-xmlbasename> <name>

The clonal origin XML file names can be
s8_1_core_alignment.xml.1 or
core_co.phase3.1.xml.
The base names are s8_1_core_alignment or core_co.phase3. 
Default base name is core_co.phase3.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make count-observed-recedge.pl better.

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

