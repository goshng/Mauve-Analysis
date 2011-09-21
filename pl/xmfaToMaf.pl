#!/opt/local/bin/perl -w
###############################################################################
# Copyright (C) 2011 Sang Chul Choi
#
# This file is part of Mauve Analysis.
# 
# Mauve Analysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mauve Analysis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mauve Analysis.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
use strict;
use warnings;
use XML::Parser;
use Getopt::Long;
use Pod::Usage;
require "pl/sub-simple-parser.pl";
require "pl/sub-newick-parser.pl";
require "pl/sub-array.pl";
require "pl/sub-xmfa.pl";

require "pl/sub-error.pl";
require "pl/sub-maf.pl";

$| = 1; # Do not buffer output
my $VERSION = 'xmfaToMaf.pl 1.0';

my $cmd = ""; 
sub process {
  my ($a) = @_; 
  $cmd = $a; 
}

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'xmfa=s',
            'xmfa2maf=s',
            'rename=s',
            'reorder=s',
            'out=s',
            '<>' => \&process
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################
my $outfile;

if (exists $params{out})
{
  open ($outfile, ">", $params{out}) or die "cannot open > $params{out} $!";
}
else
{
  $outfile = *STDOUT;   
}

if ($cmd eq 'ucsc')
{
  unless (exists $params{xmfa2maf})
  {
    &printError("Command $cmd requires option -xmfa2maf");
  }
}

################################################################################
## DATA PROCESSING
################################################################################
if ($cmd eq 'ucsc')
{
  my @countLineAlignment = peachMafCountFromMauveXmfa2Maf ($params{xmfa2maf});
  # print STDERR join ("\n", @countLineAlignment);
  # print STDERR scalar (@countLineAlignment);
  
  my @rename = split /,/, $params{rename};

  ############################################
  # Read the output file from Mauve's xmfa2maf
  open MAF, $params{xmfa2maf} or die "cannot open < $params{xmfa2maf} $!";
  my $line = <MAF>;
  print $outfile $line;
  print $outfile "\n";  # One blank line before the first alignment.
  for (my $i = 1; $i <= $#countLineAlignment; $i++)
  {
    for (my $j = 0; $j < $countLineAlignment[$i]; $j++)
    {
      $line = <MAF>;
      chomp $line;
      if ($j == 0)
      {
        die "The first character must be character a" unless $line =~ /^a/;
        print $outfile "$line\n";
      }
      elsif ($j == $countLineAlignment[$i] - 1)
      {
        die "The last line must be a blank" unless $line =~ /^$/;
        print $outfile "\n";
      }
      else
      {
        my @e = split /\s+/, $line;
        print $outfile "s\t$rename[$j-1]\t$e[2]\t$e[3]\t$e[4]\t$e[5]\t$e[6]\n";
      }
    }
  }
  close MAF;
}

if (exists $params{out})
{
  close $outfile;
}
__END__
=head1 NAME

xmfaToMaf.pl - convert an XMFA alignment to MAF-format alignment

=head1 VERSION

v1.0, Wed Sep 21 13:21:04 EDT 2011

=head1 SYNOPSIS

perl xmfaToMaf.pl ucsc -xmfa2maf file -rename s1,s2,s3 -reorder 3,1,2 -out file.out

=head1 DESCRIPTION

There may be other programs that can do the same thing: e.g., xmfa2maf in Mauve.
There are missing features that I need. 

commmand ucsc: Convert the output file from xmfa2maf to another XAF file that
can be loaded to UCSC genome browser using hgLoadMaf.
I first convert a xmfa file to maf using xmfa2maf. The maf file needs to be
edited so that it can be loaded to UCSC genome browser using hgLoadMaf. 
Line starts with `a' must be preceded by a single blank line. The xmfa2maf
output MAF file has the first sequence alignment does not have a blank line.
Species names in the MAF file can be replaced using -rename option. 
Sequences can be reordered using -reorder option.

See http://genome.ucsc.edu/FAQ/FAQformat.html#format5 for the MAF-format.

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

=item B<-xml> <file base name>

A base name for ClonalOrigin XML files
that contains the 2nd phase run result from Clonal Origin. A number of XML files
for blocks are produced by appending dot and a block ID.

  -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml

The XML file for block ID of 1 is

  -xml $RUNCLONALORIGIN/output2/${REPLICATE}/core_co.phase3.xml.1

=item B<-xmfa> <file base name>

A base name for xmfa formatted alignment blocks. Each block alignment is
produced by appending a dot and block ID.

  -xmfa $DATADIR/core_alignment.xmfa

A XMFA block alignment for block ID of 1 is

  -xmfa $DATADIR/core_alignment.xmfa.1

=item B<-refgenome> <number>

A reference genome ID. If no reference genome is given by users, I use only
blocks to compute maps.

=item B<-refgenomelength> <number>

The length of the reference genome. If refgenome is given, its length must be
given.

=item B<-numberblock> <number>

The number of blocks.

=item B<-out> <file>

If this is given, all of the output is written to the file. Otherwise, standard
output is used.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make xmfaToMaf.pl better.

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
