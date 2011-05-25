open OUT, ">colorbars.ps" or die "could not open colorbars.ps";
drawColorBars();
close OUT;

sub drawColorBars ()
{
  my $height = 792;
  my $width = 612;
  my $numberRow = 9;
  my $upperMargin = 10;
  my $lowerMargin = 10;
  my $heightRow = (792 - $upperMargin - $lowerMargin) / $numberRow;
  my $heightBar = int($heightRow * 0.9);
  my $tickBar = int($heightRow * 0.05);
  my $xStart = 100;
  for (my $i = 0; $i < $numberRow; $i++)
  {
    my $yStart = $lowerMargin + int ($i * $heightRow);
  
    for (my $j = $xStart; $j < $width; $j++)
    {
      my @values;
      for my $k (1..3) 
      {
        push @values, rand();
      }
      my @sortedValues = sort { $b <=> $a } @values; # descending order

      for my $k (1..3) 
      {
        my $barY = $yStart + int($sortedValues[$k-1] * $heightBar);
        print OUT "newpath\n";
        print OUT "$j $yStart moveto\n";
        print OUT "$j $barY lineto\n";
        if ($k == 1) {
          print OUT "1 0 0 setrgbcolor\n";
        } elsif ($k == 2) {
          print OUT "0 1 0 setrgbcolor\n";
        } elsif ($k == 3) {
          print OUT "0 0 1 setrgbcolor\n";
        } 
        print OUT "stroke\n"; 
      }
    }

    print OUT "newpath\n";
    print OUT "$xStart $yStart moveto\n"; 
    print OUT "$width $yStart lineto\n"; 
    print OUT "0 0 0 setrgbcolor\n";
    print OUT "stroke\n"; 
    for (my $j = $xStart; $j < $width; $j+=50)
    {
      my $yTick = $yStart - $tickBar;
      print OUT "newpath\n";
      print OUT "$j $yStart moveto\n"; 
      print OUT "$j $yTick lineto\n"; 
      print OUT "0 0 0 setrgbcolor\n";
      print OUT "stroke\n"; 
    }
  }
  print OUT "showpage\n";
}
