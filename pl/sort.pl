
@stuff_list = (0.3, 0.1, 0.7, 0.5, 0.9, 0.2);
# @list_order = (  0,   1,   2,   3,   4,   5);
# @list_order = (0 .. 5);

@list_order = sort { $stuff_list[$b] cmp $stuff_list[$a] } 0 .. $#stuff_list;

for my $i ( 0 .. $#list_order ) {
    print "$list_order[$i]: $stuff_list[$list_order[$i]]\n";
}

@a = reverse (0 .. 10);
print join (" ", @a);
print "\n";
