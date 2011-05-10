#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: analyze-run-clonalorigin2-simulation2-prepare.pl
#   Date: Wed May  4 14:38:21 EDT 2011
#   Version: 1.0
#===============================================================================
use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'analyze-run-clonalorigin2-simulation2-prepare.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'xml=s',
            'blockid=i',
            'xmfa=s',
            'ingene=s',
            'out=s',
            'realdataanalysis'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

analyze-run-clonalorigin2-simulation2-prepare.pl - Compute recombination intensity along the genome.

=head1 VERSION

analyze-run-clonalorigin2-simulation2-prepare.pl 1.0

=head1 SYNOPSIS

perl analyze-run-clonalorigin2-simulation2-prepare.pl 
  [-h] [-help] [-version] 
  [-d xml data directory] 
  [-xmlbasename xml file base name] 
  [-endblockid]
  [-xmfa genome alignment] 
  [-genelength integer] 
  [-n integer] 

=head1 DESCRIPTION

I wish to check if the recombination intensity can be recovered. Options -d,
-xmlbasename, and -endblockid stay put. Option -xmfa is also kept. Option gene
length is used to segment the alignment. I compute the recombination intensity
of each segment. 

I use the following two menus to find locations of genes in blocks:
convert-gff-ingene and locate-gene-in-block. I do not need -xmfa. All that I
need is ingene file. I do not need inblock either.

I may not need this -realdataanalysis option.

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

=item B<-xmfa> <alignment directory>

A directory that contains the input alignment.

=item B<-numberblock> <integer>

Number of blocks.

=item B<-genelength> <integer>

Length of genes.

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

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make analyze-run-clonalorigin2-simulation2-prepare.pl better.

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
require "pl/sub-array.pl";
require "pl/sub-ingene.pl";
sub get_genome_file ($$);
sub locate_block_in_genome ($$);
sub locate_nucleotide_in_block ($$);

#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $blockID;
my $xmlFile;
my $xmfaFile;
my $verbose = 0;
my $ingene;
my $realDataAnalysis = 0; 
my $outFile;
if (exists $params{out})
{
  $outFile = $params{out};
}
else
{
  &printError("you did not specify an output file");
}


if (exists $params{xml})
{
  $xmlFile = $params{xml};
}
else
{
  &printError("you did not specify a directory that contains Clonal Origin 2nd run results");
}

if (exists $params{blockid})
{
  $blockID = $params{blockid};
}
else
{
  &printError("you did not specify a block ID");
}

if (exists $params{realdataanalysis})
{
  $realDataAnalysis = 1;
}

if ($realDataAnalysis == 1)
{
  if (exists $params{xmfa})
  {
    $xmfaFile = $params{xmfa};
  }
  else
  {
    &printError("you did not specify an alignemnt file with realdata analysis");
  }
}

if (exists $params{ingene})
{
  $ingene = $params{ingene};
}
else
{
  &printError("you did not specify an ingene file");
}

if (exists $params{verbose})
{
  $verbose = 1;
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

my $tag;
my $content;
my %recedge;
my $itercount = 0;
my $blockLength;
my $speciesTree = get_species_tree ($xmlFile);
my $numberItartion = get_sample_size ($xmlFile);
my $numberTaxa = get_number_leave ($speciesTree);
my $numberLineage = 2 * $numberTaxa - 1;

# FIXME:
# convert-gff-ingene and locate-gene-in-block must be used to generate in.gene
# file for simulation s10 and s11.
# Do I need these?

# !!! NOTE !!!
# mapImport index is 1-based, and blockImmport index is 0-based.
# or map starts at 1, and  block starts at 0.
my @blockImport;
my @mapBlockImport;
if ($verbose == 1)
{
  print STDERR "A new mapImport is being created...";
}
$blockLength = get_block_length ($xmlFile);
my @mapImport = create3DMatrix ($numberLineage, 
                                $numberLineage, 
                                $blockLength + 1);
if ($verbose == 1)
{
  print STDERR " done.\n";
}

# mapImport is filled in.
my $offsetPosition = 0;
my $prevBlockLength = 1;

{
  $blockLength = get_block_length ($xmlFile);
  $offsetPosition += $prevBlockLength;
  $prevBlockLength = $blockLength;

  @mapBlockImport = create3DMatrix ($numberLineage, 
                                    $numberLineage, 
                                    $blockLength);
  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  $itercount = 0;
  my $doc;
  eval{ $doc = $parser->parsefile($xmlFile)};
  print "Unable to parse XML of $xmlFile, error $@\n" if $@;
  next if $@;
  
  for (my $pos = 0; $pos < $blockLength; $pos++)
  {
    for (my $j = 0; $j < $numberLineage; $j++)
    {
      for (my $k = 0; $k < $numberLineage; $k++)
      {
        $mapImport[$j][$k][$pos] = $mapBlockImport[$j][$k][$pos];
      }
    }
  }
}

################################################################################
# Find genes in the block.
################################################################################
sub map_recombination_intensity ($$$);

my @genes = parse_in_gene ($ingene);
map_recombination_intensity (\@genes, \@mapImport, $blockID);
# print_in_gene ($ingene, \@genes);

open OUT, ">$outFile" or die "$outFile could not be opened";

# Gene's RI's are printed out.
my $isFirst = 1;
for (my $i = 0; $i <= $#genes; $i++)
{
  my $h = $genes[$i];
  my $block = $h->{block};
  if ($blockID == $block)
  {
    if ($isFirst == 1)
    {
      $isFirst = 0;
      print OUT "$h->{gene}:";
    }
    else
    {
      print OUT "\t";
      print OUT "$h->{gene}:";
    }
    print OUT $h->{ri};
  }
}
print OUT "\n";
close OUT;

exit;

sub map_recombination_intensity ($$$)
{
  my ($genes, $mi, $blockID) = @_;
  for (my $i = 0; $i < scalar @{ $genes }; $i++)
  {
    my $h = $genes->[$i];
    my $block = $h->{block};
    if ($blockID == $block)
    {
      # Only genes in the current block are used.
      my $b = $h->{blockstart};
      my $e = $h->{blockend};
      my $v = 0;
      for (my $pos = $b; $pos <= $e; $pos++)
      {
        for (my $j = 0; $j < $numberLineage; $j++)
        {
          for (my $k = 0; $k < $numberLineage; $k++)
          {
            $v += $mi->[$j][$k][$pos];
          }
        }
      }
      $v /= ($e - $b + 1);
      $v /= $numberItartion;
      $h->{ri} = $v;
    }

  }
}

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

sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
  $tag = $element;
  SWITCH: {
    if ($element eq "Iteration") 
    {
      $itercount++;
      @blockImport = create3DMatrix ($numberLineage, 
                                     $numberLineage, 
                                     $blockLength);
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
  if ($elt eq "start") {
    $recedge{start} = $content;
  }
  if ($elt eq "end") {
    $recedge{end} = $content;
  }

  if ($elt eq "recedge")
  {
    for (my $i = $recedge{start}; $i < $recedge{end}; $i++)
    {
      # NOTE: efrom -> eto. This used to be eto -> efrom.
      $blockImport[$recedge{efrom}][$recedge{eto}][$i]++;
    }
  }
  if ($elt eq "Iteration")
  {
    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      for (my $j = 0; $j < $numberLineage; $j++)
      {
        for (my $k = 0; $k < $numberLineage; $k++)
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
      for (my $j = 0; $j < $numberLineage; $j++)
      {
        for (my $k = 0; $k < $numberLineage; $k++)
        {
          $mapBlockImport[$j][$k][$pos] += $blockImport[$j][$k][$i];
        }
      }
    }
    if ($verbose == 1)
    {
      print STDERR "Iteration: $itercount\r";
    }
  }
  $tag = "";
  $content = "";
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;
  $content .= $data;
}

sub default {
}

sub get_genome_file ($$)
{
  my ($speciesfile, $refGenome) = @_;
  my $r;
  my $l;
  my $c = 0;
  open SPECIES, "$speciesfile" or die "$speciesfile could not be opened";
  while ($l = <SPECIES>)
  {
    chomp $l;
    unless ($l =~ /^#/)
    {
      $c++;
      if ($c == $refGenome)
      {
        $r = $l;
        last;
      }
    }
  }
  close SPECIES;
  return $r;
}
##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'analyze-run-clonalorigin2-simulation2-prepare.pl -h\' for more information.\nExit program.\n";
    exit(0);
}

sub locate_block_in_genome ($$)
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
  close XMFA;
  return ($startGenome, $endGenome, $strand);
}

sub locate_nucleotide_in_block ($$)
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

#print STDERR "\n$s-$e-$startGenome-$endGenome-$f\n";
  #my $j = 0;
  my @nucleotides = split //, $sequence;
  return @nucleotides;

  #for (my $i = 0; $i <= $#nucleotides; $i++)
  #{
    #if ($nucleotides[$i] eq 'a' 
        #or $nucleotides[$i] eq 'c' 
        #or $nucleotides[$i] eq 'g' 
        #or $nucleotides[$i] eq 't') 
    #{
      #my $pos = $startGenome + $j;   
      #if ($s <= $pos and $pos <= $e)
      #{
        #push @v, $i;
        #$geneSequence .= $nucleotides[$i];
      #}
      #$j++;
    #}
  #}
  #print "\n$geneSequence\n";

  #return @v;
}

sub find_genes_within_block ($$$)
{
  my ($f, $s, $e) = @_; #($ingene, $href->{start}, $href->{end});
  my @genes;
  open INGENE, $f or die "Could not open $f";
  while (<INGENE>)
  {
    chomp;
    my @elements = split /\t/;
    my $geneName = $elements[0];
    my $geneStart = $elements[1];
    my $geneEnd = $elements[2];
    my $geneStrand = $elements[3];
    if ($s <= $geneStart && $geneEnd <= $e)
    {
      my $rec = {};
      $rec->{name} = $geneName;
      $rec->{start} = $geneStart;
      $rec->{end} = $geneEnd;
      push @genes, $rec;
    }
  }
  close INGENE; 
  return @genes;
}
