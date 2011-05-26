open OUT, ">tick.ps" or die "could not open tick.ps";
drawTick();
close OUT;

sub drawTick()
{
  my $height = 792;
  my $width = 612;
  my $numberRow = 9;
  my $upperMargin = 25;
  my $lowerMargin = 25;
  my $rightMargin = 20;
  my $endLine = $width - $rightMargin;
  my $heightRow = (792 - $upperMargin - $lowerMargin) / $numberRow;
  my $heightBar = int($heightRow * 0.9);
  my $tickBar = int($heightRow * 0.05);
  my $xStart = 100;
  print OUT "/Times-Roman findfont 15 scalefont setfont\n";
  for (my $i = 0; $i < $numberRow; $i++)
  {
    my $yStart = $lowerMargin + int ($i * $heightRow);
    print OUT "newpath\n";
    print OUT "$xStart $yStart moveto\n"; 
    print OUT "$endLine $yStart lineto\n"; 
    print OUT "stroke\n"; 

    for (my $j = $xStart; $j < $width - $rightMargin; $j += 100)
    {
      my $yTick = $yStart - $tickBar;
      my $yPos = $yStart - $tickBar - 15;
      print OUT "newpath\n";
      print OUT "$j $yStart moveto\n"; 
      print OUT "$j $yTick lineto\n"; 
      print OUT "stroke\n"; 
      print OUT "$j $yPos moveto ($j) show\n";

=cut
      print OUT "newpath\n";
      print OUT "$j $yPos moveto\n"; 
      $yPos += 15;
      print OUT "$j $yPos lineto\n"; 
      my $xPos = $j + 15 * 3;
      print OUT "$xPos $yPos lineto\n"; 
      $yPos -= 15;
      print OUT "$xPos $yPos lineto\n"; 
      print OUT "$j $yPos lineto\n"; 
      print OUT "stroke\n"; 
=cut
    }
  }
  print OUT "showpage\n";
}
