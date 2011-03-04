#!/usr/bin/perl

#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: remove-blocks-from-core-alignment.pl
#   Date: 2011-02-11
#   Version: 0.1.0
#
#   Usage:
#      perl remove-blocks-from-core-alignment.pl [options]
#
#      Try 'perl remove-blocks-from-core-alignment.pl -h' for more information.
#
#   Purpose: remove-blocks-from-core-alignment.pl help you to remove alignments
#            from the core alignment file that is generated by stripSubsetLCBs.
#===============================================================================

use strict;
use warnings;

#use Data::Dumper;
use Getopt::Long;
use Pod::Usage;
use File::Temp qw(tempfile);

$| = 1; # Do not buffer output

my $VERSION = 'remove-blocks-from-core-alignment.pl 0.1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'fasta=s',
            'outfile=s',
            'blocks=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

remove-blocks-from-core-alignment.pl - Remove blocks from a core alignment.

=head1 VERSION

remove-blocks-from-core-alignment.pl 0.1.0

=head1 SYNOPSIS

perl remove-blocks-from-core-alignment.pl.pl [-h] [-help] [-version] [-blocks numbers] 

=head1 DESCRIPTION

remove-blocks-from-core-alignment.pl will help you to convert segemehl program's output mapping files to a
graph file that can be viewed using a genome viewer such as IGV, IGB, etc.

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-blocks> <number>,<number>,...

=item B<-fasta> <file>

Input file in FASTA format that contains the sequence data.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make remove-blocks-from-core-alignment.pl better.

=head1 COPYRIGHT

Copyright (C) 2011  Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

my $fastaFilename;
my $outFilename;
my @blocks;
my %hash;

if (exists $params{fasta})
{
  $fastaFilename = $params{fasta};
} else {
  &printError("you did not specify an input alignment file");
}

if (exists $params{blocks})
{
  @blocks = split /,/, $params{blocks};
  @hash{@blocks}=();
} else {
  &printError("you did not specify blocks that you want to remove from $fastaFilename");
}

if (exists $params{outfile})
{
  $outFilename = $params{outfile};
  if ($fastaFilename eq $outFilename)
  { 
    &printError("you did specify the output file name that is the same as the input file");
  }
} else {
  &printError("you did not specify an output file name");
}

open OUTFILE, ">$outFilename" or die "$!";
my $count = 1;
my $remove; 
if (exists $hash{$count})
{
  $remove = "yes";
}
else
{
  $remove = "no";
}

open FILE, $fastaFilename or die "$!";
while (<FILE>)
{
  if (/^=/)
  {
    $count++;
    if (exists $hash{$count})
    {
      $remove = "yes";
    }
    else
    {
      $remove = "no";
    }
  }

  if (/^#/)
  {
    print OUTFILE;
  }
  elsif ($remove eq "no")
  {
    print OUTFILE;
  }

}
close (FILE);
close (OUTFILE);
print $count, "\n";
exit;

#
################################################################################
## DATA PROCESSING
################################################################################
#

##
#################################################################################
### MISC FUNCTIONS
#################################################################################
##

sub printError {
    my $msg = shift;
    print STDERR "ERROR: ".$msg.".\n\nTry \'remove-blocks-from-core-alignment.pl -h\' for more information.\nExit program.\n";
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
