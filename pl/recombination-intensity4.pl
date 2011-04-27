#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombination-intensity4.pl
#   Date: 2011-03-17
#   Version: 0.1.0
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

my $VERSION = 'recombination-intensity4.pl 0.1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'd=s',
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombination-intensity4.pl - Compute recombination intensity along the genome.

=head1 VERSION

recombination-intensity4.pl 0.1.0

=head1 SYNOPSIS

perl recombination-intensity4.pl [-h] [-help] [-version] 
  [-d xml data directory] 

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

=item B<-d> <directory with prefix>

A directory that contains the 2nd phase run result from Clonal Origin.
Each output file of the ClonalOrigin 2nd stage is prefixed: e.g.,
path-to-clonalorigin2nd/core_co.phase3
where a 1st block result should be accessed by a file name
path-to-clonalorigin2nd/core_co.phase3.1.xml
The number of files can be used to find the total number of alignment blocks.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make recombination-intensity4.pl better.

=head1 COPYRIGHT

Copyright (C) 2011 Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

sub find_number_files ($);
sub get_species_tree ($$);
sub get_length_block ($$);
sub get_length_all_blocks ($);
sub get_number_leave ($);

#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $xmlDir;
if (exists $params{d})
{
  $xmlDir = $params{d};
}
else
{
  &printError("you did not specify a directory that contains Clonal Origin 2nd run results");
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

my $tag;
my $content;
my %recedge;
my $itercount=0;
my $numberBlock = find_number_files ($xmlDir);
my $speciesTree = get_species_tree ($xmlDir, 1); # Just to get the tree.
my $blockLength = get_length_block ($xmlDir, 1); # Just for test.
my $genomeLength = get_length_all_blocks ($xmlDir);
my $numberTaxa = get_number_leave ($speciesTree);
my $numberLineage = 2 * $numberTaxa - 1;

# mapImport index is 1-based, and blockImmport index is 0-based.
# map starts at 1.
# block starts at 0.
# mapImport is created.
my @blockImport;
my @mapImport;
for (my $i = 0; $i < $numberLineage; $i++)
{
  my @mapPerLineage;
  for (my $j = 0; $j < $numberLineage; $j++)
  {
    my @asinglemap = (0) x ($genomeLength + 1);
    push @mapPerLineage, [ @asinglemap ];
  }
  push @mapImport, [ @mapPerLineage ];
}

# mapImport is filled in.
my $offsetPosition = 0;
my $prevBlockLength = 1;
for (my $blockID = 1; $blockID <= $numberBlock; $blockID++)
{
  my $f = "$xmlDir.$blockID.xml";
  my $blockLength = get_length_block ($xmlDir, $blockID);
  $offsetPosition += $prevBlockLength;
  $prevBlockLength = $blockLength;

	my $parser = new XML::Parser();
	$parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

	$itercount=0;
	my $doc;
	eval{ $doc = $parser->parsefile($f)};
	print "Unable to parse XML of $f, error $@\n" if $@;
	next if $@;
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

# Find the number of ClonalOrigin's output files.
# I just check if files exist.
sub find_number_files ($)
{
  my ($prefix) = @_;
  my $blockID = 1;
  my $f = "$prefix.$blockID.xml";
  while (-e $f)
  {
    $blockID++;
    $f = "$prefix.$blockID.xml";
  }
  $blockID--;
  return $blockID; 
}

# Get the species tree of a block.
sub get_species_tree ($$)
{
  my ($prefix, $blockID) = @_;
  my $r;
  my $f = "$prefix.$blockID.xml";
  open XML, $f or die "$f $!";
  while (<XML>)
  {
    if (/^<Tree>/)
    {
      $r = <XML>;
      chomp ($r);
      last;
    }
  } 
  close (XML); 
  die "The $f does not contain a species tree" unless defined $r;
  return $r;
}

# Get the length of a block
sub get_length_block ($$)
{
  my ($prefix, $blockID) = @_;
  my $line;
  my $r;
  my $f = "$prefix.$blockID.xml";
  open XML, $f or die "$f $!";
  while (<XML>)
  {
    if (/^<Blocks>/)
    {
      $line = <XML>;
      chomp ($line);
      $line =~ /^(\d+),(\d+)$/;
      $r = $2;
      last;
    }
  } 
  close (XML); 
  die "The $f does not contain a species tree" unless defined $r;
  return $r;
}

# Get length of all of the blocks.
sub get_length_all_blocks ($)
{
  my ($prefix) = @_;
  my $r = 0;
  my $blockID = 1;
  my $f = "$prefix.$blockID.xml";
  while (-e $f)
  {
    $r += get_length_block ($prefix, $blockID);
    $blockID++;
    $f = "$prefix.$blockID.xml";
  }
  $blockID--;
  return $r; 
}

# Find the number of leaves of a rooted tree.
# (((0:4.359500e-02,1:4.359500e-02)5:1.951410e-01,2:2.387360e-01)7:8.480900e-02,(3:7.356900e-02,4:7.356900e-02)6:2.499760e-01)8:0.000000e+00; 
sub get_number_leave ($)
{
  my ($newickTree) = @_;
  my $r = 0;
  my $s = $newickTree;
  print $s, "\n";
  my @elements = split (/[\(\),]/, $s);
  for (my $i = 0; $i <= $#elements; $i++)
  {
    if (length $elements[$i] > 0)
    {
      $r++;
    }
  }
  $r = ($r + 1) / 2;

  return $r;
}

sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
  SWITCH: {
    if ($element eq "Iteration") 
    {
      $itercount++;
      @blockImport = ();
      for (my $i = 0; $i < $numberLineage; $i++)
      {
        my @mapPerLineage;
        for (my $j = 0; $j < $numberLineage; $j++)
        {
          my @asinglemap = (0) x $blockLength;
          push @mapPerLineage, [ @asinglemap ];
        }
        push @blockImport, [ @mapPerLineage ];
      }
      last SWITCH;
    }
    if ($element eq "recedge") {
      last SWITCH;
    }
  }
}

sub endElement {
  my ($p, $elt) = @_;
	$tag = "";
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
      my $pos = $offsetPosition + $i;
      for (my $j = 0; $j < $numberLineage; $j++)
      {
        for (my $k = 0; $k < $numberLineage; $k++)
        {
          $mapImport[$j][$k][$pos] += $blockImport[$j][$k][$i];
        }
      }
    }
  }

  if ($elt eq "outputFile")
  {
    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $offsetPosition + $i;
      for (my $j = 0; $j < $numberLineage; $j++)
      {
        for (my $k = 0; $k < $numberLineage; $k++)
        {
          # $mapImport[$j][$k][$pos] /= $itercount;
        }
      }
    }
  }
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;
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
    print STDERR "ERROR: ".$msg.".\n\nTry \'recombination-intensity4.pl -h\' for more information.\nExit program.\n";
    exit(0);
}

