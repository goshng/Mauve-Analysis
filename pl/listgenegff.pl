#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: listgenegff.pl
#   Date: 2011-02-10
#   Version: 0.1.0
#
#   Usage:
#      perl listgenegff.pl [options]
#
#      Try 'perl listgenegff.pl -h' for more information.
#
#   Purpose: listgenegff.pl help you to quantify import ratio of a given gene.
#
#   Note that I started to code this based on PRINSEQ by Robert SCHMIEDER at
#   Computational Science Research Center @ SDSU, CA as a template. Some of
#   words are his not mine, and credit should be given to him. 
#===============================================================================

use strict;
use warnings;

#use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);
use XML::Parser;

$| = 1; # Do not buffer output

my $VERSION = 'listgenegff.pl 0.1.0';

my $man = 0;
my $help = 0;
my $perblock = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man, 'perblock' => \$perblock);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'gff=s',
            'alignment=s',
            'clonalOrigin=s',
            'taxon=i',
            'ns=i',
            'perblock'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

listgenegff.pl - Compute import ratio of all genes in the blocks

=head1 VERSION

listgenegff.pl 0.1.0

=head1 SYNOPSIS

perl listgenegff.pl.pl [-h] [-help] [-version] [-man] [-verbose] 
  [-gff genome_in_gff_format]
  [-alignment alignment_xmfa_format] 
  [-clonalOrigin output_directory_2nd_stage_clonal_origin]
  [-taxon number]

=head1 DESCRIPTION

listgenegff.pl will help you to measure import ratio of all the gene

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

=item B<-gff> <file>

A genome data file in gff format. A bacterial genome can be obtained from NCBI.

=item B<-alignment> <file>

An alignment file of species including the genome specified by -gff option.

=item B<-clonalOrigin> <directory>

An output directory of clonal origin that contains all the result file from the
2nd stage of clonal origin.

=item B<-taxon> <number>

The ordered number for the reference genome.

=item B<-ns> <number>

The number of species.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make listgenegff.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

################################################################
# Input command options
################################################################

sub locate_block ($$$$);
sub find_block_length ($$);
sub compute_import_ratio ($$$$);
sub compute_import_ratio_prev ($$$$);
sub compute_import_ratio_block ($);

my $gffFilename;
my $alignmentFilename;
my $clonalOriginDir;
my $taxon;
my $numberOfSpecies;
my $numberOfLineage;

if (exists $params{gff})
{
  $gffFilename = $params{gff};
} else {
  &printError("you did not specify an gff filename");
}

if (exists $params{alignment})
{
  $alignmentFilename = $params{alignment};
} else {
  &printError("you did not specify an alignment filename");
}

if (exists $params{clonalOrigin})
{
  $clonalOriginDir = $params{clonalOrigin};
} else {
  &printError("you did not specify an clonal origin directory");
}

if (exists $params{taxon})
{
  $taxon = $params{taxon};
} else {
  &printError("you did not specify a taxon");
}

if (exists $params{ns})
{
  $numberOfSpecies = $params{ns};
  $numberOfLineage = $numberOfSpecies * 2 - 1;
} else {
  &printError("you did not specify the number of species");
}

if ($taxon > $numberOfSpecies) 
{
  &printError("Taxon must be less than or equal to number of species");
}

################################################################
# 
################################################################

if ($perblock)
{
  for (my $blockid = 1; $blockid <= 419; $blockid++)
  {
    my ($leftBoundary, $rightBoundary, $start, $end) = find_block_length ($alignmentFilename, $blockid); 
    my ($importRatio, $sdeOverSpy) = compute_import_ratio ($blockid, $blockid, $leftBoundary, $rightBoundary);
    print "$blockid\t$start\t$end\t$blockid\t$leftBoundary\t$rightBoundary\t$importRatio\t$sdeOverSpy\n";
  }
}
else
{
  my $numGene = 0;
  my $gffLine;
  my $blockid_prev = 0;
  open GFF, "$gffFilename" or die $!;
  while ($gffLine = <GFF>)
  {
    if ($gffLine =~ /RefSeq\s+gene\s+(\d+)\s+(\d+).+locus_tag=(\w+);/)
    {
      my $start = $1;
      my $end = $2;
      my $locus_tag = $3; 
      my ($blockid, $leftBoundary, $rightBoundary) = locate_block ($alignmentFilename, $locus_tag, $start, $end); 
      if (defined $leftBoundary)
      {
        my $importRatio;
        my $sdeOverSpy;
        if ($blockid == $blockid_prev)
        {
          ($importRatio, $sdeOverSpy) = compute_import_ratio_prev ($locus_tag, $blockid, $leftBoundary, $rightBoundary);
        }
        else
        {
          # Use the blockid and region to compute import ratio.
          ($importRatio, $sdeOverSpy) = compute_import_ratio ($locus_tag, $blockid, $leftBoundary, $rightBoundary);
        }
        print "$locus_tag\t$start\t$end\t$blockid\t$leftBoundary\t$rightBoundary\t$importRatio\t$sdeOverSpy\n";
        $blockid_prev = $blockid;
      }
    } 
    if ($gffLine =~ /RefSeq\s+gene/)
    {
      $numGene++;
    }
  }
  close (GFF);
}
exit;

#################################################################################
### Main FUNCTIONS
#################################################################################

sub find_block_length ($$)
{
  my ($f, $blockid) = @_;
  my $id = 0;
  my $lineAlignment;

  my $start;
  my $end;
  my $blockBegin = 1;
  my $blockEnd;
  open ALIGNMENT, "$f" or die $!;
  while ($lineAlignment = <ALIGNMENT>)
  {
    if ($lineAlignment =~ /^>\s$taxon:(\d+)-(\d+)/)
    {
      $id++;
      if ($blockid == $id)
      {
        $start = $1;
        $end = $2;
        # print "$locus found at block $blockid\n";
        my $sequence;
        while ($lineAlignment = <ALIGNMENT>)
        {
          last if $lineAlignment =~ /^>/;
          chomp ($lineAlignment);
          $sequence .= $lineAlignment;
        }
        $blockEnd = length($sequence);
        last;
      }
    }
  }
  close (ALIGNMENT);
  return ($blockBegin, $blockEnd, $start, $end);
}

sub locate_block ($$$$)
{
  my ($f, $locus, $s, $e) = @_;
  my $blockBegin;
  my $blockEnd;
  my $blockid = 0;
  my $id = 0;
  my $lineAlignment;
  my $onlyonce = 0;
  open ALIGNMENT, "$f" or die $!;
  while ($lineAlignment = <ALIGNMENT>)
  {
    if ($lineAlignment =~ /^>\s$taxon:(\d+)-(\d+)/)
    {
      $id++;
      my $s2 = $1;
      my $e2 = $2;
      if ($s2 <= $s and $e <= $e2)
      {
        if ($onlyonce == 0)
        {
          $onlyonce = 1;
        }
        else
        {
          die "There are multiple blocks for the locus $locus";
        }
        $blockid = $id;
        # print "$locus found at block $blockid\n";
        my $sequence;
        while ($lineAlignment = <ALIGNMENT>)
        {
          last if $lineAlignment =~ /^>/;
          chomp ($lineAlignment);
          $sequence .= $lineAlignment;
        }
        # THIS IS NOT CLEAR YET.
        # Find the start position.
        $blockBegin = 0;
        $blockEnd = 0;
        my $ii = 0;
        my @nuc = split //, $sequence;
        for (my $i = 0; $i <= $#nuc; $i++)
        {
          if ($s2 + $ii == $s)
          {
            $blockBegin = $i;
          }
          if ($s2 + $ii == $e)
          {
            $blockEnd = $i; # from 0 to 2 inclusively.
            last;
          }
          if ($nuc[$i] eq '-')
          {
            #
          }
          else
          {
            #
            $ii++;
          }
        }
      }
    }
  }
  close (ALIGNMENT);
  return ($blockid, $blockBegin, $blockEnd);
}

my @mapImport;
my $importRatio;
my $sdeOverSpy;
my $blockLength;
sub compute_import_ratio_prev ($$$$)
{
  my ($locus, $blockid, $s, $e) = @_;

    $importRatio = 0;
    $sdeOverSpy = 0;
    my $toSPY = 0;
    my $toSDE = 0;
    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      if ($s <= $i and $i <= $e)
      { 
        for (my $j = 0; $j < $numberOfLineage; $j++)
        {
          for (my $k = 0; $k < $numberOfLineage; $k++)
          {
            $importRatio += $mapImport[$j][$k][$pos];
          }
        }
        $toSPY += $mapImport[0][3][$pos]
                    + $mapImport[0][4][$pos]
                    + $mapImport[1][3][$pos]
                    + $mapImport[1][4][$pos] + 0.001;
        $toSDE += $mapImport[3][0][$pos]
                    + $mapImport[3][1][$pos]
                    + $mapImport[4][0][$pos]
                    + $mapImport[4][1][$pos] + 0.001;
      }
    }
    die "locus[$locus] blockid[$blockid] s[$s], e[$e], blocklength[$blockLength]" if $toSPY == 0;
    $sdeOverSpy = ($toSDE/$toSPY);
    $importRatio /= ($e - $s + 1);
  return ($importRatio, $sdeOverSpy);
}

my $itercount;
my $tag;
my @blockImport;
my %recedge;
my $subblockStart;
my $subblockEnd;
my $content;
my @lens;
sub compute_import_ratio ($$$$)
{
  my ($locus, $blockid, $s, $e) = @_;

  # Compute import ratio
	my $fs = "$clonalOriginDir/core_co.phase3.$blockid.xml";

	my $parser = new XML::Parser();
	$parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  $subblockStart = $s;
  $subblockEnd = $e;
	$itercount=0;
	my $doc;
  print STDERR "Locus: [ $locus ]\t";
	eval{ $doc = $parser->parsefile($fs)};
	die "Unable to parse XML of $fs, error $@\n" if $@;
  return ($importRatio, $sdeOverSpy);
}

sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
  SWITCH: {
    if ($element eq "outputFile") {

      last SWITCH;
    }
    if ($element eq "Iteration") {
      $itercount++;

      # blockImport ...
      @blockImport = ();
      for (my $i = 0; $i < $numberOfLineage; $i++)
      {
        my @mapPerLineage;
        for (my $j = 0; $j < $numberOfLineage; $j++)
        {
          my @asinglemap = (0) x $blockLength;
          push @mapPerLineage, [ @asinglemap ];
        }
        push @blockImport, [ @mapPerLineage ];
      }
      if ($itercount == 1)
      {
        @mapImport = ();
        for (my $i = 0; $i < $numberOfLineage; $i++)
        {
          my @mapPerLineage;
          for (my $j = 0; $j < $numberOfLineage; $j++)
          {
            my @asinglemap = (0) x $blockLength;
            push @mapPerLineage, [ @asinglemap ];
          }
          push @mapImport, [ @mapPerLineage ];
        }
      }
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
  }
  if ($elt eq "recedge")
  {
    #print $recedge{start}, "\t";
    #print $recedge{end}, "\t";
    #print $recedge{efrom}, "\t";
    #print $recedge{eto}, "\t";
    #print $recedge{afrom}, "\t";
    #print $recedge{ato}, "\n";
    for (my $i = $recedge{start}; $i < $recedge{end}; $i++)
    {
      $blockImport[$recedge{eto}][$recedge{efrom}][$i]++;
    }
  }
  
  if ($elt eq "Iteration")
  {
    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      for (my $j = 0; $j < $numberOfLineage; $j++)
      {
        for (my $k = 0; $k < $numberOfLineage; $k++)
        {
          if ($blockImport[$j][$k][$pos] > 0) 
          {
            $blockImport[$j][$k][$pos] = 1;
          }
        }
      }
    }

    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      for (my $j = 0; $j < $numberOfLineage; $j++)
      {
        for (my $k = 0; $k < $numberOfLineage; $k++)
        {
          $mapImport[$j][$k][$pos] += $blockImport[$j][$k][$i];
        }
      }
    }
  }

  if ($elt eq "outputFile")
  {
    print STDERR "[ $blockLength ]\t";
    print STDERR "[ $itercount ]\n";
    $importRatio = 0;
    $sdeOverSpy = 0; 
    my $toSPY = 0;
    my $toSDE = 0;
    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      for (my $j = 0; $j < $numberOfLineage; $j++)
      {
        for (my $k = 0; $k < $numberOfLineage; $k++)
        {
          $mapImport[$j][$k][$pos] /= $itercount;
        }
      }
    }

    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      if ($subblockStart <= $i and $i <= $subblockEnd)
      { 
        for (my $j = 0; $j < $numberOfLineage; $j++)
        {
          for (my $k = 0; $k < $numberOfLineage; $k++)
          {
            $importRatio += $mapImport[$j][$k][$pos];
          }
        }
        # I have reversed it in the blockImport.
        # $blockImport[$recedge{eto}][$recedge{efrom}][$i]++;
        $toSDE += $mapImport[0][3][$pos]
                    + $mapImport[0][4][$pos]
                    + $mapImport[1][3][$pos]
                    + $mapImport[1][4][$pos] + 0.001;
        $toSPY += $mapImport[3][0][$pos]
                    + $mapImport[3][1][$pos]
                    + $mapImport[4][0][$pos]
                    + $mapImport[4][1][$pos] + 0.001;
      }
    }
    $sdeOverSpy = ($toSDE/$toSPY);
    $importRatio /= ($subblockEnd - $subblockStart + 1);
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
      print STDERR "Blocks: [ $blockLength ]\t";
    }
		push( @lens, $data ) if(length($data)>1);
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
    print STDERR "ERROR: ".$msg.".\n\nTry \'listgenegff.pl -h\' for more information.\nExit program.\n";
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

