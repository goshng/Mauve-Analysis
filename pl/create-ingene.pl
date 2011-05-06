#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: create-ingene.pl
#   Date: Thu May  5 15:38:42 EDT 2011
#   Version: 1.0
#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'create-ingene.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'genelength=i',
            'genomelength=i'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

create-ingene.pl - Creates a test ingene file.

=head1 VERSION

create-ingene.pl 1.0

=head1 SYNOPSIS

perl create-ingene.pl 
  [-h] [-help] [-version] 
  [-genelength number] 
  [-genomelength number] 

=head1 DESCRIPTION

An ingene file is tab-delimited with columns
1. geneid
2. start (1 indexed)
3. end (inclusive)
4. strand (1 -1)

A genome is equally divided into chunks of genes.

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

=item B<-genelength> <number>

The length of genes.

=item B<-genomelength> <number>

The length of a genome.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make create-ingene.pl better.

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

#
################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
#

my $genelength = 1000;
my $genomelength = 1000000;
my $verbose = 0;
if (exists $params{genelength})
{
  $genelength = $params{genelength};
}

if (exists $params{genomelength})
{
  $genomelength = $params{genomelength};
}

if (exists $params{verbose})
{
  $verbose = 1;
}

#
################################################################################
## DATA PROCESSING
################################################################################
#

my $geneid = 1;
for (my $pos = 1; $pos <= $genomelength; $pos += $genelength)
{
  my $endpos = $pos + $genelength - 1;
  print "$geneid\t$pos\t$endpos\t+\n";
  $geneid++; 
}

##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'create-ingene.pl -h\' for more information.\nExit program.\n";
    exit(0);
}

