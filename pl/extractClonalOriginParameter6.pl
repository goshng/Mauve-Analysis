#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extractClonalOriginParameter6.pl
#   Date: Tue Apr 19 15:02:27 EDT 2011
#   Version: 1.0
#
#   Usage:
#      perl extractClonalOriginParameter6.pl [options]
#
#      Try 'perl extractClonalOriginParameter6.pl -h' for more information.
#
#   Purpose: extractClonalOriginParameter6.pl help you extract the 3 main
#            parameters from the output XML file of ClonalOrigin. 
#===============================================================================

use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'extractClonalOriginParameter6.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'version' => sub { print $VERSION."\n"; exit; },
            'xmlbase=s',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extractClonalOriginParameter6.pl - Build a heat map of recombination.

=head1 VERSION

extractClonalOriginParameter6.pl 1.0

=head1 SYNOPSIS

perl extractClonalOriginParameter6.pl [-h] [-help] [-version] 
  [-xmlbase filename] [-out file]

=head1 DESCRIPTION

The three scalar parameters include mutation rate, recombination rate, and
average recombinant tract length.  These values are extracted from 
ClonalOrigin XML output files.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-man>

Print the full documentation; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<***** INPUT OPTIONS *****>

=item B<-xmlbase> <file>

A prefix of ClonalOrigin output files in XML format is required.

=item B<-out> <base name of output file>

Three files are generated for the three parameters. The option string of out is
used as a base name of them: i.e., out.theta, out.rho, and out.delta.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extractClonalOriginParameter6.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

my $xmlFilebase;
my $basenameOutFile;

if (exists $params{xmlbase})
{
  $xmlFilebase = $params{xmlbase};
}
else
{
  &printError("you did not specify an XML file that contains Clonal Origin run results");
}

if (exists $params{out})
{
  $basenameOutFile = $params{out};
}
else
{
  &printError("you did not specify a base name of the output file");
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

##############################################################
# Global variables
##############################################################
my $tag;
my $content;
my $itercount=0;

##############################################################
# Open the three output files.
##############################################################
open OUTTHETA, ">$basenameOutFile.theta" or die $!;
open OUTRHO, ">$basenameOutFile.rho" or die $!;
open OUTDELTA, ">$basenameOutFile.delta" or die $!;

##############################################################
# Start to parse the XML file.
##############################################################
my $blockID;
my $blockLength;

my @xmlFiles = <$xmlFilebase.*.xml>;
foreach my $xmlFile (@xmlFiles) {

  $xmlFile =~ /\.(\d+)\.xml/;
  $blockID = $1;
  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  my $doc;
  $itercount = 0;
  eval{ $doc = $parser->parsefile($xmlFile)};
  print "Unable to parse XML of $xmlFile, error $@\n" if $@;
}

close OUTTHETA;
close OUTRHO;
close OUTDELTA;

exit;
##############################################################
# END OF RUN OF THIS PERL SCRIPT
##############################################################

##############################################################
# XML Processing procedures
##############################################################
sub startElement {
  my( $parseinst, $element, %attrs ) = @_;
  $tag = $element;
  $content = "";
  SWITCH: {
    if ($element eq "Iteration") {
      $itercount++;
      last SWITCH;
    }
    if ($element eq "theta") {
      last SWITCH;
    }
    if ($element eq "delta") {
      last SWITCH;
    }
    if ($element eq "rho") {
      last SWITCH;
    }
  }
}

sub endElement {
  my ($p, $elt) = @_;
  if($tag eq "theta"){
    my $thetaPerSite = $content / $blockLength;
    print OUTTHETA "$blockID\t$thetaPerSite\n";
  }
  if($tag eq "rho"){
    my $rhoPerSite = $content / $blockLength;
    print OUTRHO "$blockID\t$rhoPerSite\n";
  }
  if($tag eq "delta"){
    print OUTDELTA "$blockID\t$content\n";
  }
  $tag = "";
  $content = "";
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;
  if($tag eq "theta"){
    $content .= $data;
  }
  if($tag eq "rho"){
    $content .= $data;
  }
  if($tag eq "delta"){
    $content .= $data;
  }
  if ($tag eq "Blocks") {
    if (length($data) > 1) {
      # print "$tag:$data\n";
      $data =~ s/.+\,//g;
      $blockLength = $data;
      # print "$blockLength\n";
      die "block length is not a positive integer ($blockLength)" unless $blockLength > 0;
    }
  }
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
  print STDERR "ERROR: ".$msg.".\n\nTry \'extractClonalOriginParameter6.pl -h\' for more information.\nExit program.\n";
  exit(0);
}
