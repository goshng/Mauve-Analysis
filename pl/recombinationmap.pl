#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: recombinationmap.pl
#   Date: 2011-02-10
#   Version: 0.1.0
#
#   Usage:
#      perl recombinationmap.pl [options]
#
#      Try 'perl recombinationmap.pl -h' for more information.
#
#   Purpose: recombinationmap.pl help you to generate graph for recombination
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
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'recombinationmap.pl 0.1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'map=s',
            'importpair=s',
            'out_format=i',
            'genome_length=i',
            'chromosomename=s',
            'samplesize=i',
            'graph=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

recombinationmap.pl - Conversion of map to graph

=head1 VERSION

recombinationmap.pl 0.1.0

=head1 SYNOPSIS

perl recombinationmap.pl.pl [-h] [-help] [-version] [-man] [-verbose] [-map input_map_file] 

=head1 DESCRIPTION

recombinationmap.pl will help you to convert segemehl program's output mapping files to a
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
com repository so that I can make recombinationmap.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

my $genome_length = 3000000;
my $chromosomeName = "NC_000915.1";
my $samplesize = 101;

if (exists $params{chromosomename})
{
  $chromosomeName = $params{chromosomename};
}

if (exists $params{samplesize})
{
  $samplesize = $params{samplesize};
}

my (@files1);

if (exists $params{genome_length}) {
    $genome_length = $params{genome_length};
}

#Check if input file exists and check if file format is correct
if (exists $params{map}) {
    @files1 = split /,/, $params{map};
    foreach my $f (@files1)
    {
        if (-e $f) {
            #check for file format
            my $format = &checkFileFormat($f);
            unless($format eq 'map') {
                &printError('input file for -map is in '.uc($format).' format not in segemehl format');
            }
        } else {
            &printError("could not find input file \"".$f."\"");
        }
    }

} else {
    &printError("you did not specify an input map file containing the mapping of reads");
}

my @edges;
my @eto;
my @efrom;
if (exists $params{importpair}) {
  @edges = split /,/, $params{importpair};
  my $alternate = 0;
  foreach (@edges)
  {
    if ($alternate == 0)
    {
      push @eto, $_;
      $alternate = 1;
    }
    else
    {
      push @efrom, $_;
      $alternate = 0;
    }
  }
}
else
{
    &printError("you did not specify import pairs of edges");
}
############################################
#print "eto: ";
#foreach (@eto)
#{
#  print "[$_] ";
#}
#print "\n";
#print "efrom: ";
#foreach (@efrom)
#{
#  print "[$_] ";
#}
#print "\n";
#exit;
############################################

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

my $filename = $files1[0];
while($filename =~ /[\w\d]+\.[\w\d]+/) {
    $filename =~ s/\.[\w\d]+$//;
}

#create filehandles for the output data
my ($fhgraph,$fhigv);
my ($filenamegraph);

$filenamegraph = $filename.'.graph';
open($fhgraph,">".$filenamegraph) or &printError('cannot open output file');

#progress bar
my $numlines = 0;
my ($progress,$counter,$part);
$progress = $counter = $part = 1;
if(exists $params{verbose}) {
    print STDERR "Estimate size of input data for status report (this might take a while for large files)\n";
    $numlines = 0;
    foreach my $f (@files1)
    {
        $numlines += &getLineNumber($f);
    }
    print STDERR "\tdone\n";

    #for progress bar
    $progress = 0;
    $counter = 1;
    $part = int($numlines/100);
}


#parse input data
print STDERR "Parse and process input data\n" if(exists $params{verbose});
my $numseqs = 0;
my $count = 0;
my (%hits);
my (@elements);
#################################################################################
# Code of mine.
#################################################################################

# Count multiple hits of a short read.
my $files1_separated_by_a_space = $files1[0];
open(FILE,"$files1_separated_by_a_space") or die "ERROR: Could not open one of files $files1_separated_by_a_space: $! \n";

my ($fhigb);
my $filenameigb;
if ($#eto == 0)
{
  $filenameigb = $files1_separated_by_a_space.'-'.$eto[0].'-'.$efrom[0].'.sgr';
}
else
{
  $filenameigb = $files1_separated_by_a_space.'.sgr';
}
open($fhigb,">".$filenameigb) or &printError('cannot open output file');

my $line = <FILE>;
while (<FILE>) {
   chomp();
   my @elements = split /\s+/;
   my $pos = $elements[0];
   # eto 0, efrom 3 index is 9 * eto + efrom + 1

   my $v = 0;
   my $to;
   my $from;
   my $j;
   for (my $i = 0; $i <= $#eto; $i++)
   {
     $to = $eto[$i];
     $from = $efrom[$i];
     $j = 9 * $to + $from + 1;
     if ($elements[$j] / $samplesize > 0.9) # Sample size is 101.
     {
       $v = 1;
     }
     else
     {
       $v = 0;
     }
   }
   if ($#eto == 0)
   {
     $v = $elements[$j] / $samplesize;
   }
   print $fhigb "$chromosomeName\t$pos\t$v\n";
}
close(FILE);
close($fhigb);

##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'recombinationmap.pl -h\' for more information.\nExit program.\n";
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

