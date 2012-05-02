#!/usr/bin/perl

open IN, $ARGV[0];
my $l;
my $i = 0;
$l = <IN>;
my @a = split /:/, $l;
my $m = $a[1];
$l = <IN>;
my @a = split /:/, $l;
my $m1 = $a[1];
print sprintf("%d & %d & ", $m1, $m);
print "\n";
close IN;

sub get_three_parameter {
open IN, $ARGV[0];
my $l;
my $i = 0;
while ($l = <IN>) {
  $i++;
  my @a = split /:/, $l;
  my $m = $a[1];
  $l = <IN>;
  my @a = split /:/, $l;
  my $m1 = $a[1];
  $l = <IN>;
  my @a = split /:/, $l;
  my $m2 = $a[1];
  if ($i == 3) {
    print sprintf("%.3f (%.3f,%.3f) \\\\", $m, $m1, $m2);
  } else {
    print sprintf("%.3f (%.3f,%.3f) & ", $m, $m1, $m2);
  }
}
print "\n";
close IN;
}

sub get_tree {
open IN, $ARGV[0];
my $l = <IN>;
print $l;
my @a = split /[\(\)\:,]/, $l;
#for (my $i = 0; $i < @a; $i++) {
  #print $i," - ",$a[$i]," ";
#}
#print "\n";
# print "\ttree tree_1 = [&R] (((SDE1:$a[4],SDE2:$a[4])[&!rotate=true,label=\"SDE\"]\n";
print "\ttree tree_1 = [&R] (((SDE1:$a[4],SDE2:$a[4])[&!rotate=true,label=\"SDE\"]:$a[8],SDD:$a[10])[&!rotate=true,label=\"SD\"]:$a[12],(SPY1:$a[15],SPY2:$a[15])[&!rotate=true,label=\"SPY\"]:$a[19])[&!rotate=true,label=\"ROOT\"]\n";
close IN;
# (((1:0.045750,2:0.045750)6:0.194360,3:0.240110)8:0.082227,(4:0.076870,5:0.076870)7:0.245468)9:0.000000
}
