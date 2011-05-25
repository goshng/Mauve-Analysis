open OUT, ">figure2.ps" or die "could not open figure2.ps";
for (my $i = 0; $i < 100; $i++)
{
  print OUT "newpath\n"; 
  print OUT "$i 0 moveto\n"; 
  print OUT "$i $i lineto\n"; 
  print OUT "stroke\n"; 
}
close OUT;
