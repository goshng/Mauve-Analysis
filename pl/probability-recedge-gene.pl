#!/opt/local/bin/perl -w
#===============================================================================
#   Author: Sang Chul Choi, BSCB @ Cornell University, NY
#
#   File: probability-recedge-gene.pl
#   Date: Wed Jun  8 15:37:24 EDT 2011
#   Version: 1.0
#===============================================================================
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'probability-recedge-gene.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help, 'man' => \$man);        
GetOptions( \%params,
            'help|h',
            'man',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'ri1map=s',
            'genbank=s',
            'clonaloriginsamplesize=i',
            'out=s',
            'latex'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

probability-recedge-gene.pl - Compute probability of recombination of genes

=head1 VERSION

v1.0, Sun May 15 16:25:25 EDT 2011

=head1 SYNOPSIS

perl probability-recedge-gene.pl [-h] [-help] [-version] [-verbose]
  [-ri1map file] 
  [-ingene file] 
  [-genbank file] 
  [-out file] 
  [-latex] 

=head1 DESCRIPTION

The number of recombination edge types at a nucleotide site along all of the
alignment blocks is computed for genes from an ingene file. 
Menu recombination-intensity1-map must be called first.

What we need includes:
1. recombination-intensity1-map file (-ri1map)
2. ingene file (-ingene)
3. out file (-out)

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

=item B<-ri1map> <file>

A recombination intensity 1 map file.

=item B<-genbank> <file>

A GenBank file.

=item B<-ingene> <file>

An ingene file.

=item B<-out> <file>

An output file.

=item B<-latex>

The output file in LaTeX.


=item B<-pairs> <string>

  -pairs 0,3:0,4:1,3:1,4:3,0:3,1:4,0:4,1

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make probability-recedge-gene.pl better.

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
sub getLengthMap ($);

require "pl/sub-ingene.pl";
require "pl/sub-error.pl";
require "pl/sub-array.pl";

# Delete these if not needed.
require "pl/sub-simple-parser.pl";
require "pl/sub-newick-parser.pl";
require "pl/sub-xmfa.pl";

################################################################################
## COMMANDLINE OPTION PROCESSING
################################################################################

my $ri1map;
my $ingene;
my $genbank;
my $out;
my $clonaloriginsamplesize;
my $pairs;
my $verbose = 0;
my $latex = 0;

if (exists $params{ri1map})
{
  $ri1map = $params{ri1map};
}
else
{
  &printError("you did not specify an ri1map file that contains recombination intensity 1 measure");
}

if (exists $params{out})
{
  $out = $params{out};
}
else
{
  &printError("you did not specify an output file");
}

if (exists $params{genbank})
{
  $genbank = $params{genbank};
}
else
{
  &printError("you did not specify a genbank file");
}

if (exists $params{clonaloriginsamplesize})
{
  $clonaloriginsamplesize = $params{clonaloriginsamplesize};
}
else
{
  &printError("you did not specify an clonaloriginsamplesize");
}

if (exists $params{verbose})
{
  $verbose = 1;
}

if (exists $params{latex})
{
  $latex = 1;
}

################################################################################
## DATA PROCESSING
################################################################################
my $itercount = 0;
my $blockLength;
my $blockidForProgress;
my $numberTaxa = 5;
my $numberLineage = 2 * $numberTaxa - 1;

################################################################################
# Find coordinates of the reference genome.
################################################################################
sub parse_genbank ($);
sub genbankOpen ($);
sub genbankNext ($);
sub genbankClose ($);
sub riOpen ($);
sub riCompute ($$$$);

if ($latex == 1)
{
  print "\\documentclass{article}\n\\begin{document}\n";
  print "\\begin{tabular}{ | l l l l l l l l l l | }\n";
  print "\\hline\n";
  print "Locus & srceI & destI & fragPortion & fragStart & fragEnd & coverage & gene start & gene end & gene product\\\\\n";
  print "\\hline\n";
}

my @notProcessedGene;
open (my $riFile, $ri1map) or die $!;
my $pos = 1;

my $genbankFile = genbankOpen ($genbank);
my %gene = genbankNext ($genbankFile);
while ($gene{locus} ne "")
{
  # print "$gene{locus}\t$gene{start}\t$gene{end}\t$gene{product}\n";
  if ($pos <= $gene{start})
  {
    # my ($srceI, $destI, $max, $coverage);
    # ($pos, $srceI, $destI, $max, $coverage) = riCompute ($riFile, $pos, $gene{start}, $gene{end});
    my ($coverage, $reTransfer);
    ($pos, $coverage, $reTransfer) = riCompute ($riFile, $pos, $gene{start}, $gene{end});
    for my $h (@{ $reTransfer })
    {
      my $index = $h->{index};
      my $srceI = int($index / 9);
      my $destI = $index % 9;
      my $fragStart = $h->{start};
      my $fragEnd = $h->{end};
      my $fragPortion = int(($fragEnd - $fragStart) / ($gene{end} - $gene{start}) * 100);
      if ($latex == 0)
      {
        print "$gene{locus}\t$srceI\t$destI\t$fragPortion\t$fragStart\t$fragEnd\t$coverage\t$gene{start}\t$gene{end}\t$gene{product}\n";
      }
      else
      {
        my $locusname = $gene{locus};
        $locusname =~ s/_/\\_/g; 
        print "$locusname & $srceI & $destI & $fragPortion & $fragStart & $fragEnd & $coverage & $gene{start} & $gene{end} & $gene{product} \\\\\n";
      }
    }
  }
  else
  {
    # Genes that already started.
    # Compute posterior probability for these genes later.
    # print STDERR "NOT PROCESSED $gene{locus}\t$gene{start}\t$gene{end}\t$gene{product}\n";
    push @notProcessedGene, { %gene };
  }
  %gene = genbankNext ($genbankFile);
}
close ($genbankFile);
close ($riFile);

#################################################
# Compute posterior probability for the unprocessed genes. 
open ($riFile, $ri1map) or die $!;
$pos = 1;
for my $g ( @notProcessedGene ) {
  my ($coverage, $reTransfer);
  ($pos, $coverage, $reTransfer) = riCompute ($riFile, $pos, $g->{start}, $g->{end});
  for my $h (@{ $reTransfer })
  {
    my $index = $h->{index};
    my $srceI = int($index / 9);
    my $destI = $index % 9;
    my $fragStart = $h->{start};
    my $fragEnd = $h->{end};
    my $fragPortion = int(($fragEnd - $fragStart) / ($g->{end} - $g->{start}) * 100);
    if ($latex == 0)
    {
      print "$g->{locus}\t$srceI\t$destI\t$fragPortion\t$fragStart\t$fragEnd\t$coverage\t$g->{start}\t$g->{end}\t$g->{product}\n";
    }
    else
    {
      my $locusname = $g->{locus};
      $locusname =~ s/_/\\_/g; 
      print "$locusname & $srceI & $destI & $fragPortion & $fragStart & $fragEnd & $coverage & $g->{start} & $g->{end} & $g->{product}\\\\\n";
    }
  }
}
close ($riFile);

if ($latex == 1)
{
  print "\\end{tabular}\n";
  print "\\end{document}\n";
}

my $lengthGenome = 0;
my @genes;

exit;

################################################################################
## END OF DATA PROCESSING
################################################################################

################################################################################
## FUNCTION DEFINITION
################################################################################
sub riCompute ($$$$)
{
  my ($f, $pos, $start, $end) = @_;
  my $threshould = 0.9 * $clonaloriginsamplesize;
  my @reTransfer;
  my $line;

  die "$pos is greater than $start" if $pos > $start;
  while ($pos < $start)
  {
    $line = <$f>;
    $pos++;
  }

  my @m = (0) x 81;
  my $numberOfSitesOfNonzero = 0;
  while ($pos <= $end)
  {
    $line = <$f>;
    my @e = split /\t/, $line;
    if ($e[1] < 0)
    {
      # no map.
    }
    else
    {
      $numberOfSitesOfNonzero++; 
      for (my $i = 0; $i < 72; $i++)
      {
        die "negative values $pos $i" if $e[$i+1] < 0;
        $m[$i] += $e[$i+1];
        if ($e[$i+1] > $threshould)
        {
          my $found = 0;
          for my $h (@reTransfer) 
          {
            if ($h->{index} == $i and $h->{end} == $pos - 1)
            {
              $h->{end} = $pos;
              $found = 1;
              last;
            }
          }
          if ($found == 0)
          {
            my $rec = {};
            $rec->{index} = $i;
            $rec->{start} = $pos;
            $rec->{end} = $pos;
            push @reTransfer, $rec;
          }
        }
      }
    }
    die "Incorrect position" unless $e[0] == $pos;
    $pos++;
  }

  my $coverage = int($numberOfSitesOfNonzero / ($end - $start + 1) * 100);

  my $srceI = -1;
  my $destI = -1;
  my $max = -1;

  if ($numberOfSitesOfNonzero > 0)
  {
    for (my $i = 0; $i < 81; $i++)
    {
      $m[$i] /= ($numberOfSitesOfNonzero * $clonaloriginsamplesize);
    }

    # Find the max and its index.
    my $maxIndex;
    for (my $i = 0; $i < 81; $i++)
    {
      if ($m[$i] > $max)
      {
        $max = $m[$i];
        $maxIndex = $i;
      }
    }
    $srceI = int($maxIndex / 9);
    $destI = $maxIndex % 9;

  }
  else
  {
    # No map.
  }

  return ($pos, $coverage, \@reTransfer);
}

sub genbankOpen ($)
{
  my ($f) = @_;
  open GENBANK, $f or die "Could not open $f $!";
  return \*GENBANK;
}

sub genbankNext ($)
{
  my ($f) = @_;
  my %gene;
  $gene{locus} = "";

  my $foundGene = 0;
  my $foundLocus = 0;
  my $foundPosition = 0;
  while (my $line = <$f>)
  {
    chomp $line;
    if ($line =~ /^\s+gene\s+/)
    {
      $foundGene = 1;
    }
    if ($foundGene == 1)
    {
      if ($line =~ /^\s+\/locus_tag=\"(\w+)\"/)
      {
        $gene{locus} = $1;
        $foundLocus = 1;
      }
    }

    if ($foundLocus == 1)
    {
      if ($line =~ /^\s+CDS\s+/
          or $line =~ /^\s+rRNA\s+/
          or $line =~ /^\s+tRNA\s+/)
      {
        if ($line =~ /(\d+)\.\.(\d+)/)
        {
          $gene{start} = $1;
          $gene{end} = $2;
          $foundPosition = 1;
        }
      }
    }

    if ($foundPosition == 1)
    {
      if ($line =~ /^\s+\/product=\"/)
      {
        my $product = "";
        if ($line =~ /\"(.+)\"/)
        {
          $product = $1;
        }
        elsif ($line =~ /\"(.+)/)
        {
          $product = $1;
          $line = <$f>;
          while ($line !~ /^\s+\//)
          {
            chomp $line;
            $product .= $line;
            $line = <$f>;
          }
          $product =~ s/\s+/ /g;
          $product =~ s/\"//g;
        }
        $gene{product} = $product;
        last;
      }
    }

  }
  return %gene;
}

sub genbankClose ($)
{
  my ($f) = @_;
  close $f;
}

sub parse_genbank ($)
{
  my ($f) = @_;
  open GENBANK, $f or die "Could not open $f $!";
  while (<GENBANK>)
  {
    
  }
  close GENBANK;
}

sub getPairs ($)
{
  my ($s) = @_;
  my @v;

  my @e = split /:/, $s;
  for my $element (@e)
  {
    push @v, [ split /,/, $element ]; 
  }
  return @v;
}

sub drawRI1BlockGenes ($$)
{
  my ($genes, $ri1map) = @_;

  my @map;
  my $line;
  my $status = "nomap";
  open MAP, $ri1map or die "could not open $ri1map";
  while ($line = <MAP>)
  {
    chomp $line;
    my @e = split /\t/, $line;
    if ($status eq "nomap")
    {
      if ($e[1] < 0)
      {
        next;
      }
      else
      {
        @map = ();
        $status = "map";
      }
    }
    else
    {
      if ($e[1] < 0)
      {
        $status = "nomap";
        # Generate the figure for the map.
        drawRI1Block (\@map, $ingene, $out);
        #last;
        next;
      }
      else
      {
        push @map, [ @e ];
      }
    }
  }
  close MAP;
}

sub drawRI1Block ($$$)
{
  my ($map, $ingene, $out) = @_;

  ###############
  # Postscript.
  ###############
  my $height = 792;
  my $width = 612;
  my $numberRow = 9;
  my $upperMargin = 60;
  my $lowerMargin = 200;
  my $rightMargin = 20;
  my $leftMargin = 20;
  my $heightRow = (792 - $upperMargin - $lowerMargin) / $numberRow;
  my $heightBar = int($heightRow * 0.5);
  my $tickBar = int($heightRow * 0.05);
  my $xStart = 100;
  my $tickInterval = 100;

  my $startPos = $map->[0][0];
  my $last = $#{$map};
  my $endPos = $map->[$last][0];
  my $binSize = int(($last + 1) / $width + 1);

  # Start to write a postscript file.
  my $outfile = sprintf("$out-%08d.ps", $startPos);
  open OUT, ">$outfile" or die "could not open $outfile $!";

  # Draw the location of the block.
  my $xGenome = $xStart;
  my $yGenome = $height - 30;
  my $xEndGenome = $width - $rightMargin;
  print OUT "newpath\n";
  print OUT "$xGenome $yGenome moveto\n"; 
  print OUT "$xEndGenome $yGenome lineto\n"; 
  print OUT "0 0 0 setrgbcolor\n";
  print OUT "stroke\n"; 
  # Left-end Bar
  my $yUpperBar = $yGenome + 5;
  print OUT "newpath\n";
  print OUT "$xGenome $yGenome moveto\n"; 
  print OUT "$xGenome $yUpperBar lineto\n"; 
  $yUpperBar = $yGenome - 5;
  print OUT "$xGenome $yUpperBar lineto\n"; 
  print OUT "0 0 0 setrgbcolor\n";
  print OUT "stroke\n"; 
  # Right-end Bar
  $yUpperBar = $yGenome + 5;
  print OUT "newpath\n";
  print OUT "$xEndGenome $yGenome moveto\n"; 
  print OUT "$xEndGenome $yUpperBar lineto\n"; 
  $yUpperBar = $yGenome - 5;
  print OUT "$xEndGenome $yUpperBar lineto\n"; 
  print OUT "0 0 0 setrgbcolor\n";
  print OUT "stroke\n"; 
  # Block
  my $lengthGenomeBar = $xEndGenome - $xGenome;
  my $xBlockBar = $startPos/$lengthGenome*$lengthGenomeBar;
  my $xBlock;
  if ($xBlockBar < 1)
  {
    $xBlock = $xGenome + 1;
  }
  else
  {
    $xBlock = int($xGenome + $startPos/$lengthGenome*$lengthGenomeBar);
  }
  my $xEndBlock = int($xGenome + $endPos/$lengthGenome*$lengthGenomeBar);
  $yUpperBar = $yGenome + 5;
  print OUT "newpath\n";
  print OUT "$xBlock $yGenome moveto\n"; 
  print OUT "$xBlock $yUpperBar lineto\n"; 
  $yUpperBar = $yGenome - 5;
  print OUT "$xBlock $yUpperBar lineto\n"; 
  print OUT "1 0 0 setrgbcolor\n";
  print OUT "stroke\n"; 

  # Write the position of the block
  my $locationBlock = "chr1:$startPos-$endPos";
  $yUpperBar = $yGenome + 10;
  print OUT "/Times-Roman findfont 15 scalefont setfont\n";
  print OUT "0 0 0 setrgbcolor\n";
  print OUT "$xGenome $yUpperBar moveto ($locationBlock) show\n";

  # Draw a scale bar
  my $xScalebar = $xStart;
  my $yScalebar = $height - 60;
  print OUT "newpath\n";
  print OUT "$xScalebar $yScalebar moveto\n"; 
  $xScalebar += $tickInterval; 
  print OUT "$xScalebar $yScalebar lineto\n"; 
  print OUT "0 0 0 setrgbcolor\n";
  print OUT "stroke\n"; 
  # Write the scale in base pairs
  my $scaleSize = sprintf ("%d bp", $binSize * $tickInterval);
  print OUT "/Times-Roman findfont 15 scalefont setfont\n";
  print OUT "0 0 0 setrgbcolor\n";
  $yScalebar -= 5;
  $xScalebar += 5;
  print OUT "$xScalebar $yScalebar moveto ($scaleSize) show\n";

  # Colors
  my @setrgbcolors;
  push @setrgbcolors, "0 0 1 setrgbcolor\n";          # Blue
  push @setrgbcolors, "0 1 1 setrgbcolor\n";          # Aqua
  push @setrgbcolors, "0 1 0 setrgbcolor\n";          # Green
  push @setrgbcolors, "1 0 0 setrgbcolor\n";          # Red
  push @setrgbcolors, "1 0.65 0 setrgbcolor\n";       # Orange
  push @setrgbcolors, "0 0 0 setrgbcolor\n";          # Black
  push @setrgbcolors, "0.65 0.16 0.16 setrgbcolor\n"; # Brown
  push @setrgbcolors, "1 1 0 setrgbcolor\n";          # Yellow
  push @setrgbcolors, "0.93 0.51 0.93 setrgbcolor\n"; # Violet

  # Species
  my @speciesNames;
  push @speciesNames, "SDE1";
  push @speciesNames, "SDE2";
  push @speciesNames, "SDD";
  push @speciesNames, "SPY1";
  push @speciesNames, "SPY2";
  push @speciesNames, "SDE";
  push @speciesNames, "SPY";
  push @speciesNames, "SD";
  push @speciesNames, "ROOT";

  # Draw boxes for each species
  my @destinationJOrder = reverse (0,5,1,7,2,8,3,6,4);
  for (my $destinationJIndex = 0; $destinationJIndex < $numberLineage; $destinationJIndex++)
  {
    my $destinationJ = $destinationJOrder[$destinationJIndex];
    my $i = $destinationJIndex;
    my $yStart = $lowerMargin + int ($i * $heightRow);
  
    my $order = $destinationJOrder[$destinationJIndex] + 1;
    print OUT $setrgbcolors[$order-1];

    print OUT "newpath\n";
    print OUT "70 $yStart moveto\n";
    print OUT "10 0 rlineto\n";
    print OUT "0 10 rlineto\n"; 
    print OUT "-10 0 rlineto\n";
    print OUT "closepath fill\n";
    print OUT "stroke\n";
    print OUT "0 0 0 setrgbcolor\n";       # Orange
    print OUT "20 $yStart moveto ($speciesNames[$order-1]) show\n";
  }

  # Draw genes.
  my $yGene = 10;
  my $numberGene = 0;
  for (my $i = 0; $i < scalar @genes; $i++)
  {
    my $rec = $genes[$i];
    if ($startPos < $rec->{start} and $rec->{start} < $endPos)
    {
      $numberGene++;
      if ($numberGene > 5)
      {
        $yGene = 10;
        $numberGene = 0;
      }
      $yGene += 15;
      my $xGene = $xStart + int(($rec->{start} - $startPos) / ($endPos - $startPos) * ($width - $xStart));
      print OUT "newpath\n";
      print OUT "$xGene $yGene moveto\n"; 
      $yGene += 10;
      print OUT "$xGene $yGene lineto\n"; 
      print OUT "1 0 0 setrgbcolor\n";
      print OUT "stroke\n"; 

      print OUT "$xGene $yGene moveto ($rec->{gene}) show\n";
    }
    if ($startPos < $rec->{end} and $rec->{end} < $endPos)
    {
      if ($startPos < $rec->{start} and $rec->{start} < $endPos)
      {
        $yGene -= 10;
      } 
      else
      {
        $numberGene++;
        if ($numberGene > 5)
        {
          $yGene = 10;
          $numberGene = 0;
        }
      }
      my $xGene = $xStart + int(($rec->{end} - $startPos) / ($endPos - $startPos) * ($width - $xStart));
      print OUT "newpath\n";
      print OUT "$xGene $yGene moveto\n"; 
      $yGene += 10;
      print OUT "$xGene $yGene lineto\n"; 
      print OUT "0 0 1 setrgbcolor\n";
      print OUT "stroke\n"; 
      if ($startPos < $rec->{start} and $rec->{start} < $endPos)
      {
        # No code.
      }
      else
      {
        print OUT "$xGene $yGene moveto ($rec->{gene}) show\n";
      }
    }
    if ($rec->{start} < $startPos and $endPos < $rec->{start})
    {
      my $xGene = $xStart; 
      print OUT "$xGene 10 moveto ($rec->{gene}) show\n";
    }

  }

  # Draw recombination probability.
  @destinationJOrder = reverse (0,5,1,7,2,8,3,6,4);
  for (my $destinationJIndex = 0; $destinationJIndex < $numberLineage; $destinationJIndex++)
  {
    my $destinationJ = $destinationJOrder[$destinationJIndex];
    # my $destinationJ = $destinationJIndex;
    # Postscript.
    my $i = $destinationJIndex;
    my $yStart = $lowerMargin + int ($i * $heightRow);

    my @prob = (0) x $numberLineage;  
    my $binIndex = 0;
    my $j = $xStart;
    for (my $p = 0; $p <= $last; $p++)
    {
      unless ($binIndex < $binSize)
      {
        # Postscript.
        my @sortedOrder = sort { $prob[$b] cmp $prob[$a] } 0 .. $#prob;
        for my $k (1..$numberLineage) 
        {
          my $order = $sortedOrder[$k-1] + 1;
          my $barY = $yStart + int($prob[$order-1] * $heightBar);
          print OUT "newpath\n";
          print OUT "$j $yStart moveto\n";
          print OUT "$j $barY lineto\n";

          print OUT $setrgbcolors[$order-1];
          if ($order > 9) {
            die "No more than 9 colors are available";
            print OUT "1 0 1 setrgbcolor\n"; # Magenta
          } 
          print OUT "stroke\n"; 
        }

        $j++;
        @prob = (0) x $numberLineage;  
        $binIndex = 0;
      }

      for (my $sourceI = 0; $sourceI < $numberLineage; $sourceI++)
      {
        my $v = $map->[$p][1 + $sourceI * $numberLineage + $destinationJ];
        die "Negative means no alignemnt in $p" if $v < 0;
        $prob[$sourceI] += ($v / ($clonaloriginsamplesize * $binSize));
      }
      $binIndex++;
    }
    # Postscript. 
    print OUT "newpath\n";
    print OUT "$xStart $yStart moveto\n"; 
    print OUT "$width $yStart lineto\n"; 
    print OUT "0 0 0 setrgbcolor\n";
    print OUT "stroke\n"; 
    my $tickIndex = 0;
    for (my $j = $xStart; $j < $width - $tickInterval; $j+=$tickInterval)
    {
      my $yTick = $yStart - $tickBar;
      my $yPos = $yStart - $tickBar - 15;
      print OUT "newpath\n";
      print OUT "$j $yStart moveto\n"; 
      print OUT "$j $yTick lineto\n"; 
      print OUT "0 0 0 setrgbcolor\n";
      print OUT "stroke\n"; 
      my $xLabel = $startPos + $tickIndex * $binSize * $tickInterval;
      print OUT "$j $yPos moveto ($xLabel) show\n";
      $tickIndex++;
    }
  }
  close OUT;
}

