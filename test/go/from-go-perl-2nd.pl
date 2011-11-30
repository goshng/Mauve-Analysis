use strict;
# perl from-go-perl-2nd.pl go-list.txt.out SpyMGAS315_go_bacteria.txt

my $goListFilename = $ARGV[0];
my $geneGoFilename = $ARGV[1];

my %goInformational;
open GOLIST, $goListFilename or die "cannot open < $goListFilename $!";
while (<GOLIST>)
{
  chomp;
  my @e = split /\t/;
  $goInformational{$e[0]} = $e[1];
}
close GOLIST;

my %geneInformational;
my %geneGoCount;
open GENEGO, $geneGoFilename or die "cannot open < $geneGoFilename $!";
while (<GENEGO>)
{
  chomp;
  my @e = split /\t/;
  unless (exists $geneInformational{$e[0]})
  {
    $geneInformational{$e[0]} = 0;
  }
  unless (exists $geneGoCount{$e[0]})
  {
    $geneGoCount{$e[0]} = 0;
  }
  $geneGoCount{$e[0]}++;
  if ($e[2] < 0.00001)
  {
    if ($goInformational{$e[1]} == 1)
    {
      $geneInformational{$e[0]}++;
      # print "$e[0]\t1\n";
    }
    else
    {
      # print "$e[0]\t0\n";
    }
  }
}
close GENEGO;

foreach my $k (keys %geneInformational)
{
  my $f = sprintf("%.3f", $geneInformational{$k}/$geneGoCount{$k});
  print "$k\t$geneInformational{$k}\t$geneGoCount{$k}\t$f\n";
}
