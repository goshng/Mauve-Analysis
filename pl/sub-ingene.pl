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

sub maIngeneParse ($) {
  my ($ingene) = @_;
  my @genes;
  open INGENE, "$ingene" or die "cannot open < $ingene";
  while (<INGENE>)
  {
    chomp;
    my @e = split /\t/;
    my $rec = {};
    $rec->{gene} = $e[0]; 
    $rec->{start} = $e[1]; 
    $rec->{end} = $e[2]; 
    $rec->{strand} = $e[3]; 
    push @genes, $rec;
  }
  close INGENE;
  return @genes;
}

sub maIngenePrint ($$)
{
  my ($ingene, $genes) = @_;
  
  open INGENE, ">", $ingene or die "cannot open > $ingene";
  for (my $i = 0; $i < scalar @{ $genes }; $i++)
  {
    my $rec = $genes->[$i];
    print INGENE "$rec->{gene}\t";
    print INGENE "$rec->{start}\t";
    print INGENE "$rec->{end}\t";
    print INGENE "$rec->{strand}\n";
  }
  close INGENE;
}

sub maIngeneParseBlock ($) {
  my ($ingene) = @_;
  my $line;
  my @genes;
  open INGENE, "$ingene" or die "cannot open < $ingene";
  $line = <INGENE>;
  chomp $line;
  my @header = split /\t/, $line;
  
  while (<INGENE>)
  {
    chomp;
    my @e = split /\t/;
    my $g = {};
    for (my $i = 0; $i <= $#header; $i++)
    {
      $g->{$header[$i]} = $e[$i];
    }
    push @genes, $g;
  }
  close INGENE;
  return @genes;
}

sub maIngenePrintBlock ($$)
{
  my ($ingene, $genes) = @_;
  
  open INGENE, ">", $ingene or die "cannot open > $ingene";
  for (my $i = 0; $i < scalar @{ $genes }; $i++)
  {
    my $g = $genes->[$i];
    print INGENE "$g->{gene}\t";
    print INGENE "$g->{start}\t";
    print INGENE "$g->{end}\t";
    print INGENE "$g->{strand}\t";
    print INGENE "$g->{blockidGene}\t";
    print INGENE "$g->{blockStart}\t";
    print INGENE "$g->{blockEnd}\t";
    print INGENE "$g->{geneStartInBlock}\t";
    print INGENE "$g->{geneEndInBlock}\t";
    print INGENE "$g->{lenSeq}\t";
    print INGENE "$g->{gap}\n";
  }
  close INGENE;
}

sub maIngenePrintBlockRi ($$)
{
  my ($ingene, $genes) = @_;
  
  open INGENE, ">", $ingene or die "cannot open > $ingene";
  for (my $i = 0; $i < scalar @{ $genes }; $i++)
  {
    my $g = $genes->[$i];
    print INGENE "$g->{gene}\t";
    print INGENE "$g->{start}\t";
    print INGENE "$g->{end}\t";
    print INGENE "$g->{strand}\t";
    print INGENE "$g->{blockidGene}\t";
    print INGENE "$g->{blockStart}\t";
    print INGENE "$g->{blockEnd}\t";
    print INGENE "$g->{geneStartInBlock}\t";
    print INGENE "$g->{geneEndInBlock}\t";
    print INGENE "$g->{lenSeq}\t";
    print INGENE "$g->{gap}\t";
    print INGENE "$g->{ri}\n";
  }
  close INGENE;
}

sub parse_in_gene ($) {
  my ($ingene) = @_;
  my @genes;
  open INGENE, "$ingene" or die "$ingene could be not opened";
  while (<INGENE>)
  {
    chomp;
    my @e = split /\t/;
    my $rec = {};
    $rec->{gene} = $e[0]; 
    $rec->{start} = $e[1]; 
    $rec->{end} = $e[2]; 
    $rec->{strand} = $e[3]; 
    $rec->{block} = $e[4]; 
    $rec->{blockstart} = $e[5]; 
    $rec->{blockend} = $e[6]; 
    $rec->{genelength} = $e[7]; 
    $rec->{proportiongap} = $e[8]; 
    push @genes, $rec;
  }
  close INGENE;
  return @genes;
}

sub print_in_gene ($$)
{
  my ($ingene, $genes) = @_;
  
  open INGENE, ">$ingene.temp" or die "$ingene.temp could be not opened";
  for (my $i = 0; $i < scalar @{ $genes }; $i++)
  {
    my $rec = $genes->[$i];
    print INGENE "$rec->{gene}\t";
    print INGENE "$rec->{start}\t";
    print INGENE "$rec->{end}\t";
    print INGENE "$rec->{strand}\t";
    print INGENE "$rec->{block}\t";
    print INGENE "$rec->{blockstart}\t";
    print INGENE "$rec->{blockend}\t";
    print INGENE "$rec->{genelength}\t";
    print INGENE "$rec->{proportiongap}\t";
    print INGENE "$rec->{ri}\t";
    print INGENE "$rec->{ri2}\t";
    print INGENE "$rec->{ri3}\n";
  }
  close INGENE;
  rename "$ingene.temp", $ingene
}

1;
__END__
=head1 NAME

sub-ingene.pl - Procedures of ingene file parser

=head1 SYNOPSIS

  require "pl/sub-ingene.pl";
  my @genes = maIngeneParse ($ingenefilename); 
  maIngenePrint ($ingenefilename, \@genes);

=head1 VERSION

v1.0, Sun May 15 18:11:38 EDT 2011

=head1 DESCRIPTION

An ingene file contains rows, each of which is tab delimited items. Items can be
gene name, gene start and end position, and gene strand. An example is 

  pyM3_0743 796085  796765  +

=head1 FUNCTIONS

=over 4

=item sub maIngenePrintBlockRi ($$)

  Argument 1: File name of an ingene file
  Argument 2: Reference of an array of gene name, start position, end poisition, and its strand
  The array is printed out to the ingene file.

=item sub maIngeneParse ($)

  Argument 1: File name of an ingene file
  Return: an array of gene name, start position, end poisition, and its strand

=item sub maIngenePrint ($$)

  Argument 1: File name of an ingene file
  Argument 2: Reference of an array of gene name, start position, end poisition, and its strand
  The array is printed out to the ingene file.

=item sub maIngeneParseBlock ($)

  Argument 1: File name of an ingene block file
  Return: an array of values corresponding to each columns.

  The ingene file with block information contains the following columns:
  gene start end strand blockidGene blockStart blockEnd 
  geneStartInBlock geneEndInBlock lenSeq gap

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

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

