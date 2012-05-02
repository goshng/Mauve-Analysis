#!/opt/local/bin/perl -w
###############################################################################
# Copyright (C) 2012 Sang Chul Choi
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
use strict;
use warnings;
use Scalar::Util qw(looks_like_number);
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
require "pl/sub-error.pl";
require "pl/sub-simple-parser.pl";
require "pl/sub-array.pl";
require "pl/sub-heatmap.pl";
require "pl/sub-newick-parser.pl";
sub CF_get_number_sites ($);
sub CF_get_recombination_probability ($$$);

my $cmd = ""; 
sub process {
  my ($a) = @_; 
  $cmd = $a; 
}
$| = 1; # Do not buffer output
my $VERSION = 'summarize-clonalframe-event.pl 1.0';
my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'in=s',
            'node=i',
            'out=s',
            '<>' => \&process
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $infile;
my $outfile;

unless (exists $params{in}) {
  &printError("you did not specify option -in");
} 
unless (exists $params{node}) {
  &printError("you did not specify option -node");
} 

if (exists $params{out})
{
  open ($outfile, ">", $params{out}) or die "cannot open > $params{out}: $!";
}
else
{
  $outfile = *STDOUT;   
}
################################################################################
## DATA PROCESSING
################################################################################

##############################################################
# Global variables
##############################################################
my $n = CF_get_number_sites ($params{in});
my $cf_number_import = CF_get_recombination_probability ($params{in}, $n, $params{node});
# print $cf_number_import, "\n";

if (exists $params{out})
{
  close $outfile;
}

exit;
##############################################################
# END OF RUN OF THIS PERL SCRIPT
##############################################################

sub CF_get_number_sites ($) {
  my ($in) = @_;
  open (IN, "<", $in) or die "cannot open < $in: $!";
  while (<IN>) {
    last if /^#poly/;
  }
  my $maximum = 0;
  while (<IN>) {
    last if /^#/;
    if ($maximum < $_)
    {
      $maximum = $_;
    }
  }
  close IN;
  return $maximum;
}

sub CF_get_recombination_probability ($$$) {
  my ($in,$n,$node) = @_;
  my @a = (-1) x ($n + 1);

  # Find reference sites
  open (IN, "<", $in) or die "cannot open < $in: $!";
  while (<IN>) {
    last if /^#poly/;
  }
  my @refSites;
  while (<IN>) {
    last if /^#/;
    push @refSites, $_;
  }
  close IN;

  # Set recombination probabilities
  my $l;
  open (IN, "<", $in) or die "cannot open < $in: $!";
  while (<IN>) {
    last if /^#consevents/;
  }
  for (my $i = 1; $i < $node; $i++) {
    $l = <IN>;
  }
  $l = <IN>;
  my @b = split /\s+/, $l;
  close IN;

  for (my $i = 0; $i < scalar(@refSites); $i++) {
    my $pos = $refSites[$i];
    if ($pos > 0) {
      $a[$pos] = $b[2*$i];
      die "Error: $b[2*$i] is not a number." unless looks_like_number($b[2*$i]);
    }
  }

  # Remove elements less than 0.
  my @pos_indices = grep { $a[$_] > -0.1 } 0..$#a;
  @a = grep { $_ > -0.1 } @a;
  my @indices = grep { $a[$_] > 0.95 } 0..$#a;
  my @c = (0) x scalar(@a);
  for my $i (@indices) {
    $c[$i] = 1;
  }
  my $bits = join ("", @c);
  my @counts;
  while ($bits =~ /(0+|1+)/g) {
    push @counts, length($1) * (substr($1, 0, 1) == 1 ? 1 : -1);
  }
  my @cf_imports = grep { $_ > 0 } @counts;

  # Compute the average length of imports.
  my $pos = 0;
  for my $i (@counts) {
    if ($i > 0) {
      my $length_import = $pos_indices[$pos + abs($i) - 1] - $pos_indices[$pos] + 1;
      # print $pos_indices[$pos + abs($i) - 1], " - ", $pos_indices[$pos], "\t";
      print $length_import, "\n";
    }
    $pos += abs($i);
  }


#  print scalar (@b), "\n";
#  print scalar (@refSites), "\n";
#  print $n, "\n";
  return scalar (@cf_imports);
}
__END__
=head1 NAME

summarize-clonalframe-event.pl - Count recombinant edges

=head1 VERSION

summarize-clonalframe-event.pl 1.0

=head1 SYNOPSIS

perl summarize-clonalframe-event.pl [-h] [-help] [-version] 
  [-d xml data directory] 
  [-e per-block heat map directory] 
  [-n number of blocks] 
  [-s number of species] 
  [-xmlbasename filename]
  [-endblockid]
  [-obsonly]

perl pl/summarize-clonalframe-event.pl obsonly -d output2/1 -endblockid -obsonly -n 274

perl pl/summarize-clonalframe-event.pl obsonly -d output2/1 -n 274 -endblockid -lowertime 0.045557

perl pl/summarize-clonalframe-event.pl obsiter -d output2/1 -n 274

=head1 DESCRIPTION

obsiter - first we create a matrix of size n-by-m; n is equal to the number of
iterations, and m is equal to square of the number of species tree branches.  We
count recombinant edges of i-th recombinant tree for the first block. Repeat the
count for all of the n recombinant trees. We call this matrix A.  We then repeat
this procedure for the next block to obtain a matrix B. We sum the two matrices
element-by-element to replace A. Now, we move to the next block to repeat the
summation of two matrices until we exhaust all of the blocks. 

obsonly - This does not require option -e. I sum the number of recombinant edges
over all of the blocks, and divide it by the sample size.

heatmap - This is almost the same as obsonly except for accounting the prior
expected numbers of recombinant edges.

exponly - I just sum the prior expected numbers over all of the blocks.


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

-obsonly

Situation 4: I wish to compute the average number of recombination and its
standard deviation across MCMC sample by considering prior expected number of
recombinant edges.

Default options (or neither meanonly nor obsonly).

Command obsonly: 

  The directory of clonalorigin's 2nd MCMC results must be specified by option
  -d. The number of block must be set using option -n.

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

=item B<-obsonly>

Prior expected numbers of recombinant edges are ignored.

=item B<-endblockid>

Note: we always put block IDs at the end of a file name. This option does not do
anything except for voiding any option error.

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
com repository so that I can make summarize-clonalframe-event.pl better.

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

