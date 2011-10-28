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
require "pl/sub-error.pl";
require "pl/sub-xmfa.pl";

my $cmd = ""; 
sub process {
  my ($a) = @_; 
  $cmd = $a; 
}
$| = 1; # Do not buffer output

my $VERSION = 'remove-blocks-from-core-alignment.pl 0.1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'threshould=f',
            'in=s',
            'xmfa=s',
            'out=s',
            '<>' => \&process
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

my $infile;
my $outfile;

if (exists $params{in})
{
  open ($infile, "<", $params{in}) or die "cannot open < $params{in}: $!";
}
else
{
  $infile = *STDIN;   
}

if (exists $params{out})
{
  open ($outfile, ">", $params{out}) or die "cannot open > $params{out}: $!";
}
else
{
  $outfile = *STDOUT;   
}

unless (exists $params{threshould})
{
  $params{threshould} = 0.95;
}

################################################################################
## DATA PROCESSING
################################################################################

if ($cmd eq "count")
{
  my $line;
  my $c = 0;
  while ($line = <$infile>)
  {
    if ($line =~ /^=/)
    {
      $c++;
    }
  }
  print $outfile "$c\n";
}
elsif ($cmd eq "remove")
{
  my $blockID = 0;
  my $line;
  while ($line = <$infile>)
  {
    print $outfile $line if $line =~ /^#/;
    last if $line =~ /^>/;
  }

  my $blockLine = $line;
  my $blockSeq = "";
  while ($line = <$infile>)
  {
    $blockLine .= $line;
    if ($line =~ /^=/)
    {
      $blockID++;
      my $totalLength = length($blockSeq);
      my %numNuc;
      $numNuc{a} = $blockSeq =~ tr/a//;
      $numNuc{c} = $blockSeq =~ tr/c//;
      $numNuc{g} = $blockSeq =~ tr/g//;
      $numNuc{t} = $blockSeq =~ tr/t//;
      $numNuc{a} += $blockSeq =~ tr/A//;
      $numNuc{c} += $blockSeq =~ tr/C//;
      $numNuc{g} += $blockSeq =~ tr/G//;
      $numNuc{t} += $blockSeq =~ tr/T//;
      my $totalACGT = $numNuc{a} + $numNuc{c} + $numNuc{g} + $numNuc{t};
      # print $outfile $blockID, "\t", $totalACGT/$totalLength, "\n";
      if ($totalACGT/$totalLength > $params{threshould})
      {
        print $outfile $blockLine;
      }
      $blockSeq = "";
      $blockLine = "";
      next;
    }
    unless ($line =~ /^>/)
    {
      chomp $line;
      $blockSeq .= $line;
    }
  }
}

if (exists $params{out})
{
  close $outfile;
}
if (exists $params{in})
{
  close $infile;
}

exit;
#################################################################################
### MISC FUNCTIONS
#################################################################################

__END__
=head1 NAME

remove-blocks-from-core-alignment.pl - Remove blocks from a core alignment.

=head1 VERSION

v1 Fri Oct 28 15:30:38 EDT 2011

=head1 SYNOPSIS

To count the number of blocks in the XMFA alignment:

perl remove-blocks-from-core-alignment.pl count -in file.xmfa

To remove blocks with gap proportion above a threshould:

perl remove-blocks-from-core-alignment.pl remove < file.xmfa > file.xmfa.new

=head1 DESCRIPTION

Mauve and stripSubsetLCBs produce a core alignment: e.g.,
output/cornell6/1/data/core_alignment.xmfa. We want to have statistics of the
alignments. 

1. How many alignment blocks?

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-blocks> <number>,<number>,...

=item B<-fasta> <file>

Input file in FASTA format that contains the sequence data.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make remove-blocks-from-core-alignment.pl better.

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
