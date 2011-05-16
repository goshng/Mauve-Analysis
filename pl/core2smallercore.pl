#!/usr/bin/perl -w 
# Sang Chul modified blocksplit to suit his needs.
# 1. Count blocks to find how many blocks we have.
# 2. Randomly choose some of them.
# 3. Generate the output.
# Usage: [command] <filename> <fraction> <seed>
# <fraction> must be a real number between 0 and 1.
# e.g.,
#  perl $HOME/usr/bin/core2smallercore.pl \
#    $RUNLCBDIR/core_alignment.xmfa 0.1 12345
use strict;
use File::Basename;

my $fname = $ARGV[0];
my $fraction = $ARGV[1];
my $seed = $ARGV[2];

die "perl $0 <fname> <fraction> <seed> $#ARGV"
  unless $#ARGV == 2;

sub count_blocks ($);
sub selection_sample ($$);
sub exist_number_array ($$);

srand $seed;
my $nBlocks = count_blocks ($fname);
my $nSample = int($nBlocks*$fraction);
my @a;
for (my $i = 1; $i <= $nBlocks; $i++)
{
  push @a, $i;
}

my $b = selection_sample (\@a, $nSample); 
my $base_fname = basename($fname);
my $dir_fname = dirname($fname);
my $smallerfname = "$dir_fname/smaller$base_fname";

open (SMALLERFILE, ">$smallerfname");
open(INFILE, "$fname") || die "Unable to open input XMFA file $fname\n";
my $i = 1;
while( my $line = <INFILE> )
{
  my $keep_outfile = exist_number_array ($b, $i);
  if ($line =~ /^#/ or $keep_outfile == 1)
  {
    print SMALLERFILE $line;
  }

  if($line =~ /=/)
  {
    $i++;
  }
}
# last output file is extra
close SMALLERFILE;

###########################################################
# Count blocks.
###########################################################
sub count_blocks ($)
{
  my ($fname) = @_;
  my $c = 0;
  open(INFILE, "$fname") || die "Unable to open input XMFA file $fname\n";
  while( my $line = <INFILE> )
  {
    $c++ if $line =~ /^=/; 
  }
  close INFILE;
  return $c;
}

###########################################################
# Sample random values of size num in an array.
###########################################################
sub selection_sample ($$) {
    my ($array,$num)=@_;
    die "Too few elements (".scalar(@$array).") to select $num from\n"
        unless $num<=@$array;
    my @result;
    my $pos=0;
    while (@result<$num) {
        $pos++ while (rand(@$array-$pos)>($num-@result));
        push @result,$array->[$pos++];
    }
    return \@result;
}

###########################################################
# Check if a number exists in an array.
###########################################################
sub exist_number_array ($$)
{
  my ($array, $num) = @_;
  my $v = 0;
  foreach (@$array)
  {
    if ($num == $_)
    {
      $v = 1;
      last;
    }
  }
  return $v;
}
