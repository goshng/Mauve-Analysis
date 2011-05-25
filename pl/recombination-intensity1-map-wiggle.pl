#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombination-intensity1-map-wiggle.pl
#   Date: Tue May  3 09:22:29 EDT 2011
#   Version: 1.0
#
#   Usage:
#      perl recombination-intensity1-map-wiggle.pl [options]
#
#      Try 'perl recombination-intensity1-map-wiggle.pl -h' for more information.
#
#   Purpose: recombination-intensity1-map-wiggle.pl help you compute
#            recombination intensity from the map file. The values will be
#            scaled.
#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'recombination-intensity1-map-wiggle.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'map=s',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombination-intensity1-map-wiggle.pl - Convert map to wiggle

=head1 VERSION

v1.0, Sun May 15 16:25:25 EDT 2011

=head1 SYNOPSIS

perl recombination-intensity1-map-wiggle.pl [-h] [-help] [-version] [-verbose]
  [-map file] 
  [-out file] 

=head1 DESCRIPTION

A map file contains numbers for each line. Each line starts with a number that
is equal to the map position or the line number. The subsequent numbers are
tab-delimited. The number of numbers must be a square of an integer.

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

=item B<-xml> <file base name>

A base name for ClonalOrigin XML files
that contains the 2nd phase run result from Clonal Origin. A number of XML files
for blocks are produced by appending dot and a block ID.

  -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml

The XML file for block ID of 1 is

  -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml.1

=item B<-xmfa> <file base name>

A base name for xmfa formatted alignment blocks. Each block alignment is
produced by appending a dot and block ID.

  -xmfa $DATADIR/core_alignment.xmfa

A XMFA block alignment for block ID of 1 is

  -xmfa $DATADIR/core_alignment.xmfa.1

=item B<-refgenome> <number>

A reference genome ID.

=item B<-refgenomelength> <number>

The length of the reference genome.

=item B<-numberblock> <number>

The number of blocks.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make recombination-intensity1-map-wiggle.pl better.

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
require "pl/sub-error.pl";
require "pl/sub-array.pl";
require "pl/sub-xmfa.pl";

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $map;
my $out;
my $verbose = 0;

if (exists $params{map})
{
  $map = $params{map};
}
else
{
  &printError("you did not specify a map file");
}

if (exists $params{out})
{
  $out = $params{out};
}
else
{
  &printError("you did not specify an output file");
}

if (exists $params{verbose})
{
  $verbose = 1;
}

################################################################################
## DATA PROCESSING
################################################################################
# Find the maximum.
my $max = 0;
my @values;
open MAP, $map or die "Could not open $map $!";
while (<MAP>)
{
  chomp;
  my @e = split /\t/;
  my $v = 0;
  if ($e[1] < 0)
  {
    # No code.
  }
  else
  {
    for (my $i = 1; $i <= $#e; $i++)
    {
      $v += $e[$i];
    }
  }
  $max = $v if $max < $v;
  push @values, $v; 
}
close MAP;

# Print the wiggle file.
open OUT, ">$out" or die "Could not open $out $!";
print OUT "track type=wiggle_0\n";
print OUT "fixedStep chrom=chr1 start=1 step=1 span=1\n";
foreach my $v (@values)
{
  $v /= $max;
  $v *= 1000; 
  print OUT "$v\n";
}
close OUT;
