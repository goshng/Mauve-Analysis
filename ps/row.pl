open OUT, ">row.ps" or die "could not open row.ps";
drawRow();
close OUT;

sub drawRow ()
{
  my $height = 792;
  my $width = 612;
  my $numberRow = 9;
  my $upperMargin = 10;
  my $lowerMargin = 10;
  my $heightRow = (792 - $upperMargin - $lowerMargin) / $numberRow;
  my $xStart = 200;
  for (my $i = 0; $i < $numberRow; $i++)
  {
    my $yStart = $lowerMargin + int ($i * $heightRow);
    print OUT "newpath\n";
    print OUT "$xStart $yStart moveto\n"; 
    print OUT "$width $yStart lineto\n"; 
    print OUT "stroke\n"; 
  }
}
