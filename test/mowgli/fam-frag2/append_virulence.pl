# perl append_virulence.pl > append_virulence.txt

my %vir;
open VIR, "virulence.txt";
while (<VIR>)
{
  chomp;
  my @e = split /\t/;
  $vir{$e[0]} = $e[1];
}
close VIR;

open FAM, "famid-events.txt";
while (<FAM>)
{
  chomp;
  my @e = split /\t/;
  if (exists $vir{$e[0]})
  {
    print;
    print "\t$vir{$e[0]}\n";
  }
  else
  {
    print;
    print "\tFALSE\n";
  }
}
close FAM;

