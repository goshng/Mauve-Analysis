# perl copy.pl srcdir destdir s1.diff
# perl copy.pl s1 /Volumes/Elements/Documents/Projects/mauve/output s1.diff
my $srcdir = $ARGV[0];
my $destdir = $ARGV[1];
my $difffile = $ARGV[2];

# print "$srcdir\t$destdir\t$difffile\n";
open IN, "$difffile" or die "cannot open < $difffile $!";
while (<IN>)
{
  if (/^Only in $srcdir/)
  {
    my @e = split /\s+/;
    my $f = $e[2];
    my $s = $e[3];
    my @e = split /:/, $f;
    $f = $e[0];
    system("cp -pr $f/$s $destdir/$f");
  }
}
close IN;


=comment
Only in s1/1/data: in1.block
Only in s1/1/data: s1_1_core_alignment.xmfa
Only in s1/1/data: s1_1_core_alignment.xml
=comment
