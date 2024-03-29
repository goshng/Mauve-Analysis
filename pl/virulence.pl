#!/usr/bin/perl
###############################################################################
# Copyright (C) 2011 Sang Chul Choi
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
use Getopt::Long;
use Pod::Usage;
require 'pl/sub-error.pl';
require 'pl/sub-ptt.pl';
require 'pl/sub-bed.pl';
$| = 1; # Do not buffer output
my $VERSION = 'virulence.pl 1.0';

my $cmd = ""; 
sub process {
  my ($a) = @_; 
  $cmd = $a; 
}

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'ptt=s',
            'bed=s',
            'virulence=s',
            'negate',
            'random',
            'ortholog=s',
            'gene=s',
            'in=s',
            'out=s',
            '<>' => \&process
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $in;
my $infile;
my $out;
my $outfile;

if (exists $params{in})
{
  $in = $params{in};
  open ($infile, "<", $in) or die "cannot open < $in: $!";
}
else
{
  $infile = *STDIN;   
}

if (exists $params{out})
{
  $out = "$params{out}";
  open ($outfile, ">", $out) or die "cannot open > $out: $!";
}
else
{
  $outfile = *STDOUT;   
}

if ($cmd eq "table")
{
  unless (exists $params{virulence} and exists $params{ortholog})
  {
    &printError("command table needs options -virulence, and -ortholog");
  }
}
elsif ($cmd eq "bed")
{
  unless (exists $params{virulence} 
          and (exists $params{ptt} or exists $params{bed}))
  {
    &printError("command bed needs options -virulence, and -ptt");
  }
}
elsif ($cmd eq "subset")
{
  unless (exists $params{virulence})
  {
    &printError("command $cmd needs options -virulence");
  }
}
elsif ($cmd eq "extract")
{
  unless (exists $params{gene}
          and exists $params{in})
  {
    &printError("command $cmd needs options -gene and -in");
  }
}

################################################################################
## DATA PROCESSING
################################################################################
if ($cmd eq "extract")
{
  my $line;
  if (exists $params{random})
  {
    die "Requires option -out" unless (exists $params{out});
    my $range = 10;
    my $random_number = rand($range);

    $line = <$infile>;
    my $outNegate = "$params{out}.not";
    my $outfileNegate;
    open ($outfileNegate, ">", $outNegate) or die "cannot open > $outNegate: $!";
    print $outfileNegate $line;
    print $outfile $line;
    while ($line = <$infile>)
    {
      my @e = split /\t/, $line;
      $random_number = rand($range);
      if ($random_number % $range == 0)
      {
        print $outfile $line;
      }
      else
      {
        print $outfileNegate $line;
      }
    }
    close $outfileNegate;
  }
  else
  {
    my %gene;
    open GENE, $params{gene} or die "cannot open $params{gene} $!";
    while ($line = <GENE>)
    {
      chomp $line;
      $gene{$line} = "TRUE";
    }
    close GENE;

    $line = <$infile>;
    print $outfile $line;
    while ($line = <$infile>)
    {
      my @e = split /\t/, $line;
      if (exists $params{negate})
      {
        unless (exists $gene{$e[0]})
        {
          print $outfile $line;
        }
      }
      else
      {
        if (exists $gene{$e[0]})
        {
          print $outfile $line;
        }
      }
    }
  }
  close $infile;
}
elsif ($cmd eq "subset")
{
  my $line;
  # Parse virulence file.
  my %virulence;
  open VIR, $params{virulence} or die "cannot open < $params{virulence} $!";
  $line = <VIR>;
  while ($line = <VIR>)
  {
    chomp $line;
    my @e = split /\t/, $line;
    $virulence{$e[0]} = $e[1];
  }
  close VIR;

  my @sns = ('SDE1', 'SDEG', 'SDD', 'SpyM3_', 'MGAS10750_', 'SEQ_');
  my @snsSynonym = ('sde1', 'sde2', 'sdd', 'spy1', 'spy2', 'see');
  for my $g (keys %virulence)
  {
    if ($g =~ /^SpyM3/)
    {
      if ($virulence{$g} eq "TRUE")
      {
        print $outfile "$g\n";
      }
    }
  }
}
elsif ($cmd eq "table")
{
  my $line;
  # Parse virulence file.
  my %virulence;
  open VIR, $params{virulence} or die "cannot open < $params{virulence} $!";
  $line = <VIR>;
  while ($line = <VIR>)
  {
    chomp $line;
    my @e = split /\t/, $line;
    $virulence{$e[0]} = $e[1];
  }
  close VIR;

  # Parse ortholog.
  my %ortholog;
  open ORTH, $params{ortholog} or die "cannot open < $params{ortholog} $!";
  while (<ORTH>)
  {
    chomp;
    my @e = split /\t/;
    $ortholog{$e[0]} = [ splice (@e, 1) ];
  }
  close ORTH;

  # Species names.
# SDE1*	sde1
# SDEG*	sde2
# SDD*	sdd
# SpyM3_*	spy1
# MGAS10750_*	spy2
# SEQ_*	see
  my @sns = ('SDE1', 'SDEG', 'SDD', 'SpyM3_', 'MGAS10750_', 'SEQ_');
  my @snsSynonym = ('sde1', 'sde2', 'sdd', 'spy1', 'spy2', 'see');

  # Count virulence genes.
  my %virulenceTable;
  foreach my $family (keys %ortholog)
  {
    my @e2;
    my @e = @{ $ortholog{$family} };
    foreach my $sn (@sns)
    {
      my $virulenceTableElement = 0;
      foreach my $g (@e)
      {
        if ($g =~ /^$sn/)
        {
          $virulenceTableElement = 1;
          if (exists $virulence{$g})
          {
            if ($virulence{$g} eq "TRUE")
            {
              $virulenceTableElement = 2;
            }
          }
        }
        if ($virulenceTableElement == 2)
        {
          last;
        }
      }
      push @e2, $virulenceTableElement;
    }
    $virulenceTable{$family} = [ @e2 ];
  }

  # Print the table.
  print $outfile "family";
  foreach my $sn (@snsSynonym)
  {
    print $outfile "\t$sn";
  }
  print $outfile "\n";
  my $count = 0;
  foreach my $family (keys %virulenceTable)
  {
    my $isVirulent = 0;
    foreach my $i (0 .. $#{ $virulenceTable{$family} })
    {
      if ($virulenceTable{$family}[$i] == 2)
      {
        $isVirulent = 1;
        last;
      }
    }
    
    # Print families with virulence genes.
    if ($isVirulent == 1)
    {
      print $outfile "$family";
      foreach my $i (0 .. $#{ $virulenceTable{$family} })
      {
        print $outfile "\t$virulenceTable{$family}[$i]";
      }
      print $outfile "\n";

      my $isAllVirulent = 1;
      foreach my $i (0 .. $#{ $virulenceTable{$family} })
      {
        if ($virulenceTable{$family}[$i] != 2)
        {
          $isAllVirulent = 0;
          last;
        }
      }
      if ($isAllVirulent == 1)
      {
        $count++;
      }
    }
  }
  print STDERR "Number of families with all of the genes being virulent: $count\n";
}
elsif ($cmd eq "bed")
{
  my $line;
  # Parse virulence file.
  my %virulence;
  open VIR, $params{virulence} or die "cannot open < $params{virulence} $!";
  $line = <VIR>;
  while ($line = <VIR>)
  {
    chomp $line;
    my @e = split /\t/, $line;
    $virulence{$e[0]} = $e[1];
  }
  close VIR;

  if (exists $params{ptt})
  {
    my @genesPtt = rnaseqPttParse ($params{ptt});
    foreach my $g (@genesPtt)
    {
      if (exists $virulence{$g->{Synonym}})
      {
        if ($virulence{$g->{Synonym}} eq "TRUE")
        {
          $g->{Location} =~ /(\d+)\.\.(\d+)/;
          my $start = $1;
          my $end = $2;
          my $name = $g->{Synonym};
          print $outfile "chr1\t$start\t$end\t$name\n";
        }
      }
    }
  }
  elsif (exists $params{bed})
  {
    my @genesBed = rnaseqBedParse ($params{bed});
    foreach my $g (@genesBed)
    {
      if (exists $virulence{$g->{name}})
      {
        if ($virulence{$g->{name}} eq "TRUE")
        {
          my $start = $g->{start};
          my $end = $g->{end};
          my $name = $g->{name};
          print $outfile "chr1\t$start\t$end\t$name\n";
        }
      }
    }
  }
  else
  {
    die "The gene annotations must be given as ptt or bed format.";
  }
}

if (exists $params{in})
{
  close $infile;
}
if (exists $params{out})
{
  close $outfile;
}

__END__
=head1 NAME

virulence.pl - Create a table for species and viruence genes.

=head1 VERSION

virulence.pl 1.0

=head1 SYNOPSIS

perl virulence.pl table -virulence virulent_genes.txt -ortholog fam-frag2.part.txt 

perl virulence.pl bed -virulence virulent_genes.txt -ptt genome.ptt

perl virulence.pl subset -virulence virulent_genes.txt

perl pl/virulence.pl extract -in in.gene.4.block -gene output/virulence/virulent_genes.txt.spy1

perl pl/virulence.pl extract -negate -in in.gene.4.block -gene output/virulence/virulent_genes.txt.spy1

=head1 DESCRIPTION

virulence.pl deals with virulence factors.

=head1 OPTIONS

  command: 

  table - creates a table of virulence genes among the 6 species.

  bed - create a BED-format file for the virulence genes. 

  subset - create a list of subset of virulence genes for SPY1. Genes of SPY1
  are listed.

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-virulence> <file>

A file with gene and its true/false of virulence.

=item B<-ortholog> <file>

Matt created a file for orthologous genes.

=item B<-out> <file>

An output file.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make virulence.pl better.

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
