require "pl/sub-simple-parser.pl";

my $f = "output/cornell5/1/run-clonalorigin/output/1/core_co.phase2.1.xml";
my $l = get_block_length("output/cornell5/1/run-clonalorigin/output/1/core_co.phase2.1.xml");
my $s = get_sample_size("output/cornell5/1/run-clonalorigin/output/1/core_co.phase2.1.xml");

print "XML File: $f\n";
print "  Length: $l\n";
print "  Sample: $s\n";
