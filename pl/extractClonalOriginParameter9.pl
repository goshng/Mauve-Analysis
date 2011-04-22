#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extractClonalOriginParameter9.pl
#   Date: Thu Apr 21 12:42:10 EDT 2011
#   Version: 1.0
#
#   Usage:
#      perl extractClonalOriginParameter9.pl [options]
#
#      Try 'perl extractClonalOriginParameter9.pl -h' for more information.
#
#   Purpose: We parse a clonal origin XML file. 
#
#   Note that I started to code this based on PRINSEQ by Robert SCHMIEDER at
#   Computational Science Research Center @ SDSU, CA as a template. Some of
#   words are his not mine, and credit should be given to him. 
#===============================================================================

use strict;
use warnings;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'extractClonalOriginParameter9.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'xml=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extractClonalOriginParameter9.pl - Build a heat map of recombination.

=head1 VERSION

extractClonalOriginParameter9.pl 0.1.0

=head1 SYNOPSIS

perl extractClonalOriginParameter9.pl [-h] [-help] [-version] 
  [-xml xmlfile] 

=head1 DESCRIPTION

An XML Clonal Origin file is divided into files for multiple blocks.

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

=item B<-xml> <xmlfile>

A clonal origin XML file.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extractClonalOriginParameter9.pl better.

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

require "pl/sub-simple-parser.pl";

my $xmlFile;

if (exists $params{xml})
{
  $xmlFile = $params{xml};
}
else
{
  &printError("you did not specify an XML file that contains Clonal Origin 2nd run results");
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

##############################################################
# Global variables
##############################################################
my $numberBlock; 
my @xmlFiles;
my @blocks;
my $tag;
my $content;
my %recedge;
my $itercount=0;

my $parser = new XML::Parser();
$parser->setHandlers(Start => \&startElement,
                     End => \&endElement,
                     Char => \&characterData,
                     Default => \&default);

$itercount=0;
my $doc;
eval{ $doc = $parser->parsefile($xmlFile)};
print "Unable to parse XML of $xmlFile, error $@\n" if $@;
 
exit;
##############################################################
# END OF RUN OF THIS PERL SCRIPT
##############################################################

#############################################################
# XML Parsing functions
#############################################################

sub startElement {
  my ($parseinst, $e, %attrs) = @_;
#  $tag = $element;
  $content = "";
  if ($e eq "Iteration") {
    $itercount++;
  }
  if ($e eq "outputFile") {
    # The start of XML file.
  }
}

sub endElement {
  my ($p, $elt) = @_;

  if ($elt eq "Blocks") {
    @blocks = split /,/, $content;
    $numberBlock = $#blocks;
    for (my $i = 0; $i < $#blocks; $i++)
    {
      my $xmlFileBlock = "$xmlFile.$i";
      my $f;
      open $f, ">$xmlFileBlock" 
        or die "Could not open $xmlFileBlock";
      push @xmlFiles, $f;
      print $f i" <?xml version = '1.0' encoding = 'UTF-8'?>kkkkjjj:wq
    }

  }

  if ($elt eq "outputFile") {
    # The end of XML file.
    foreach (@xmlFiles)
    {
      close;
    }
  }

  if ($elt eq "efrom") {
    $recedge{efrom} = $content;
  }
  if ($elt eq "eto") {
    $recedge{eto} = $content;
  }

  if ($elt eq "recedge")
  {
  }
  
#  $tag = "";
  $content = "";
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;

  $content .= $data;
}

sub default {
}

##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'extractClonalOriginParameter9.pl -h\' for more information.\nExit program.\n";
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
