#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extractClonalOriginParameter5.pl
#   Date: 2011-04-13
#   Version: 1.0
#
#   Usage:
#      perl extractClonalOriginParameter5.pl [options]
#
#      Try 'perl extractClonalOriginParameter5.pl -h' for more information.
#
#   Purpose: extractClonalOriginParameter5.pl help you extract 3 main parameters
#            from the output XML file of ClonalOrigin.
#===============================================================================

use strict;
use warnings;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'extractClonalOriginParameter5.pl 0.1.0';

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
            's=i'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extractClonalOriginParameter5.pl - Build a heat map of recombination.

=head1 VERSION

extractClonalOriginParameter5.pl 0.1.0

=head1 SYNOPSIS

perl extractClonalOriginParameter5.pl [-h] [-help] [-version] 
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

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extractClonalOriginParameter5.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

sub get_exp_map($$);
sub get_obs_map($$);

my $xmlDir;
my $heatDir;
my $numBlocks;
my $numSpecies;

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


##############################################################
# An initial heat map is created.
##############################################################
my @heatMap;
my $numberOfTaxa = $numSpecies;
my $numberOfLineage = 2 * $numberOfTaxa - 1;
for (my $j = 0; $j < $numberOfLineage; $j++)
{
  my @rowMap = (0) x $numberOfLineage;
  push @heatMap, [ @rowMap ];
}
my @obsMap;
my @blockObsMap;
my $blockLength;
my $totalLength;

##############################################################
# Find the total length of all the blocks.
##############################################################
$totalLength = 0;
for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
{
  my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
  my @obsMap = get_obs_map($xmlfilename, $numberOfLineage);
  $totalLength += $blockLength;
}

for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
{
  my $heatfilename = "$heatDir/heatmap-$blockid.txt";
  my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
  my @expMap = get_exp_map($heatfilename, $numberOfLineage);

  my @obsMap = get_obs_map($xmlfilename, $numberOfLineage);

  # Debug
print "========================================\n";
print "expMap - block $blockid\n";
for my $i ( 0 .. $#expMap ) {
  print "$expMap[$i][0]";
  for my $j ( 1 .. $#{ $expMap[$i] } ) {
    print ",$expMap[$i][$j]";
  }
  print "\n";
}
print "----------------------------------------\n";
print "obsMap - block $blockid\n";
for my $i ( 0 .. $#obsMap ) {
  print "$obsMap[$i][0]";
  for my $j ( 1 .. $#{ $obsMap[$i] } ) {
    print ",$obsMap[$i][$j]";
  }
  print "\n";
}
print "----------------------------------------\n";
print "block length: $blockLength for block $blockid\n";
print "Total block length: $totalLength\n";
print "----------------------------------------\n";

  # blockLength is given.

  for my $i ( 0 .. $#heatMap ) {
    for my $j ( 0 .. $#{ $heatMap[$i] } ) {
      if ($expMap[$i][$j] > 0)
      {
        my $blockValue = ($blockLength / $totalLength); # weight
        $blockValue *= ($obsMap[$i][$j] / $expMap[$i][$j]);
        $heatMap[$i][$j] += $blockValue;
      }
    }
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

for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
{
  my $heatfilename = "$heatDir/heatmap-$blockid.txt";
  my $xmlfilename = "$xmlDir/core_co.phase3.$blockid.xml";
  my @expMap = get_exp_map($heatfilename, $numberOfLineage);

  my @obsMap = get_obs_map($xmlfilename, $numberOfLineage);

print "----------------------------------------\n";
print "block length: $blockLength for block $blockid\n";
print "Total block length: $totalLength\n";
print "----------------------------------------\n";

  # blockLength is given.
  for my $i ( 0 .. $#heatVarMap ) {
    for my $j ( 0 .. $#{ $heatVarMap[$i] } ) {
      if ($expMap[$i][$j] > 0)
      {
        my $blockValue = ($blockLength / $totalLength); # weight
        $blockValue *= (($heatMap[$i][$j] - $obsMap[$i][$j] / $expMap[$i][$j]) 
                       * ($heatMap[$i][$j] - $obsMap[$i][$j] / $expMap[$i][$j]));
        $heatVarMap[$i][$j] += $blockValue;
      }
    }
  }
}

##############################################################
# Print the resulting heat map.
##############################################################
for my $i ( 0 .. $#heatMap ) {
  print "$heatMap[$i][0]";
  for my $j ( 1 .. $#{ $heatMap[$i] } ) {
    print ",$heatMap[$i][$j]";
  }
  print "\n";
}
print "\n";
for my $i ( 0 .. $#heatVarMap ) {
  print "$heatVarMap[$i][0]";
  for my $j ( 1 .. $#{ $heatVarMap[$i] } ) {
    print ",$heatVarMap[$i][$j]";
  }
  print "\n";
}

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

sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
  SWITCH: {
    if ($element eq "Iteration") {
      $itercount++;
      last SWITCH;
    }
    if ($element eq "delta") {
      last SWITCH;
    }
    if ($element eq "rho") {
      last SWITCH;
    }
    if ($element eq "recedge") {
      last SWITCH;
    }
    if ($element eq "Tree") {
      $content = "";
      last SWITCH;
    }
  }
}

sub endElement {
  my ($p, $elt) = @_;
	$tag = "";
  if ($elt eq "Tree")
  {
    # No Code.

    # print STDERR $content, "\n";
  }
  if ($elt eq "recedge")
  {
    $blockObsMap[$recedge{efrom}][$recedge{eto}]++;

    #print $recedge{start}, "\t";
    #print $recedge{end}, "\t";
    #print $recedge{efrom}, "\t";
    #print $recedge{eto}, "\t";
    #print $recedge{afrom}, "\t";
    #print $recedge{ato}, "\n";
  }
  
  if ($elt eq "Iteration")
  {
    # No Code.
  }

  if ($elt eq "outputFile")
  {
    print STDERR "outFile: [ $blockLength ]\n";
    print STDERR "outFile: [ $itercount ]\n";
    for (my $j = 0; $j < $numberOfLineage; $j++)
    {
      for (my $k = 0; $k < $numberOfLineage; $k++)
      {
        $blockObsMap[$j][$k] /= $itercount;
      }
    }
  }
}

sub characterData {
       my( $parseinst, $data ) = @_;
	$data =~ s/\n|\t//g;
	if($tag eq "Tree"){
    $content .= $data;    
	}
	if($tag eq "start"){
    $recedge{start} = $data;
	}
	if($tag eq "end"){
    $recedge{end} = $data;
	}
	if($tag eq "efrom"){
    $recedge{efrom} = $data;
	}
	if($tag eq "eto"){
    $recedge{eto} = $data;
	}
	if($tag eq "afrom"){
    $recedge{afrom} = $data;
	}
	if($tag eq "ato"){
    $recedge{ato} = $data;
	}

	if($tag eq "Blocks"){
		if ($data =~ s/.+\,//g)
    {
      $blockLength = $data;
      print STDERR "Blocks: [ $blockLength ]\n";
    }
		#push( @lens, $data ) if(length($data)>1);
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
    print STDERR "ERROR: ".$msg.".\n\nTry \'extractClonalOriginParameter5.pl -h\' for more information.\nExit program.\n";
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





