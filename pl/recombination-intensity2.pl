#!/usr/bin/perl
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombination-intensity2.pl
#   Date: 2011-02-10
#   Version: 0.1.0
#
#   Usage:
#      perl recombination-intensity2.pl [options]
#
#      Try 'perl recombination-intensity2.pl -h' for more information.
#
#   Purpose: recombination-intensity2.pl help you to generate graph for recombination
#            map. I read in a recombination import file to generate a graph to
#            display it using IGB. I wanted to generate some graphs that Didelot
#            et al. (2010) generated. I could not do that because I do not know
#            what I should do. IGB may be useful to achieve some of the goals.
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

$| = 1; # Do not buffer output

my $VERSION = 'recombination-intensity2.pl 0.1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'd=s',
            'map=s',
            'out_format=i'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombination-intensity2.pl - Conversion of map to graph

=head1 VERSION

recombination-intensity2.pl 0.1.0

=head1 SYNOPSIS

perl recombination-intensity2.pl.pl [-h] [-help] [-version] [-man] [-verbose] [-map input_map_file] 

=head1 DESCRIPTION

recombination-intensity2.pl will help you to convert segemehl program's output mapping files to a
graph file that can be viewed using a genome viewer such as IGV, IGB, etc.

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

=item B<-map> <file>,<file>,...

Input files in segemehl output file format that contains short read sequences
with their maps on a reference genome. The first file's name is used for the
output graph file.

=item B<-d> <directory with prefix>

A directory that contains the 2nd phase run result from Clonal Origin.
Each output file of the ClonalOrigin 2nd stage is prefixed: e.g.,
path-to-clonalorigin2nd/core_co.phase3
where a 1st block result should be accessed by a file name
path-to-clonalorigin2nd/core_co.phase3.1.xml
The number of files can be used to find the total number of alignment blocks.

=item B<-fasta> <file>

Input file in FASTA format that contains the sequence data.

=item B<-genome_length> <integer>

Length of the reference genome

=item B<***** OUTPUT OPTIONS *****>

=item B<-out_format> <integer>

To change the output format, use one of the following options. If not defined,
the output format will be of IGB graph format.

1 (IGB), 2 (IGV) or 3 (UCSC Genome Browser)

=item B<***** FILTER OPTIONS *****>

=item B<-genome-len> <integer>

Length of a reference genome. This is optional.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make recombination-intensity2.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

require 'pl/common-parser-clonal-origin-xml-output.pl';
#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $chromosomeName = "Streptococcus";
my $xmlDir;
my $mapfile;
if (exists $params{d})
{
  $xmlDir = $params{d};
}
else
{
  &printError("you did not specify a directory that contains Clonal Origin 2nd run results");
}

if (exists $params{map}) {
  $mapfile = $params{map};
} else {
  &printError("you did not specify an input map file containing the mapping of reads");
}

my $numberBlock = find_number_files ($xmlDir);
my $genomeLength = get_length_all_blocks ($xmlDir);
my $samplesize = get_length_iteraion ($xmlDir, 1);
for (my $blockID = 2; $blockID <= $numberBlock; $blockID++)
{
  my $s = get_length_iteraion ($xmlDir, 2);
  die "The 1st block has $samplesize of Iterations, and $blockID has $s" 
    unless $samplesize == $s;
}
my $speciesTree = get_species_tree ($xmlDir, 1); # Just to get the tree.
my $numberTaxa = get_number_leave ($speciesTree);
my $numberLineage = 2 * $numberTaxa - 1;
my $sizeMatrix = $numberLineage * $numberLineage;

#check if output format is possible
my $out_igb = 1;
my $out_igv = 0;
my $out_ucsc = 0;
if (exists $params{out_format}) {
    if ($params{out_format} =~ /\D/) {
        &printError('output format option has to be an integer value');
    } 
    if ($params{out_format} >= 1 and $params{out_format} <= 3) {
        &printError('output format option has to be inclusively between 1 and 3.');
    } 
    if ($params{out_format} == 1)
    {
      $out_igb = 1;
      $out_igv = 0;
      $out_ucsc = 0;
    }
    elsif ($params{out_format} == 2)
    {
      $out_igb = 0;
      $out_igv = 1;
      $out_ucsc = 0;
    }
    elsif ($params{out_format} == 3)
    {
      $out_igb = 0;
      $out_igv = 0;
      $out_ucsc = 1;
    }
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

# Count multiple hits of a short read.
my $fhigb;
my $filenameigb = $mapfile.'.sgr';
open($fhigb,">".$filenameigb) or &printError('cannot open output file');
open FILE, $mapfile or die "$mapfile $!";
while (<FILE>) {
  chomp();
  my @elements = split /\s+/;
  my $pos = $elements[0];

  my $v = 0;
  for (my $i = 1; $i <= $sizeMatrix; $i++)
  {
    $v += $elements[$i];
  }
  $v /= $samplesize;
   
  print $fhigb "$chromosomeName\t$pos\t$v\n";
}
close(FILE);
close($fhigb);

