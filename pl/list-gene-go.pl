#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: list-gene-go.pl
#   Date: Fri May  6 20:28:29 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use XML::Parser;

$| = 1; # Do not buffer output

my $VERSION = 'list-gene-go.pl 1.0';

my $man = 0;
my $help = 0;
my $perblock = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man, 'perblock' => \$perblock);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'godesc=s',
            'desc2go=s',
            'go2gene=s',
            'gene2product=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

list-gene-go.pl - List gene names belonging to a gene ontology term

=head1 VERSION

list-gene-go.pl 1.0

=head1 SYNOPSIS

perl list-gene-go.pl.pl [-h] [-help] [-version] [-man] [-verbose] 
  [-godesc string]
  [-desc2go file]
  [-go2gene file] 
  [-gene2product file]

=head1 DESCRIPTION

list-gene-go.pl will help you to list gene names belonging to a gene ontology term.

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

=item B<-godesc> <string>

A gene ontology term description.

=item B<-desc2go> <file>

Melissa made a file named
SpyMGAS315_go_category_names.txt
that is a tab-delimited file. Description of columns are:
1st: Gene ontology term - e.g., GO:0019874
2nd: numbers
3rd: Name of the gene ontology term

=item B<-go2gene> <file>

Melissa also made a file named
SpyMGAS315_go_bacteria.txt
that is a tab-delimited file. Description of columns are:
1st: Locus tag - e.g., SpyM3_1865
2nd: Gene ontology term - e.g., GO:0019874 
3rd: P-value

=item B<-gene2product> <file>

A genbank file for the reference genome for the locus names.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make list-gene-go.pl better.

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

################################################################
# Input command options
################################################################

my $godesc;
my $desc2go;
my $go2gene;
my $gene2product;

if (exists $params{godesc})
{
  $godesc = $params{godesc};
} else {
  &printError("you did not specify a gene ontology term description");
}

if (exists $params{desc2go})
{
  $desc2go = $params{desc2go};
} else {
  &printError("you did not specify a desc2go filename");
}

if (exists $params{go2gene})
{
  $go2gene = $params{go2gene};
} else {
  &printError("you did not specify a go2gene filename");
}

if (exists $params{gene2product})
{
  $gene2product = $params{gene2product};
} else {
  &printError("you did not specify a gene2product filename");
}

################################################################
# The main function.
################################################################

sub findGOTermOfDesc ($$);
sub findGenesOfGO ($$);
sub findGeneDescriptionOfGene($$);

my $goterm = findGOTermOfDesc ($desc2go, $godesc);
my @genes = findGenesOfGO ($go2gene, $goterm);

for my $gene (@genes)
{
  my $v = findGeneDescriptionOfGene($gene2product, $gene);
  print "$gene\t$v\n";
}

exit;

################################################################
# Functions.
################################################################

sub findGeneDescriptionOfGene($$)
{
  my ($f, $s) = @_;
  my $v;
  my $found = "false";
  open FILE, $f or die "Could not open $f $!";
  while (<FILE>)
  {
    chomp;
    if (/\/locus_tag=\"$s\"/)
    {
      $found = "true";
    }
    if ($found eq "true")
    {
      if (/\/product=\"(.+)\"/)
      {
        $v = $1;
        last;
      }
    }
  }
  close FILE;

  return $v;
}

sub findGenesOfGO ($$)
{
  my ($f, $s) = @_;
  my @v;

  open FILE, $f or die "Could not open $f $!";
  while (<FILE>)
  {
    chomp;
    my @e = split /\t/;
    if ($e[1] eq $s)
    {
      push @v, $e[0];
    }
  }
  close FILE;

  return @v;
}

sub findGOTermOfDesc ($$)
{
  my ($f, $s) = @_;
  my $v = "";

  open FILE, $f or die "Could not open $f $!";
  while (<FILE>)
  {
    chomp;
    my @e = split /\t/;
    if ($e[2] eq $s)
    {
      $v = $e[0];
      last;
    }
  }
  close FILE;
  die "Could not find a gene ontology term for $s" if $v eq "";
  return $v;
}
