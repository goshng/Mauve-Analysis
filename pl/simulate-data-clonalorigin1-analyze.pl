#!/usr/bin/perl
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: simulate-data-clonalorigin1-analyze.pl
#   Date: Sat May 14 07:54:44 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'simulate-data-clonalorigin1-analyze.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'in=s',
            'numbersample=i',
            'delta',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

simulate-data-clonalorigin1-analyze.pl - Summarize results of simulation 1

=head1 VERSION

simulate-data-clonalorigin1-analyze.pl 1.0

=head1 SYNOPSIS

perl simulate-data-clonalorigin1-analyze.pl.pl [-h] [-help] [-version] [-verbose]
  [-in file] 
  [-out file] 
  [-numbersample number] 

=head1 DESCRIPTION

simulate-data-clonalorigin1-analyze.pl summarizes results of simulation 1.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-in> <file>

Menu simulate-data-clonalorigin1-analyze generates three files out.theta,
out.delta, and out.rho. The number of rows is equal to the number of
repetitions. Each row there are numbers.

=item B<-numbersample> <number>

The number of sample size.

=item B<-out> <file>

The output file of this PERL script.

=item B<-delta>

The way that I compute weighted median of delta is different from those of
computing weighted medians of mu and rho.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make simulate-data-clonalorigin1-analyze.pl better.

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

my $in;
my $outfile;
my $numbersample;
my $delta = 0;

if (exists $params{in}) {
  $in = $params{in};
} else {
  &printError("you did not specify an input file");
}

if (exists $params{out})
{
  open ($outfile, ">", $params{out}) or die "cannot open > $params{out}: $!";
}
else
{
  $outfile = *STDOUT;   
}

if (exists $params{numbersample}) {
  $numbersample = $params{numbersample};
} else {
  &printError("you did not specify an number for samples");
}

if (exists $params{delta}) {
  $delta = 1;
}

################################################################################
## DATA PROCESSING
################################################################################

sub reportNumberColumnRow ($);
sub computeWeightedMedian ($);
sub computeMedianWeighedOverBlockLength ($$$$$);

#reportNumberColumnRow ($in);
computeWeightedMedian ($in);

sub computeWeightedMedian ($)
{
  my ($f) = @_;
  my $row = 0;
  open IN, $f or die "Could not open $f - $!";
  while (<IN>)
  {
    $row++;
    my @meantheta;
    my @meanrho;
    my @meandelta;
    my @lens;
    my @blockIDs;
    chomp;
    my @e = split /\s+/;
    shift @e;
    my $col = scalar @e;
    my $numberElementBlock = 3 * $numbersample + 2;
    my $numberBlock = $col / ($numberElementBlock);
    for (my $i = 0; $i < $numberBlock; $i++)
    {
      my $curtheta = 0;
      my $currho = 0;
      my $curdelta = 0;
      my $blocksize = $e[$i * $numberElementBlock + 1];
      my $blockid   = $e[$i * $numberElementBlock + 0];
      if ($blockid =~ /Block(\d+)/)
      {
        $blockid = $1;
      }
      else
      {
        die "Errors in parsing $f - $blockid";
      }
      for (my $j = 0; $j < $numbersample; $j++)
      {
        $curtheta += $e[$i * $numberElementBlock + $j * 3 + 2];
        $currho   += $e[$i * $numberElementBlock + $j * 3 + 2 + 1];
        $curdelta += $e[$i * $numberElementBlock + $j * 3 + 2 + 2];
      }
      $curtheta /= $numbersample;
      $currho   /= $numbersample;
      $curdelta /= $numbersample;
      push @meantheta, $curtheta;
      push @meanrho, $currho;
      push @meandelta, $curdelta;
      push @lens, $blocksize;
      push @blockIDs, $blockid;
    }
    # Find the weight median of the @mean
    my @wm = computeMedianWeighedOverBlockLength (\@meantheta, 
                                                  \@meanrho,
                                                  \@meandelta,
                                                  \@lens,
                                                  \@blockIDs);
    print $outfile "$wm[0]\t$wm[2]\t$wm[1]\n";
  }
  close IN;
}

if (exists $params{out})
{
  close $outfile;
}
exit;

sub computeMedianWeighedOverBlockLength ($$$$$)
{
  my ($meantheta, $meanrho, $meandelta, $lens, $blockIDs) = @_;
  my @v;
  for( my $i = 0; $i < @{ $meantheta }; $i++) {
    $meantheta->[$i] /= $lens->[$i];
    $meanrho->[$i] /= $meandelta->[$i] + $lens->[$i] - 1;
  }

  # now compute a weighted median
  my %thetalens;
  my %deltalens;
  my %rholens;
  my $lensum = 0;
  for( my $i = 0; $i < @{ $meantheta }; $i++){
    $thetalens{$meantheta->[$i]} = $lens->[$i];
    $deltalens{$meandelta->[$i]} = $lens->[$i];
    $rholens{$meanrho->[$i]}     = $lens->[$i];
    $lensum += $lens->[$i];
  }
  #print "lensum is $lensum\n";

  my @tsort = sort{ $a <=> $b } @{ $meantheta };
  my @dsort = sort{ $a <=> $b } @{ $meandelta };
  my @rsort = sort{ $a <=> $b } @{ $meanrho };
  my $j = 0;
  for(my $ttally=$thetalens{$tsort[$j]}; $ttally < $lensum/2; $ttally += $thetalens{$tsort[$j]})
  {
    $j++;
  }
  push @v, $tsort[$j];
  #print "Median theta:".$tsort[$j]."\n";

  $j = 0;
  for(my $dtally=$deltalens{$dsort[$j]}; $dtally < $lensum/2; $dtally += $deltalens{$dsort[$j]})
  {
    $j++;
  }
  push @v, $dsort[$j];
  #print "Median delta:".$dsort[$j]."\n";

  $j = 0;
  for(my $rtally=$rholens{$rsort[$j]}; $rtally < $lensum/2; $rtally += $rholens{$rsort[$j]})
  {
    $j++;
  }
  push @v, $rsort[$j];
  #print "Median rho:".$rsort[$j]."\n";
  return @v;
}


sub reportNumberColumnRow ($)
{
  my ($f) = @_;
  my $row = 0;
  open IN, $f or die "Could not open $f - $!";
  while (<IN>)
  {
    $row++;
    chomp;
    my @e = split /\s+/;
    shift @e;
    my $col = scalar @e;
    print "$row - $col First is $e[0]\n";
  }
  close IN;
}

