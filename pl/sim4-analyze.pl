#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: clonalorigin2-simulation3-analyze.pl
#   Date: Tue May 10 13:23:33 EDT 2011
#   Version: 1.0
#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'clonalorigin2-simulation3-analyze.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'true=s',
            'estimate=s',
            'numberreplicate=i',
            'numbersample=i',
            'ingene=s',
            'block=i',
            'blocklength=i',
            'treetopology=i',
            'out=s',
            'append'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

clonalorigin2-simulation3-analyze.pl - Generate a table for menu
clonalorigin2-simulation3-analyze

=head1 VERSION

clonalorigin2-simulation3-analyze.pl 1.0

=head1 SYNOPSIS

perl clonalorigin2-simulation3-analyze.pl 
  [-h] [-help] [-version] 
  [-true file base name] 
  [-estimate file base name] 
  [-numberreplicate number] 
  [-numbersample number] 
  [-ingene file] 
  [-block number] 
  [-blocklength number] 
  [-treetopology number] 
  [-out file] 
  [-append] 

=head1 DESCRIPTION

Menus clonalorigin2-simulation3-prepare,
clonalorigin2-simulation3-receive,
clonalorigin2-simulation3-analyze are used to validate another
surrogate measure of recombination intensity. This is based on map of local gene
tree topologies.
True values of this measure can be found at
output/s14/1/run-analysis/mt-yes-out/core_alignment.2
for REPETITION=1, BLOCK=2. A number of replicates are found at
output/s14/1/run-clonalorigin/output2/mt-3-out/core_co.phase3.xml.2.4.
for REPETITION=1, BLOCK=2, REPLICATE=3, SAMPLE=4. 
Each file is tab-delimited with gene tree topology indices. The number of
indices is equal to the number of sites of a block.
I make a table for each replicate with columns: gene, true,
estimate. This table would be used to plot.

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

=item B<-true> <file>

A file that contains genes and their values.

=item B<-estimate> <file base name>

A base name of files that contains genes and their values.

=item B<-numberreplicate> <number>

Number of replicates.

=item B<-numbersample> <number>

Number of Iterations in ClonalOrigin posterior sample.

=item B<-ingene> <file>

An ingene file that contains genes and their locations.

=item B<-treetopology> <number>

The species tree topology ID.

=item B<-blocklength> <number>

The length of the block.

=item B<-block> <number>

The block ID.

=item B<-out> <file>

An output file.

=item B<-append>

The output file is not created.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make clonalorigin2-simulation3-analyze.pl better.

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

require "pl/sub-error.pl";
require "pl/sub-ingene.pl";

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $verbose = 0;
my $true;
my $estimate;
my $numberreplicate;
my $block;
my $blocklength;
my $treetopology;
my $out;
my $ingene;
my $numbersample;
my $append = 0;

if (exists $params{ingene})
{
  $ingene = $params{ingene};
}
else
{
  &printError("you did not specify an ingene file");
}

if (exists $params{true})
{
  $true = $params{true};
}
else
{
  &printError("you did not specify a file for true values");
}

if (exists $params{estimate})
{
  $estimate = $params{estimate};
}
else
{
  &printError("you did not specify a base name for estimates");
}

if (exists $params{numberreplicate})
{
  $numberreplicate = $params{numberreplicate};
}
else
{
  &printError("you did not specify a number of replicates");
}

if (exists $params{numbersample})
{
  $numbersample = $params{numbersample};
}
else
{
  &printError("you did not specify a number of ClonalOrigin posterior samples");
}

if (exists $params{blocklength})
{
  $blocklength = $params{blocklength};
}
else
{
  &printError("you did not specify the length of the block");
}

if (exists $params{block})
{
  $block = $params{block};
}
else
{
  &printError("you did not specify a block ID");
}

if (exists $params{treetopology})
{
  $treetopology = $params{treetopology};
}
else
{
  &printError("you did not specify a species tree topology ID");
}

if (exists $params{out})
{
  $out = $params{out};
}
else
{
  &printError("you did not specify an output file");
}

if (exists $params{append})
{
  $append = 1;
}

if (exists $params{verbose})
{
  $verbose = 1;
}

################################################################################
## DATA PROCESSING
################################################################################
sub mt_get_value_gene ($$$);

my @genes = parse_in_gene ($ingene);

if ($append == 0)
{
  open OUT, ">$out";
  print OUT "gene\tstart\tend\tstrand\tblock\t";
  print OUT "blockstart\tblockend\tgenelength\tproportiongap\t";
  print OUT "mt\tmtest\tmt2\tmt2est\tmt3\tmt3est\n";
}
else
{
  open OUT, ">>$out";
}

for (my $i = 0; $i <= $#genes; $i++)
{
  my $h = $genes[$i];
  if ($block == $h->{block})
  { 
    my $start = $h->{blockstart};
    my $end = $h->{blockend};
    my $trueFile = "$true.1";
    my ($mt,$mt2,$mt3) = mt_get_value_gene ($trueFile, $start, $end);
     
    for (my $replicate = 1; $replicate <= $numberreplicate; $replicate++)
    {
      for (my $sample = 1; $sample < $numbersample; $sample++)
      {
        my $estimateFile = "$estimate-$replicate-out/core_co.phase3.xml.$block.$sample";
        my ($mtest,$mt2est,$mt3est) = mt_get_value_gene ($estimateFile, $start, $end);
        print OUT "$h->{gene}\t";
        print OUT "$h->{start}\t";
        print OUT "$h->{end}\t";
        print OUT "$h->{strand}\t";
        print OUT "$h->{block}\t";
        print OUT "$h->{blockstart}\t";
        print OUT "$h->{blockend}\t";
        print OUT "$h->{genelength}\t";
        print OUT "$h->{proportiongap}\t";
        print OUT "$mt\t$mtest\t$mt2\t$mt2est\t$mt3\t$mt3est\n";
      }
    }
    if ($verbose == 1)
    {
      print STDERR "$i/$#genes $h->{gene} done\r";
    }
  }
}

close OUT;

exit;

sub mt_get_value_gene ($$$)
{
  my ($f, $start, $end) = @_;
  open FILE, $f or die "Could not open $f";
  my $line = <FILE>;
  chomp $line;
  my @e = split /\t/, $line;
  my @eGene = @e[$start .. $end]; 
  my %seen = (); my @uniquE = grep { ! $seen{$_} ++ } @eGene;
  my $numberUniqueTopology = scalar (@uniquE);
  die "\$\#e and \$blocklength are different at $f"
    unless ($#e + 1) == $blocklength;

  my $v = 0;
  my $vTopology = 0;
  my $vCountTopology = 0;
  for (my $i = $start; $i < $end; $i++)
  {
    if ($e[$i] != $e[$i+1])
    {
      $v++;
    }
    if ($e[$i] != $treetopology)
    {
      $vTopology++;
    }
  }
  if ($e[$end] != $treetopology)
  {
    $vTopology++;
  }

  close FILE;
  return ($v, $vTopology, $numberUniqueTopology);
}

