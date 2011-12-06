# perl pl/snippet-wig-divide-sample-size.pl samplesize infile.wig outfile
# perl pl/snippet-wig-divide-sample-size.pl 1001 output/cornellf/3/run-analysis/recombprobwig-1/1/0-1 1
my $s = $ARGV[0];
my $infile = $ARGV[1];
my $outfile = $ARGV[2];
print $s, "\n";
print $infile, "\n";
print $outfile, "\n";
open IN, $infile or die "cannot open $infile $!";
open OUT, ">", $outfile or die "cannot open $outfule $!";
my $l = <IN>;
print OUT $l;
$l = <IN>;
print OUT $l;
while (<IN>)
{
  chomp;
  my $v = $_ / $s;
  print OUT $v, "\n";
}
close OUT;
close IN;
