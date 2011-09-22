#!/opt/local/bin/perl -w
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
require "pl/sub-simple-parser.pl";
require "pl/sub-newick-parser.pl";
require "pl/sub-error.pl";
require "pl/sub-array.pl";
require "pl/sub-xmfa.pl";

$| = 1; # Do not buffer output
my $VERSION = 'recombination-intensity1-map-wiggle.pl 1.0';
my $cmd = ""; 
sub process {
  my ($a) = @_; 
  $cmd = $a; 
}
my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'subtraction',
            'prior=s',
            'posteriorsize=i',
            'map=s',
            'out=s',
            '<>' => \&process
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $map;
my $outfile;
my $verbose = 0;
my $prior;

if (exists $params{prior})
{
  $prior = $params{prior};
}

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
  open ($outfile, ">", $params{out}) or die "cannot open > $params{out}: $!";
}
else
{
  $outfile = *STDOUT;   
}

if (exists $params{verbose})
{
  $verbose = 1;
}

if ($cmd eq "intensity")
{
  unless (exists $params{prior} and exists $params{posteriorsize})
  {
    &printError("command intensity needs option -prior.");
  }
}

################################################################################
## DATA PROCESSING
################################################################################
# Find the maximum.
my @values;
my $max = 0;
if ($cmd eq "scaled")
{
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
  print $outfile "track type=wiggle_0\n";
  print $outfile "fixedStep chrom=chr1 start=1 step=1 span=1\n";
  foreach my $v (@values)
  {
    $v /= $max;
    $v *= 1000; 
    print $outfile "$v\n";
  }
}
elsif ($cmd eq "intensity")
{
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
    push @values, $v; 
  }
  close MAP;

  # Print the wiggle file.
  print $outfile "track type=wiggle_0\n";
  print $outfile "fixedStep chrom=chr1 start=1 step=1 span=1\n";
  foreach my $v (@values)
  {
    if ($v > 0)
    {
      $v /= $params{posteriorsize};
      if (exists $params{subtraction})
      {
        $v -= $prior;
      }
      else
      {
        $v = log($v/$prior)/log(2);
      }
    }
    print $outfile "$v\n";
  }
}

if (exists $params{out})
{
  close $outfile;
}
__END__
=head1 NAME

recombination-intensity1-map-wiggle.pl - Convert map to wiggle

=head1 VERSION

v1.0, Sun May 15 16:25:25 EDT 2011

=head1 SYNOPSIS

perl pl/recombination-intensity1-map-wiggle.pl scaled -map ri1-map.txt

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

=item B<-map> <file>

The map file created by pl/recombination-intensity1-map.pl.

=item B<-out> <file>

The output file (Default: stdout)

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
