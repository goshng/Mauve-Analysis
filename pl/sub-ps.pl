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
sub maPsReadmap ($$$);

sub maPsReadmap ($$$)
{
  my ($rimap, $startBlock, $endBlock) = @_;
  ###############
  # Read map.
  ###############
  my @map;
  my $c = 0;
  my $line;
  open MAP, $rimap or die "cannot open < $rimap $!";
  if ($c < $startBlock)
  {
    while ($line = <MAP>)
    {
      $c++;
      last if $c == $startBlock;
    }
  }
  while ($line = <MAP>)
  {
    $c++;
    last if $c == $endBlock;
    chomp $line;
    my @e = split /\t/, $line;
    die "Error: negative values in the map" if $e[1] < 0;
    push @map, [ @e ];
  }
  close MAP;
  return \@map;
}

sub maPsDrawRiBlock ($$$$$$)
{
  my ($out, $rimap, $blockStart, $genes, $block, $clonaloriginsamplesize) = @_;
  my $lengthGenome = $blockStart->[$#$blockStart];
  my $numberLineage = 9; # FIXME: number of lineages

  # 0-base positions
  my $startBlock = $blockStart->[$block-1];
  my $endBlock = $blockStart->[$block];
  my $map = maPsReadmap ($rimap, $startBlock, $endBlock);

  ###############
  # Postscript.
  ###############
  my $height = 792;
  my $width = 612;
  my $numberRow = $numberLineage; # Number of lineages
  my $upperMargin = 60;
  my $lowerMargin = 200;
  my $rightMargin = 20;
  my $leftMargin = 20;
  my $heightRow = ($height - $upperMargin - $lowerMargin) / $numberRow;
  my $heightBar = int($heightRow * 0.5);
  my $tickBar = int($heightRow * 0.05);
  my $xStart = 100;
  my $xEnd = $width - $rightMargin;
  my $widthBar = $xEnd - $xStart + 1;
  my $tickInterval = 100;

  my $startPos = $map->[0][0];
  my $last = $#{$map};
  my $endPos = $map->[$last][0];
  my $binSize = int(($last+1) / $widthBar + 1);
  # Recompute the width of the bar and xEnd.
  $widthBar = -1;
  my $lenPos = $startPos;
  while ($lenPos <= $endPos)
  {
    $lenPos += $binSize;
    $widthBar++;
  }
  $xEnd = $xStart + $widthBar;
  # print STDERR "widthBar: $widthBar\n";
  # print STDERR "binSize: $binSize\n";

  # Start to write a postscript file.
  my $outfile = sprintf("$out-%04d-%08d.eps", $block, $startPos);
  open OUT, ">", $outfile or die "cannot open > $outfile $!";

  # Draw the location of the block.
  my $xGenome = $xStart;
  my $yGenome = $height - 30;
  my $yUpperBar = $yGenome + 5;
=cut
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
=cut

  # Write the position of the block
  my $locationBlock = "Block #$block";
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

  # FIXME: Colors
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

  # FIXME: Species
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
  my @destinationJOrder = reverse (0,5,1,7,2,8,3,6,4); # FIXME
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
  for (my $i = 0; $i <= $#$genes; $i++)
  {
    my $g = $genes->[$i];
    # print INGENE "$g->{blockidGene}\t";
    # print INGENE "$g->{blockStart}\t";
    # print INGENE "$g->{blockEnd}\t";
    my $gStart = $startBlock + $g->{blockStart} + 1; 
    my $gEnd = $startBlock + $g->{blockEnd} + 1; 
    if ($g->{blockidGene} == $block)
    {
      $numberGene++;
      if ($numberGene > 5)
      {
        $yGene = 10;
        $numberGene = 0;
      }
      $yGene += 15;
      my $xGene = $xStart + int(($gStart - $startPos) / ($endPos - $startPos) * ($widthBar));
      print OUT "newpath\n";
      print OUT "$xGene $yGene moveto\n"; 
      $yGene += 10;
      print OUT "$xGene $yGene lineto\n"; 
      print OUT "1 0 0 setrgbcolor\n";
      print OUT "stroke\n"; 

      print OUT "$xGene $yGene moveto ($g->{gene}) show\n";

      # End position of the gene
      $xGene = $xStart + int(($gEnd - $startPos) / ($endPos - $startPos) * ($widthBar));
      print OUT "newpath\n";
      print OUT "$xGene $yGene moveto\n"; 
      $yGene -= 10;
      print OUT "$xGene $yGene lineto\n"; 
      print OUT "0 0 1 setrgbcolor\n";
      print OUT "stroke\n"; 
      # print OUT "$xGene $yGene moveto ($rec->{gene}) show\n";
    }
  }

  # Draw recombination probability.
  @destinationJOrder = reverse (0,5,1,7,2,8,3,6,4); # FIXME
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
    # print STDERR ($j - $xStart), "\n";
    # Postscript - Ticks
    print OUT "newpath\n";
    print OUT "$xStart $yStart moveto\n"; 
    print OUT "$xEnd $yStart lineto\n"; 
    print OUT "0 0 0 setrgbcolor\n";
    print OUT "stroke\n"; 
=cut
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
=cut
  }
  close OUT;
}

1;
__END__
=head1 NAME

pl/sub-ps.pl - draw bacterial recombination along genome or block.

=head1 VERSION

v1.0, Sun Jul 17 13:53:33 EDT 2011

=head1 SYNOPSIS

  my $out = "rimap";
  my $rimap = "rimap.txt";
  my $xmfa = "core_alignment.xmfa";
  my $ingene = "ingene.4.block";
  my @blockStart =  maXmfaGetBlockStart ($xmfa);
  my @genes = maIngeneParseBlock ($ingene); 
  maPsDrawRiBlock ($out, $rimap, \@blockStart, \@genes, 254, 1000);
  # rimap-254.eps is created.

=head1 FUNCTIONS

=over 4

=item sub maPsDrawRiBlock $($$$$$)

  Argument 1: output file base name
  Argument 2: rimap file name
  Argument 3: block start positions in array reference
  Argument 4: ingene in array reference
  Argument 5: block ID
  Argument 6: sample size
  Return: [output file name]-[block ID].eps file is created. The file can be
  viewed using a graphic software.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message mauve-analysis project at codaset dot
com repository so that I can make recombination-intensity1-probability.pl better.

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
