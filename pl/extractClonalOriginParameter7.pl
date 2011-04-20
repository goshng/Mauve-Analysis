#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: extractClonalOriginParameter7.pl
#   Date: Tue Apr 19 15:02:27 EDT 2011
#   Version: 1.0
#
#   Usage:
#      perl extractClonalOriginParameter7.pl [options]
#
#      Try 'perl extractClonalOriginParameter7.pl -h' for more information.
#
#   Purpose: extractClonalOriginParameter7.pl help you extract the number of
#            recombination events that happen within blocks
#            using the output XML files of ClonalOrigin. 
#===============================================================================

use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'extractClonalOriginParameter7.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'version' => sub { print $VERSION."\n"; exit; },
            'xmlbase=s',
            'xmfabase=s',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

extractClonalOriginParameter7.pl - Build a heat map of recombination.

=head1 VERSION

extractClonalOriginParameter7.pl 1.0

=head1 SYNOPSIS

perl extractClonalOriginParameter7.pl [-h] [-help] [-version] 
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

=item B<-xmfabase> <file>

A prefix of alignmet in XMFA format is required.

=item B<-out> <base name of output file>

Three files are generated for the three parameters. The option string of out is
used as a base name of them: i.e., out.theta, out.rho, and out.delta.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make extractClonalOriginParameter7.pl better.

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

sub getMidPosition ($);

my $xmlFilebase;
my $xmfaFilebase;
my $basenameOutFile;

if (exists $params{xmlbase})
{
  $xmlFilebase = $params{xmlbase};
}
else
{
  &printError("you did not specify an XML file that contains Clonal Origin run results");
}

if (exists $params{xmfabase})
{
  $xmfaFilebase = $params{xmfabase};
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
open OUTRECOMB, ">$basenameOutFile.recomb" or die $!;

##############################################################
# Start to parse the XML file.
##############################################################
my $blockID;
my $blockLength;
my $start;
my $end;
my $numberRecEdge;
my $curR;
my @lens;
my @meanR;

my @xmlFiles = <$xmlFilebase.*.xml>;
foreach my $xmlFile (@xmlFiles) {
  $xmlFile =~ /\.(\d+)\.xml/;
  $blockID = $1;
  my $position = getMidPosition ("$xmfaFilebase.$blockID");
  my $parser = new XML::Parser();
  $parser->setHandlers(Start => \&startElement,
                       End => \&endElement,
                       Char => \&characterData,
                       Default => \&default);

  my $doc;
  $itercount = 0;
  $curR = 0;
  eval{ $doc = $parser->parsefile($xmlFile)};
  print "Unable to parse XML of $xmlFile, error $@\n" if $@;
  print OUTRECOMB "\t$blockLength\t$blockID\t$position\n";
  $curR /= $itercount;
  push @meanR, $curR;
  #last;
}

# convert to per-site values of theta and rho
for (my $i = 0; $i < @meanR; $i++) {
  $meanR[$i] /= $lens[$i];
}

# now compute a weighted median
my %Rlens;
my $lensum = 0;
for (my $i = 0; $i < @meanR; $i++) {
  $Rlens{$meanR[$i]} = $lens[$i];
  $lensum += $lens[$i];
}
print "lensum is $lensum\n";


my @Rsort = sort{ $a <=> $b } @meanR;

my $j = 0;
for (my $Rtally = $Rlens{$Rsort[$j]}; 
     $Rtally < $lensum/2; 
     $Rtally += $Rlens{$Rsort[$j]})
{
  $j++;
}
print "Median R: ".$Rsort[$j]."\n";

close OUTRECOMB;

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
      $numberRecEdge = 0;
      last SWITCH;
    }
    if ($element eq "recedge") {
      last SWITCH;
    }
    if ($element eq "start") {
      last SWITCH;
    }
    if ($element eq "end") {
      last SWITCH;
    }
  }
}

sub endElement {
  my ($p, $elt) = @_;
  if ($tag eq "start") {
    $start = $content;
  }
  if ($tag eq "end") {
    $end = $content;
  }
  if ($elt eq "recedge") {
    if (0 < $start and $end < $blockLength) {
      $numberRecEdge++;
    } 
  }
  if ($elt eq "Iteration") {
    print OUTRECOMB "\t" if $itercount > 1;
    print OUTRECOMB $numberRecEdge;
    $curR += $numberRecEdge;
  }
  $tag = "";
  $content = "";
}

sub characterData {
  my( $parseinst, $data ) = @_;
  $data =~ s/\n|\t//g;
  if($tag eq "start"){
    $content .= $data;
  }
  if($tag eq "end"){
    $content .= $data;
  }
  if ($tag eq "Blocks") {
    if (length($data) > 1) {
      # print "$tag:$data\n";
      $data =~ s/.+\,//g;
      $blockLength = $data;
      # print "$blockLength\n";
      die "block length is not a positive integer ($blockLength)" unless $blockLength > 0;
      push @lens, $blockLength;
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
  print STDERR "ERROR: ".$msg.".\n\nTry \'extractClonalOriginParameter7.pl -h\' for more information.\nExit program.\n";
  exit(0);
}


sub getMidPosition ($)
{
  my ($f) = @_;
  my $v;
  open XMFA, $f or die $!;
  while (<XMFA>) {
    if (/^>\s+(\d+):(\d+)-(\d+)/) {
      die "$1 is not 1" unless $1 == 1;
      $v = ($2 + $3)/2;
      last;
    }
  }
  close XMFA;
  return $v;
}
