open OUT, ">rowbars.ps" or die "could not open rowbars.ps";
drawRowBars();
close OUT;

sub drawRowBars ()
{
  my $height = 792;
  my $width = 612;
  my $numberRow = 9;
  my $upperMargin = 10;
  my $lowerMargin = 10;
  my $heightRow = (792 - $upperMargin - $lowerMargin) / $numberRow;
  my $heightBar = int($heightRow * 0.9);
  my $xStart = 100;
  for (my $i = 0; $i < $numberRow; $i++)
  {
    my $yStart = $lowerMargin + int ($i * $heightRow);
    print OUT "newpath\n";
    print OUT "$xStart $yStart moveto\n"; 
    print OUT "$width $yStart lineto\n"; 
    print OUT "stroke\n"; 
   
    for (my $j = $xStart; $j < $width; $j++)
    {
      my $barY = $yStart + int(rand() * $heightBar);
      print OUT "newpath\n";
      print OUT "$j $yStart moveto\n";
      print OUT "$j $barY lineto\n";
      print OUT "stroke\n"; 
    }
  }
}
