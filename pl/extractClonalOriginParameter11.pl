#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extractClonalOriginParameter11.pl
#   Date: Thu Apr 21 12:42:10 EDT 2011
#   Version: 1.0
#
#   Usage:
#      perl extractClonalOriginParameter11.pl [options]
#
#      Try 'perl extractClonalOriginParameter11.pl -h' for more information.
#
#   Purpose: For each block I grab an <Iteration>. Pull all of the Iteration to
#            make an XML file with a single clonal frame with its recombinant
#            edges. 
#            1. Find block lengths.
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

my $VERSION = 'extractClonalOriginParameter11.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'd=s',
            'speciesDir=s',
            'n=i',
            'endblockid'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extractClonalOriginParameter11.pl - Build a heat map of recombination.

=head1 VERSION

extractClonalOriginParameter11.pl 0.1.0

=head1 SYNOPSIS

perl extractClonalOriginParameter11.pl [-h] [-help] [-version] 
  [-xml xmlfile] 

=head1 DESCRIPTION

An XML Clonal Origin file is divided into files for multiple blocks.

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

=item B<-d> <clonal origin output2>

A directory that contains clonal origin XML output files of the 2nd stage.

=item B<-n> <number of subsample>

An integer number. Default is 10.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extractClonalOriginParameter11.pl better.

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

my $xmlDir;
my $numberSubsample = 10;
my $xmlBasename = "core_co.phase3";
my $endblockid = 0;
my $check = 0;
my $speciesDir;

if (exists $params{d})
{
  $xmlDir= $params{d};
}
else
{
  &printError("you did not specify an XML file directory that contains Clonal Origin 2nd run results");
}

if (exists $params{speciesDir})
{
  $speciesDir = $params{speciesDir};
}
else
{
  &printError("you did not specify species directory");
}

if (exists $params{n})
{
  $numberSubsample = $params{n};
}

if (exists $params{endblockid})
{
  $endblockid = 1;
}


#
################################################################################
## DATA PROCESSING
################################################################################
#
sub get_iteration($);

##############################################################
# Global variables
##############################################################
my $iterationContent;
my $sampleIter;
my $offset;
my $treeFile;

my $delta;
my $rho;
my $Lt;           # Total length of all of the blocks
my $numberBlock; 
my @blocks;
my $tag;
my $content;
my %recedge;
my $itercount=0;


##############################################################
# Find number of blocks.
##############################################################
my @xmlFiles;
if ($endblockid == 1)
{
  @xmlFiles =  <$xmlDir/$xmlBasename.xml.*>;
}
else
{
  @xmlFiles =  <$xmlDir/$xmlBasename.*.xml>;
}
my $numBlocks = $#xmlFiles + 1;

##############################################################
# Find the sample size of an Clonal Origin XML.
##############################################################
my $xmlfilename = "$xmlDir/$xmlBasename.1.xml";
if ($endblockid == 1)
{
  $xmlfilename = "$xmlDir/$xmlBasename.xml.1";
}
my $sampleSizeFirst = get_sample_size ($xmlfilename);
for (my $blockid = 2; $blockid <= $numBlocks; $blockid++)
{
  my $xmlfilename = "$xmlDir/$xmlBasename.$blockid.xml";
  if ($endblockid == 1)
  {
    $xmlfilename = "$xmlDir/$xmlBasename.xml.$blockid";
  }

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
my $totalLength = 0;
my @blockLengths;
push @blockLengths, 0;
for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
{
  my $xmlfilename = "$xmlDir/$xmlBasename.$blockid.xml";
  if ($endblockid == 1)
  {
    $xmlfilename = "$xmlDir/$xmlBasename.xml.$blockid";
  }

  my $blockLength = get_block_length ($xmlfilename);
  $totalLength += $blockLength;
  push @blockLengths, $totalLength;
}
if ($check == 1)
{
  print "totalLength:$totalLength\n";
}

my $subsampleInterval = int ($sampleSizeFirst/$numberSubsample);
for (my $replicateID = 1; $replicateID <= $numberSubsample; $replicateID++)
{
  $sampleIter = $subsampleInterval * $replicateID;
  my $xmlFile = "$speciesDir/$replicateID/data/core_alignment.xml";
  $treeFile = "$speciesDir/$replicateID/run-clonalorigin/input/1/in.tree";
  my $blockFile = "$speciesDir/$replicateID/data/in.block";
  open BLOCK, ">$blockFile" or die "$blockFile could not be craeted";
  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    my $bl = $blockLengths[$blockid] - $blockLengths[$blockid - 1];
    print BLOCK "$bl\n";
  }
  close BLOCK;
  #my $xmlFile = "$speciesDir-$replicateID-data-core_alignment.xml";

  open XML, ">$xmlFile" or die "$xmlFile could not be created";
  # Print the header of the XML file.
  print XML "<?xml version = '1.0' encoding = 'UTF-8'?>\n";
  print XML "<outputFile>\n<Blocks>\n";
  print XML join (",", @blockLengths);
  print XML "\n</Blocks>\n";
  print XML "<comment>$sampleIter</comment>\n";
  print XML "<nameMap></nameMap>\n";
  print XML "<regions>0</regions>\n";
  print XML "<Iteration>\n";
  for (my $blockid = 1; $blockid <= $numBlocks; $blockid++)
  {
    my $xmlfilename = "$xmlDir/$xmlBasename.$blockid.xml";
    if ($endblockid == 1)
    {
      $xmlfilename = "$xmlDir/$xmlBasename.xml.$blockid";
    }

    $offset = $blockLengths[$blockid - 1];
    get_iteration ($xmlfilename);
    print XML $iterationContent;
print STDERR "$replicateID: $blockid\r";
  }
  print XML "</Iteration>\n";
  print XML "</outputFile>\n";
  close XML;
}

exit;

sub get_iteration($)
{
  my ($f) = @_;

  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  $itercount=0;
  $iterationContent = "";
  my $doc;
  eval{ $doc = $parser->parsefile($f)};
  die "Unable to parse XML of $f, error $@\n" if $@;
  return;
}


sub print_xml_one_line ($$);

my $xmlFile;

##############################################################
# END OF RUN OF THIS PERL SCRIPT
##############################################################

#############################################################
# XML Parsing functions
#############################################################

sub startElement {
  my ($parseinst, $e, %attrs) = @_;
#  $tag = $element;
  $content = "";
  if ($e eq "Iteration") {
    $itercount++;
  }
  if ($e eq "outputFile") {
    # The start of XML file.
  }
}

sub endElement {
  my ($p, $elt) = @_;
  my $eltname;
  if ($elt eq "Blocks") {
    @blocks = split /,/, $content;
  }

  if ($sampleIter == $itercount and $offset == 0)
  {
    $eltname = "Tree";
    if ($elt eq $eltname) {
      $iterationContent .= "<Tree>\n$content\n</Tree>\n";
      open TREE, ">$treeFile" or die "$treeFile could not be craeted";
      print TREE "$content\n";
      close TREE;
    }
    $eltname = "number";
    if ($elt eq $eltname) {
      $iterationContent .= "<number>-1</number>\n";
    }

    print_xml_one_line ("ll", $elt);
    print_xml_one_line ("prior", $elt);
    print_xml_one_line ("theta", $elt);
    print_xml_one_line ("rho", $elt);
    print_xml_one_line ("tmrca", $elt);
    print_xml_one_line ("esttheta", $elt);
    print_xml_one_line ("estvartheta", $elt);
    print_xml_one_line ("estrho", $elt);
    print_xml_one_line ("estdelta", $elt);
    print_xml_one_line ("estnumrecedge", $elt);
    print_xml_one_line ("estedgeden", $elt);
    print_xml_one_line ("estedgepb", $elt);
    print_xml_one_line ("estedgevarpb", $elt);
  }

  if ($sampleIter == $itercount)
  {
    $eltname = "recedge";
    if ($elt eq $eltname) {
      my $startBlock;
      my $endBlock;
      # 0   10000    20000   30000
      # 0..9999 
      # 10000..19999
      # 20000..29999
      my $start = $recedge{start} + $offset;
      my $end = $recedge{end} + $offset;
      $iterationContent .= "<recedge><start>$start<\/start><end>$end<\/end>";
      $iterationContent .= "<efrom>$recedge{efrom}<\/efrom>";
      $iterationContent .= "<eto>$recedge{eto}<\/eto>";
      $iterationContent .= "<afrom>$recedge{afrom}<\/afrom>";
      $iterationContent .= "<ato>$recedge{ato}<\/ato>";
      $iterationContent .= "<\/recedge>\n";
    }

    $eltname = "outputFile";
    if ($elt eq $eltname) {
    }

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
    print STDERR "ERROR: ".$msg.".\n\nTry \'extractClonalOriginParameter11.pl -h\' for more information.\nExit program.\n";
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

sub print_xml_one_line ($$) {
  my ($eltname, $elt) = @_;
  if ($elt eq $eltname) {
    $iterationContent .= "<$eltname>$content<\/$eltname>\n";
  }
}

