#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: parse-jcvi-role.pl
#   Date: 2011-02-10
#   Version: 0.1.0
#
#   Usage:
#      perl parse-jcvi-role.pl [options]
#
#      Try 'perl parse-jcvi-role.pl -h' for more information.
#
#   Purpose: parse-jcvi-role.pl help you to parse the HTML file at
#            http://cmr.jcvi.org/cgi-bin/CMR/shared/RoleList.cgi
#            to find the assignment of JCVI role identifiers to JCVI role
#            categories.
#
#   Note that I started to code this based on PRINSEQ by Robert SCHMIEDER at
#   Computational Science Research Center @ SDSU, CA as a template. Some of
#   words are his not mine, and credit should be given to him. 
#===============================================================================

use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);
use XML::Parser;

$| = 1; # Do not buffer output

my $VERSION = 'parse-jcvi-role.pl 1.0.0';

my $man = 0;
my $help = 0;
my $perblock = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man, 'perblock' => \$perblock);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'in=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

parse-jcvi-role.pl - Find the assignment of JCVI role IDs to roles

=head1 VERSION

parse-jcvi-role.pl 1.0.0

=head1 SYNOPSIS

perl parse-jcvi-role.pl.pl [-h] [-help] [-version] [-man] [-verbose] 
  [-in html_file]

=head1 DESCRIPTION

parse-jcvi-role.pl help you to parse the HTML file at
http://cmr.jcvi.org/cgi-bin/CMR/shared/RoleList.cgi
to find the assignment of JCVI role identifiers to JCVI role
categories.

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

=item B<-in> <file>

The HTML file that is saved from the web site at
http://cmr.jcvi.org/cgi-bin/CMR/shared/RoleList.cgi

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make parse-jcvi-role.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

################################################################
# Input command options
################################################################

my $htmlFilename;
if (exists $params{in})
{
  $htmlFilename = $params{in};
} else {
  &printError("you did not specify a html filename");
}

################################################################
# Main
################################################################

open HTML, $htmlFilename or die $!;
while (<HTML>)
{
  # if (/role_category_list\&string_to_search=\&([\d\&]+)\&string_to_display=([\w\s]+)\&/)
  if (/role_category_list\&string_to_search=(.+)\&string_to_display=(.+)\&/)
  {
    print "$1:$2\n";
  }
}
close (HTML);

exit;

#################################################################################
### Main FUNCTIONS
#################################################################################

##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'parse-jcvi-role.pl -h\' for more information.\nExit program.\n";
    exit(0);
}

sub getLineNumber {
    my $file = shift;
    my $lines = 0;
    open(FILE,"perl -p -e 's/\r/\n/g' < $file |") or die "ERROR: Could not open file $file: $! \n";
    $lines += tr/\n/\n/ while sysread(FILE, $_, 2 ** 16);
    close(FILE);
    return $lines;
}


sub checkFileFormat {
    my $file = shift;

    open(FILE,"perl -p -e 's/\r/\n/g' < $file |") or die "ERROR: Could not open file $file: $! \n";
    while (<FILE>) {
    }
    close(FILE);

    my $format = 'map';
    return $format;
}

