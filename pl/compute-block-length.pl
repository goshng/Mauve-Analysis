#!/usr/bin/perl
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: compute-block-length.pl
#   Date: 2011-04-08
#   Version: 1.0
#
#   Usage:
#      perl compute-block-length.pl [basename]
#
#      Try 'perl compute-block-length.pl -h' for more information.
#
#   Purpose: compute-block-length.pl help you to count the lengths of blocks.
#===============================================================================

use strict;
use warnings;

#use Data::Dumper;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'compute-block-length.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'base=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

compute-block-length.pl - Computes the lengths of blocks

=head1 VERSION

compute-block-length.pl 1.0

=head1 SYNOPSIS

perl compute-block-length.pl.pl [-h] [-help] [-version] [-verbose] [-base basename] 

=head1 DESCRIPTION

compute-block-length.pl counts the lengths of blocks.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-base> <basename>

The alignment files are in a directory called run-lcb. They are prefixed with
core_alignment.xmfa, and suffixed with dot and numbers: i.e.,
core_alignment.xmfa.1.  The base name includes the base directory as well so
that the script can locate an alignment file with its full path.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make compute-block-length.pl better.

=head1 COPYRIGHT

Copyright (C) 2011 Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

sub lengthBlock ($);
#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $basename;
if (exists $params{base}) {
  $basename = $params{base};
} else {
  &printError("you did not specify a base name");
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

my $blockID = 1;
my $xmfaFilename = "$basename.$blockID";

while (-e $xmfaFilename) {
  my $l = lengthBlock ($xmfaFilename);
  print $l, "\n";
  $blockID++;
  $xmfaFilename = "$basename.$blockID";
}

sub lengthBlock ($)
{
  my ($f) = @_;
  my $line;
  my $sequence = "";
  open XMFA, $f or die $!;
  while ($line = <XMFA>)
  {
    chomp $line;
    next if $line =~ /^#/;
    last if $line =~ /^>/;
  }
  while ($line = <XMFA>)
  {
    chomp $line;
    if ($line =~ /^>/)
    {
      last;
    }
    $sequence .= $line; 
  }
  close (XMFA);
  return length($sequence);
}

