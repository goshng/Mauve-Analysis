require "pl/sub-array.pl";

my @m1 = createSquareMatrix (3);
my @m2 = createSquareMatrix (3);

$m1[0][0] = 1;
$m1[2][1] = 1;

$m2[1][2] = 2;
$m2[0][2] = 3;

printSquareMatrix (\@m1, 3);
printSquareMatrix (\@m2, 3);
