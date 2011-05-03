#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombination-intensity4.pl
#   Date: 21.03-17
#   Version: 1.0
#
#   Usage:
#      perl recombination-intensity4.pl [options]
#
#      Try 'perl recombination-intensity4.pl -h' for more information.
#
#   Purpose: recombination-intensity4.pl help you compute recombinant edge counts
#            along a genome. I order all the alignment blocks with respect to
#            one of genomes. I would use the first genome in the alignment. I
#            need to use the species tree that is in the clonal origin output
#            files. Note that the numbering of internal nodes in the input
#            species tree and that of the clonal output files were different. I
#            have to use the species tree in the clonal origin to locate
#            internal nodes. Using the species tree I should be able to find the
#            species and their ancestors. Find which ordered pairs are possible
#            and which others are not. I need to parse the species tree in a
#            clonal origin outputfile. 
#            Consider a species tree with recombinant edges: e.g., Didelot's
#            2010 ClonalOrigin paper. For each site of an alignment block I can
#            have a matrix where element is a binary character. A site is
#            affected by multiple recombinant edges. It is possible that
#            recombinant edges with the same arrival and departure affect a
#            single site. This should not be possible under ClonalOrigin's
#            model. It happened in the ClonalOrigin output file. If you simply
#            count recombinant edges, you could count some recombinant edge type
#            two or more times. To avoid the multiple count we use a matrix with
#            binary values. Then, we sum the binary matrices across all the
#            iteratons.
#            Note that the source and destination edges could be reversed. Be
#            careful not to reverse it. I used to use to -> from not from -> to.
#            Now, I use from -> to for each position.
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

my $VERSION = 'recombination-intensity4.pl 1.0';

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
            'xmlbasename=s',
            'speciesfile=s',
            'genomedir=s',
            'numberblock=i',
            'r=i',
            'check'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombination-intensity4.pl - Compute recombination intensity along the genome.

=head1 VERSION

recombination-intensity4.pl 1.0

=head1 SYNOPSIS

perl recombination-intensity4.pl [-h] [-help] [-version] 
  [-d xml data directory] 
  [-xmfa genome alignment] 
  [-r reference genome ID] 
  [-xmlbasename xml file base name] 
  [-speciesfile file] 
  [-genomedir file] 
  [-endblockid]

=head1 DESCRIPTION

The number of recombination edge types at a nucleotide site along all of the
alignment blocks is computed.

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

=item B<-r> <number>

A reference genome ID.

=item B<-speciesfile> <speices file>

=item B<-genomedir> <dir>

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
com repository so that I can make recombination-intensity4.pl better.

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
sub get_genome_file ($$);
sub locate_block_in_genome ($$);
sub locate_nucleotide_in_block ($$);


#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $xmlDir;
my $xmfaBasename;
my $check = 0;
my $xmlBasename = "core_co.phase3";
my $endblockid = 0;
my $genomedir;
my $speciesfile;
my $refGenome;
my $numberBlock; 

if (exists $params{d})
{
  $xmlDir = $params{d};
}
else
{
  &printError("you did not specify a directory that contains Clonal Origin 2nd run results");
}

if (exists $params{numberblock})
{
  $numberBlock = $params{numberblock};
}
else
{
  &printError("you did not specify the number of blocks");
}

if (exists $params{r})
{
  $refGenome = $params{r};
}
else
{
  &printError("you did not specify a reference genome");
}

if (exists $params{xmfa})
{
  $xmfaBasename = $params{xmfa};
}
else
{
  &printError("you did not specify a directory that contains genome alignments");
}

if (exists $params{speciesfile})
{
  $speciesfile = $params{speciesfile};
}
else
{
  &printError("you did not specify a directory that contains genomes");
}

if (exists $params{genomedir})
{
  $genomedir = $params{genomedir};
}
else
{
  &printError("you did not specify a directory that contains genomes");
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
my $speciesTree = get_species_tree ("$xmlDir/$xmlBasename.xml.1");
my $numberTaxa = get_number_leave ($speciesTree);
my $numberLineage = 2 * $numberTaxa - 1;
my $genomefile = get_genome_file ($speciesfile, $refGenome);
my $genomeLength = get_genome_length ("$genomedir/$genomefile");

if ($check == 1)
{
  print "Genome: $genomedir/$genomefile\n";
  print "  Length - $genomeLength\n";
}

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

# mapImport index is 1-based, and blockImmport index is 0-based.
# map starts at 1.
# block starts at 0.
# mapImport is created.
my @blockImport;
my @mapBlockImport;
if ($check == 1)
{
  print STDERR "A new mapImport is being created...";
}
my @mapImport = create3DMatrix ($numberLineage, 
                                $numberLineage, 
                                $genomeLength + 1);
if ($check == 1)
{
  print STDERR " done.\n";
}

# mapImport is filled in.
my $offsetPosition = 0;
my $prevBlockLength = 1;
for (my $blockID = 1; $blockID <= $numberBlock; $blockID++)
{
  my $af = "$xmfaBasename.$blockID";
  my $f = "$xmlDir/$xmlBasename.xml.$blockID";
  $blockLength = get_block_length ($f);
  $offsetPosition += $prevBlockLength;
  $prevBlockLength = $blockLength;

  @mapBlockImport = create3DMatrix ($numberLineage, 
                                    $numberLineage, 
                                    $blockLength);
  if ($check == 1)
  {
    print STDERR "A new mapBlockImport for $blockID is created.\n";
  }
  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  $itercount = 0;
  my $doc;
  eval{ $doc = $parser->parsefile($f)};
  print "Unable to parse XML of $f, error $@\n" if $@;
  next if $@;

  my @sites = locate_nucleotide_in_block ($af, $refGenome);
  my ($b, $e, $strand) = locate_block_in_genome ($af, $refGenome);
  my $c = 0; 
  for my $i ( 0 .. $#sites ) {
    if ($sites[$i] eq '-')
    {
      # No code.
    }
    else
    {
      my $pos;
      if ($strand eq '+') 
      {
        $pos = $b + $c;
      }
      else
      {
        $pos = $e - $c;
      }
      for (my $j = 0; $j < $numberLineage; $j++)
      {
        for (my $k = 0; $k < $numberLineage; $k++)
        {
          $mapImport[$j][$k][$pos] = $mapBlockImport[$j][$k][$i];
        }
      }
      $c++;
    }
  }
  $c--;
  die "$e and $b + $c do not match" unless $e == $b + $c;
  if ($check == 1)
  {
    print "Block: $blockID\r";
  }
}

# mapImport is printed out.
for (my $i = 1; $i <= $genomeLength; $i++)
{
  my $pos = $i;
  print "$pos";
  for (my $j = 0; $j < $numberLineage; $j++)
  {
    for (my $k = 0; $k < $numberLineage; $k++)
    {
      print "\t", $mapImport[$j][$k][$pos];
    }
  }
  print "\n";
}

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
    if ($check == 1)
    {
      print STDERR "$itercount\r";
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
    print STDERR "ERROR: ".$msg.".\n\nTry \'recombination-intensity4.pl -h\' for more information.\nExit program.\n";
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

