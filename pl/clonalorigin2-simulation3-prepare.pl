#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: clonalorigin2-simulation3-prepare.pl
#   Date: Mon May  9 00:24:54 EDT 2011
#   Version: 1.0
#===============================================================================

use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'clonalorigin2-simulation3-prepare.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'check',
            'version' => sub { print $VERSION."\n"; exit; },
            'xml=s',
            'out=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

clonalorigin2-simulation3-prepare.pl - Split an XML file.

=head1 VERSION

clonalorigin2-simulation3-prepare.pl 0.1.0

=head1 SYNOPSIS

perl clonalorigin2-simulation3-prepare.pl [-h] [-help] [-version] 
  [-xml xmlfile] 
  [-out xmlfile]

=head1 DESCRIPTION

A perl script called pl/splitCOXMLPerIteration.pl splits all of the XML files
into more XML files for each iteration. 

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

=item B<-xml> <file>

A ClonalOrigin XML file.

=item B<-out> <prefix of file name>

A ClonalOrigin XML file with different path.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make clonalorigin2-simulation3-prepare.pl better.

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

my $xml;
my $out;
my $verbose = 0;

if (exists $params{xml})
{
  $xml= $params{xml};
}
else
{
  &printError("you did not specify an XML file");
}

if (exists $params{out})
{
  $out = $params{out};
}
else
{
  &printError("you did not specify a prefix of XML file name");
}

if (exists $params{verbose})
{
  $verbose = 1;
}

################################################################################
## DATA PROCESSING
################################################################################

##############################################################
# Global variables
##############################################################
sub split_clonaloriginxml ($$); 

split_clonaloriginxml ($xml, $out); 

sub split_clonaloriginxml ($$) {
  my ($xmlFile,$outBase) = @_;
  my $line;
  my $header = ""; 
  open XML, $xmlFile or die "$xmlFile could not be opened";
  
  my $iterationid = 0;
  while ($line = <XML>)
  {
    if ($line =~ /^<Iteration>/)
    {
      if ($iterationid > 0)
      {
        print OUTXML "</outputFile>\n";
        close OUTXML;
        if ($verbose == 1)
        {
          print STDERR "Iteration: $iterationid\r";
        }
      }
      $iterationid++; 
      my $outXmlFile = "$out.$iterationid";
      open OUTXML, ">$outXmlFile" or die "$xmlFile could not be opended";
      print OUTXML $header;
    }
    if ($iterationid > 0)
    {
      print OUTXML $line;
    }
    else
    {
      $header .= $line;
    }
  }
  close XML;
}

exit;
