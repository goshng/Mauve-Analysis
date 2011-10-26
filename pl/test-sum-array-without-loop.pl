my @arr1 = ( 2, 0, 2, 0, 1 );
my @arr2 = ( 3, 3, 0, 3, -2 );

my @for_loop;
for my $i ( 0..$#arr1 ) { 
    push @for_loop, $arr1[$i] + $arr2[$i];
}

my @map_array = map { $arr1[$_] + $arr2[$_] } 0..$#arr1;

print "Sum of\n";
print (join (" ", @arr1)); print "\n";
print "and\n";
print (join (" ", @arr2)); print "\n";
print "is\n";
print (join (" ", @map_array)); print "\n";

print "The first array is reused:\n";
@arr1 = map { $arr1[$_] + $arr2[$_] } 0..$#arr1;
print (join (" ", @arr1)); print "\n";

print "Divide all elements by 10:\n";
@arr1 = map { $arr1[$_] / 10  } 0..$#arr1;
print (join (" ", @arr1)); print "\n";

print "Test of if :\n";
@arr1 = map { if ($arr1[$_] > 0.1) {$arr1[$_] + 1} else {$arr1[$_]} } 0..$#arr1;
print (join (" ", @arr1)); print "\n";
