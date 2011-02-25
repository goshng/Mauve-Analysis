#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: parse-m3-locus.pl
#   Date: 2011-02-10
#   Version: 0.1.0
#
#   Usage:
#      perl parse-m3-locus.pl [options]
#
#      Try 'perl parse-m3-locus.pl -h' for more information.
#
#   Purpose: parse-m3-locus.pl help you to find the assignment of JCVI loci to
#            genbank primary loci.
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

my $VERSION = 'parse-m3-locus.pl 1.0.0';

my $man = 0;
my $help = 0;
my $perblock = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man, 'perblock' => \$perblock);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'primary=s',
            'jcvi=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

parse-m3-locus.pl - Find the assignment of JCVI loci to genbank locus_tag

=head1 VERSION

parse-m3-locus.pl 1.0.0

=head1 SYNOPSIS

perl parse-m3-locus.pl.pl [-h] [-help] [-version] [-man] [-verbose] 
  [-primary file] [-jcvi file]

=head1 DESCRIPTION

parse-m3-locus.pl help you to find the assignment of JCVI loci to
genbank primary loci.

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
com repository so that I can make parse-m3-locus.pl better.

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

my $primaryFilename;
my $jcviFilename;
if (exists $params{primary})
{
  $primaryFilename = $params{primary};
} else {
  &printError("you did not specify an bcp_m3_primary_locus.txt");
}

if (exists $params{jcvi})
{
  $jcviFilename = $params{jcvi};
} else {
  &printError("you did not specify an bcp_m3_jcvi_locus.txt");
}

################################################################
# Main
################################################################

my @primaryLoci;
my @jcviLoci;
my @elements;
my $line;

open PRIMARY, $primaryFilename or die $!;
$line = <PRIMARY>;
chomp($line);
while (<PRIMARY>)
{
  chomp;
  @elements = split /\t/;
  push @primaryLoci, [ @elements ];
}
close (PRIMARY);

open JCVI, $jcviFilename or die $!;
chomp($line);
$line = <JCVI>;
while (<JCVI>)
{
  chomp;
  @elements = split /\t/;
  push @jcviLoci, [ @elements ];
}
close (JCVI);

# 0:Locus
# 1:Gene Symbol
# 2:Common Name <- Use this.
# 3:EC Number
# 4:5' End <- Use this.
# 5:3' End <- Use this.
# 6:Evidence Code: Function
# 7:Evidence Code: Process
# 8:DNA molecule

my %primary2jcvi;
for my $i ( 0 .. $#primaryLoci ) 
{
  my $found = 'false';
  for my $jcviI ( 0 .. $#jcviLoci ) 
  {
    if ($primaryLoci[$i][4] eq $jcviLoci[$jcviI][4]
        and $primaryLoci[$i][5] eq $jcviLoci[$jcviI][5])
    {
      $primary2jcvi{$primaryLoci[$i][0]} = $jcviLoci[$jcviI][0];
      $found = 'true';
      last;
    }
  }
  if ($found eq 'false')
  {
    # die "$primaryLoci[$i][0] does not have its corresponding JCVI locus";
    print "# $primaryLoci[$i][0]\n";
  }
}

foreach my $primary ( keys %primary2jcvi )
{
  print "$primary:$primary2jcvi{$primary}\n";
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
    print STDERR "ERROR: ".$msg.".\n\nTry \'parse-m3-locus.pl -h\' for more information.\nExit program.\n";
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

