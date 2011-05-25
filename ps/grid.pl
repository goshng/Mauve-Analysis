open OUT, ">grid.ps" or die "could not open grid.ps";
drawHorizontalGrid ();
drawVerticalGrid ();
close OUT;

sub drawHorizontalGrid ()
{
  for (my $i = 0; $i < 792; $i += 100)
  {
    print OUT "newpath\n";
    print OUT "0 $i moveto\n"; 
    print OUT "612 $i lineto\n"; 
    print OUT "stroke\n"; 
  }
}
sub drawVerticalGrid ()
{
  for (my $i = 0; $i < 612; $i += 100)
  {
    print OUT "newpath\n";
    print OUT "$i 0 moveto\n"; 
    print OUT "$i 792 lineto\n"; 
    print OUT "stroke\n"; 
  }
}
