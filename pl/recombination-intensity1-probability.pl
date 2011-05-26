#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombination-intensity1-probability.pl
#   Date: Tue May 17 14:34:30 EDT 2011
#   Version: 1.0
#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'recombination-intensity1-probability.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'ri1map=s',
            'ingene=s',
            'clonaloriginsamplesize=i',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombination-intensity1-probability.pl - Compute recombination intensity1 along a genome

=head1 VERSION

v1.0, Sun May 15 16:25:25 EDT 2011

=head1 SYNOPSIS

perl recombination-intensity1-probability.pl [-h] [-help] [-version] [-verbose]
  [-ri1map file] 
  [-ingene file] 
  [-out file] 

=head1 DESCRIPTION

The number of recombination edge types at a nucleotide site along all of the
alignment blocks is computed for genes from an ingene file. 
Menu recombination-intensity1-map must be called first.

What we need includes:
1. recombination-intensity1-map file (-ri1map)
2. ingene file (-ingene)
3. out file (-out)

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

=item B<-ri1map> <file>

A recombination intensity 1 map file.

=item B<-ingene> <file>

An ingene file.

=item B<-out> <file>

An output file.

=item B<-pairs> <string>

  -pairs 0,3:0,4:1,3:1,4:3,0:3,1:4,0:4,1

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make recombination-intensity1-probability.pl better.

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

require "pl/sub-ingene.pl";
require "pl/sub-error.pl";
require "pl/sub-array.pl";

# Delete these if not needed.
require "pl/sub-simple-parser.pl";
require "pl/sub-newick-parser.pl";
require "pl/sub-xmfa.pl";

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $ri1map;
my $ingene;
my $out; 
my $clonaloriginsamplesize;
my $pairs;
my $verbose = 0;

if (exists $params{ri1map})
{
  $ri1map = $params{ri1map};
}
else
{
  &printError("you did not specify an ri1map file that contains recombination intensity 1 measure");
}

if (exists $params{out})
{
  $out = $params{out};
}
else
{
  &printError("you did not specify an output file");
}

if (exists $params{pairs})
{
  $pairs = $params{pairs};
}
else
{
  &printError("you did not specify an pairs file");
}

if (exists $params{ingene})
{
  $ingene = $params{ingene};
}
else
{
  &printError("you did not specify an ingene file");
}

if (exists $params{clonaloriginsamplesize})
{
  $clonaloriginsamplesize = $params{clonaloriginsamplesize};
}
else
{
  &printError("you did not specify an clonaloriginsamplesize");
}

if (exists $params{verbose})
{
  $verbose = 1;
}

################################################################################
## DATA PROCESSING
################################################################################
my $itercount = 0;
my $blockLength;
my $blockidForProgress;
# my $speciesTree = get_species_tree ("$xml.1");
my $numberTaxa = 5;
my $numberLineage = 2 * $numberTaxa - 1;

################################################################################
# Find coordinates of the reference genome.
################################################################################

my @genes = parse_in_gene ($ingene); 

sub test ($$$);
sub drawRI1BlockGenes ($$);
sub getRI1Gene ($$$$$);
sub getPairs ($);

# my @pairSourceDestination = getPairs ($pairs);
#for my $i ( 0 .. $#pairSourceDestination) {
  #print "\t [ @{$pairSourceDestination[$i]} ],\n";
#}

#test (\@genes, $ri1map, \@pairSourceDestination);
drawRI1BlockGenes (\@genes, $ri1map);

exit;
################################################################################
## END OF DATA PROCESSING
################################################################################

################################################################################
## FUNCTION DEFINITION
################################################################################

sub test ($$$)
{
  my ($genes, $ri1map, $pairSourceDestination) = @_;
  for my $i ( 0 .. $#pairSourceDestination) {
    my $sourceI = $pairSourceDestination->[$i][0];
    my $destinationJ = $pairSourceDestination->[$i][1];
    print "$sourceI -> $destinationJ\n";
  }
}

sub getPairs ($)
{
  my ($s) = @_;
  my @v;

  my @e = split /:/, $s;
  for my $element (@e)
  {
    push @v, [ split /,/, $element ]; 
  }
  return @v;
}

sub drawRI1BlockGenes ($$)
{
  my ($genes, $ri1map) = @_;

  my @map;
  my $line;
  my $status = "nomap";
  open MAP, $ri1map or die "could not open $ri1map";
  while ($line = <MAP>)
  {
    chomp $line;
    my @e = split /\t/, $line;
    if ($status eq "nomap")
    {
      if ($e[1] < 0)
      {
        next;
      }
      else
      {
        @map = ();
        $status = "map";
      }
    }
    else
    {
      if ($e[1] < 0)
      {
        $status = "nomap";
        # Generate the figure for the map.
        drawRI1Block (\@map, $ingene, $out);
        last;
        next;
      }
      else
      {
        push @map, [ @e ];
      }
    }
  }
  close MAP;
}

sub drawRI1Block ($$$)
{
  my ($map, $ingene, $out) = @_;

  my $startPos = $map->[0][0];
  my $last = $#map;
  my $endPos = $map->[$last][0];
  my $width = 500;
  my $binSize = int(($last + 1) / $width + 1);

  my $outfile = sprintf("$out-%09d.ps", $startPos)
  open OUT, ">$outfile" or die "could not open $outfile $!";

  for (my $destinationJ = 0; $destinationJ < $numberLineage; $destinationJ++)
  {
    my @prob = (0) x $numberLineage;  
    my $binIndex = 0;
    for (my $p = 0; $p <= $last; $p++)
    {
      unless ($binIndex < $binSize)
      {
        # Print values.
        for (my $sourceI = 0; $sourceI < $numberLineage; $sourceI++)
        {
          print OUT "$p: $destinationJ: $prob[$sourceI]\n";
        }
        @prob = (0) x $numberLineage;  
        $binIndex = 0;
      }

      for (my $sourceI = 0; $sourceI < $numberLineage; $sourceI++)
      {
        my $v = $map->[$p][1 + $sourceI * $numberLineage + $destinationJ];
        die "Negative means no alignemnt in $position" if $v < 0;
        $prob[$sourceI] += ($v / ($clonaloriginsamplesize * $binSize));
      }
      $binIndex++;
    }
  }
  close OUT;
}
