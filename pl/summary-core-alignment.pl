#!/usr/bin/perl
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: summary-core-alignment.pl
#   Date: Sun Jun 19 17:54:07 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'summary-core-alignment.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'in=s',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

summary-core-alignment.pl - Summary of the core alignment.

=head1 VERSION

summary-core-alignment.pl 1.0

=head1 SYNOPSIS

perl summary-core-alignment.pl.pl [-h] [-help] [-version] [-verbose] 
  [-in file] 
  [-out file] 

=head1 DESCRIPTION

summary-core-alignment.pl summarizes a core alignment.

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

A core alignment.

=item B<-out> <file>

The output file.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make summary-core-alignment.pl better.

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

require "pl/sub-xmfa.pl";

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $in;
my $out;
my $outfile;

if (exists $params{in}) {
  $in = $params{in};
} else {
  &printError("you did not specify a core alignment file name");
}

if (exists $params{out}) {
  $out = $params{out};
  print "$out\n";
  close STDOUT;
  open STDOUT, '>', $out or die "Can't open STDOUT: $!";
}

################################################################################
## DATA PROCESSING
################################################################################

my $l = xmfaLengthAllBlock ($in);
print "TotalLengthOfCoreAlignment:$l\n";
my $nb = xmfaNumberBlock ($in);
print "NumberOfBlock:$nb\n";
my $bs = xmfaBlockSize ($in);
print "BlockSize:$bs\n";


if (exists $params{out}) {
  close STDOUT;
}
