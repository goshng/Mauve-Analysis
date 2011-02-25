#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: get-primary-jcvi-loci.pl
#   Date: 2011-02-10
#   Version: 0.1.0
#
#   Usage:
#      perl get-primary-jcvi-loci.pl [options]
#
#      Try 'perl get-primary-jcvi-loci.pl -h' for more information.
#
#   Purpose: get-primary-jcvi-loci.pl help you to find the assignment of JCVI loci to
#            genbank primary loci.
#            I tried to do this by executing parse-m3-locus.pl. 
#            bcp_m3_primary_to_jcvi.txt does not contain all the JCVI loci. This
#            was weird because the website said that it found more than 2,000
#            but it showed only 1,800. Anther way of doing this is to directly
#            download some information from JCVI CMR using wget command with the
#            following:
#            wget
#            http://cmr.jcvi.org/cgi-bin/CMR/shared/GenePage.cgi?locus=NTL04SP0008
#            -O 1
#            The locus starts from NTL04SP0001 and ends in NTL04SP1865. 
#            Search the download file for display_locus=. Locus tag and JCVI
#            locus are put together with a slash mark. 
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

my $VERSION = 'get-primary-jcvi-loci.pl 1.0.0';

my $man = 0;
my $help = 0;
my $perblock = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man, 'perblock' => \$perblock);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; }
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

get-primary-jcvi-loci.pl - Find the assignment of JCVI loci to genbank locus_tag

=head1 VERSION

get-primary-jcvi-loci.pl 1.0.0

=head1 SYNOPSIS

perl get-primary-jcvi-loci.pl.pl [-h] [-help] [-version] [-man] [-verbose] 

=head1 DESCRIPTION

get-primary-jcvi-loci.pl help you to find the assignment of JCVI loci to
genbank primary loci.
I tried to do this by executing parse-m3-locus.pl. 
bcp_m3_primary_to_jcvi.txt does not contain all the JCVI loci. This
was weird because the website said that it found more than 2,000
but it showed only 1,800. Anther way of doing this is to directly
download some information from JCVI CMR using wget command with the
following:
wget
http://cmr.jcvi.org/cgi-bin/CMR/shared/GenePage.cgi?locus=NTL04SP0008
-O 1
The locus starts from NTL04SP0001 and ends in NTL04SP1865. 
Search the download file for display_locus=. Locus tag and JCVI
locus are put together with a slash mark. 

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

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make get-primary-jcvi-loci.pl better.

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

################################################################
# Main
################################################################

my @primaryLoci;
my @jcviLoci;
my @elements;
my $line;

for (my $i = 1; $i <= 1865; $i++)
{
  my $found = 'false';
  my $command = sprintf ("%s%04d%s", 
                         "wget -q http://cmr.jcvi.org/cgi-bin/CMR/shared/GenePage.cgi?locus=NTL04SP",
                         $i, " -O $i.temp");
  system ($command);
  open FILE, "$i.temp" or die $!;
  while (<FILE>)
  {
    if (/display_locus=(\w+)\/(\w+)\&/)
    {
      my $locus_tag = $1;
      my $jcvi_locus = $2;
      print "$locus_tag:$jcvi_locus\n";
      $found = 'true';
      last;
    }
  }
  close (FILE);
  unlink ("$i.temp");
  if ($found eq 'false')
  {
    print "# $i\n";
  }
  sleep (3);
}


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
    print STDERR "ERROR: ".$msg.".\n\nTry \'get-primary-jcvi-loci.pl -h\' for more information.\nExit program.\n";
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

