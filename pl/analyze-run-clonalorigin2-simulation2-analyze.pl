#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: analyze-run-clonalorigin2-simulation2-analyze.pl
#   Date: Tue May 10 09:58:36 EDT 2011
#   Version: 1.0
#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'analyze-run-clonalorigin2-simulation2-analyze.pl 1.0';

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
            'block=i',
            'out=s',
            'append'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

analyze-run-clonalorigin2-simulation2-analyze.pl - Generate a table for menu
analyze-run-clonalorigin2-simulation2-analyze

=head1 VERSION

analyze-run-clonalorigin2-simulation2-analyze.pl 1.0

=head1 SYNOPSIS

perl analyze-run-clonalorigin2-simulation2-analyze.pl 
  [-h] [-help] [-version] 
  [-true file] 
  [-estimate file base name] 
  [-numberreplicate number] 
  [-block number] 
  [-out file] 
  [-append] 

=head1 DESCRIPTION

Menus analyze-run-clonalorigin2-simulation2-prepare,
analyze-run-clonalorigin2-simulation2-receive,
analyze-run-clonalorigin2-simulation2-analyze are used to validate the first
surrogate measure of recombination intensity. 
True values of this measure can be found at
output/s14/1/run-analysis/ri-true/2
for REPETITION=1, BLOCK=2. A number of replicates are found at
output/s14/1/run-clonalorigin/output2/ri-3/2
for REPETITION=1, BLOCK=2, REPLICATE=3. Each file is tab-delimited with gene
name and its value. I make a table for each replicate with columns: gene, true,
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
com repository so that I can make analyze-run-clonalorigin2-simulation2-analyze.pl better.

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

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $verbose = 0;
my $true;
my $estimate;
my $numberreplicate;
my $block;
my $out;
my $append = 0;

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

if (exists $params{block})
{
  $block = $params{block};
}
else
{
  &printError("you did not specify a block ID");
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
sub parse_file_gene_colon_value ($);

my @genes = parse_file_gene_colon_value ($true);

if ($append == 0)
{
  open OUT, ">$out";
}
else
{
  open OUT, ">>$out";
}

for (my $replicate = 1; $replicate <= $numberreplicate; $replicate++)
{
  my $estimateFile = "$estimate-$replicate/$block";
  my @estimate = parse_file_gene_colon_value ($estimateFile);
  for (my $i = 0; $i <= $#genes; $i++)
  {
    my $hi = $genes[$i];
    my $hj = $estimate[$i];
    die "$hi->{gene} $hj->{gene} are different" 
      unless $hi->{gene} eq $hj->{gene};
    print OUT "$hi->{gene}\t$hi->{value}\t$hj->{value}\n"; 
  }
}

close OUT;

exit;

sub parse_file_gene_colon_value ($)
{
  my ($f) = @_;
  my @genes;
  open F, $f or die "Could not open $f";
  my $line = <F>;
  chomp $line;
  my @e = split /\t/, $line; 
  for my $g (@e)
  {
    my ($gene, $value) = split /:/, $g;
    my $rec = {};
    $rec->{gene} = $gene;
    $rec->{value} = $value;
    push @genes, $rec;
  }
  close F;
  return @genes;
}


