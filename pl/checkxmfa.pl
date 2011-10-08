# perl pl/checkxmfa.pl file.xmfa
# Check if an XMFA file has only A, C, G, and T.
my $isValid = 1;
my $line;
open XMFA, $ARGV[0] or die "cannot open $ARGV[0] $!"; 
while ($line = <XMFA>)
{
  if ($line =~ /^=/)
  {
    last;
  }
  else
  {
    die "Header of $ARGV[0] is invalid" unless $line =~ /^>/;
  }

  $line = <XMFA>;
  chomp $line;
  my @e = split //, $line;
  my %Seen; my @unique = grep { ! $Seen{$_}++ } @e;
  @sortedUnique = sort {$a cmp $b} @unique;

  if (scalar (@unique) == 4)
  {
    unless ($sortedUnique[0] eq 'A'
            and $sortedUnique[1] eq 'C'
            and $sortedUnique[2] eq 'G'
            and $sortedUnique[3] eq 'T')
    {
      $isValid = 0;
    }
  }
  else
  {
    $isValid = 0;
  }
}
close XMFA;

if ($isValid == 0)
{
  print "Invalid XMFA: $ARGV[0]\n";
}
