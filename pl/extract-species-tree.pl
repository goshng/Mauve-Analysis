#!/usr/bin/perl
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extract-species-tree.pl
#   Date: Wed May 11 21:58:27 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'extract-species-tree.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'out=s',
            'xml=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extract-species-tree.pl - Extract species tree from ClonalOrigin XML file

=head1 VERSION

extract-species-tree.pl 1.0

=head1 SYNOPSIS

perl extract-species-tree.pl.pl [-h] [-help] [-version] [-verbose] [-base basename] 

=head1 DESCRIPTION

extract-species-tree.pl extracts species tree from ClonalOrigin XML file.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-xml> <file>

A ClonalOrigin XML file.

=item B<-out> <file>

An output file.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extract-species-tree.pl better.

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

require "pl/sub-simple-parser.pl";

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $xml;
my $out;

if (exists $params{xml}) {
  $xml = $params{xml};
} else {
  &printError("you did not specify an ClonalOrigin XML file");
}

if (exists $params{out}) {
  $out = $params{out};
} else {
  &printError("you did not specify an output file");
}

################################################################################
## DATA PROCESSING
################################################################################
my $v = get_species_tree ($xml);
open OUT, ">$out" or die "Could not open $out";
print OUT "$v\n";
close OUT;
