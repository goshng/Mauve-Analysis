###############################################################################
# Copyright (C) 2011 Sang Chul Choi
#
# This file is part of Mauve Analysis.
# 
# Mauve Analysis is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Mauve Analysis is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Mauve Analysis.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################
use strict;

# Date  : Wed Apr 27 13:24:04 EDT 2011

# Find the number of leaves of a rooted tree.
# (((0:4.359500e-02,1:4.359500e-02)5:1.951410e-01,2:2.387360e-01)7:8.480900e-02,(3:7.356900e-02,4:7.356900e-02)6:2.499760e-01)8:0.000000e+00; 
sub get_number_leave ($)
{
  my ($newickTree) = @_;
  my $r = 0;
  my $s = $newickTree;
  my @elements = split (/[\(\),]/, $s);
  for (my $i = 0; $i <= $#elements; $i++)
  {
    if (length $elements[$i] > 0)
    {
      $r++;
    }
  }
  $r = ($r + 1) / 2;

  return $r;
}

# (((0:4.359500e-02,1:4.359500e-02)5:1.951410e-01,2:2.387360e-01)7:8.480900e-02,(3:7.356900e-02,4:7.356900e-02)6:2.499760e-01)8:0.000000e+00; 
# mauve analysis: ma
# class: Newick
# Function name: ParseTree
# A Newick tree string is given. 

# Find the position of the middle comma, which is the second one in the
# following example. Return -1 if no comma is found.
# (0:4.359500e-02,1:4.359500e-02)5:1.951410e-01,2:2.387360e-01
sub maNewickFindMiddleComma($)
{
  my ($s) = @_;
  my $v = -1;
  my @e = split //, $s;
  my $countParenthesis = 0;
  for (my $i = 0; $i <= $#e; $i++)
  {
    if ($e[$i] eq '(')
    {
      $countParenthesis++;
    }
    elsif ($e[$i] eq ')')
    {
      $countParenthesis--;
    }
    if ($countParenthesis == 0 and $e[$i] eq ',')
    {
      $v = $i;
    }
  }
  return $v;
}

sub maNewickParseSubtree ($$);

sub maNewickParseSubtree ($$)
{
  my ($s, $t) = @_;
  my $nodeNumber;
  my $downEdgeLength;
  my @e;
  my $leftNodeNumber; 
  my $rightNodeNumber;
  if ($s =~ /\((.+)\)(.+)/)
  {
    my $subtreeString = $1;
    my $node = $2;
    @e = split /:/, $node;
    $nodeNumber = $e[0];
    $downEdgeLength = $e[1];
    die "e must have two elements" unless $#e == 1;

    my $posComma = maNewickFindMiddleComma ($subtreeString);
    my $leftTree = substr $subtreeString, 0, $posComma;
    my $rightTree = substr $subtreeString, $posComma + 1;
    $leftNodeNumber = maNewickParseSubtree ($leftTree, $t);
    $rightNodeNumber = maNewickParseSubtree ($rightTree, $t);

    my $rec = {};
    $t->{$nodeNumber} = $rec;
    $rec->{left} = $leftNodeNumber;
    $rec->{right} = $rightNodeNumber;
    $rec->{len} = $downEdgeLength;
    $t->{$leftNodeNumber}{down} = $nodeNumber;
    $t->{$rightNodeNumber}{down} = $nodeNumber;
  }
  else
  {
    @e = split /:/, $s;
    $nodeNumber = $e[0];
    $downEdgeLength = $e[1];
    $leftNodeNumber = -1;
    $rightNodeNumber = -1;
    my $rec = {};
    $t->{$nodeNumber} = $rec;
    $rec->{left} = $leftNodeNumber;
    $rec->{right} = $rightNodeNumber;
    $rec->{len} = $downEdgeLength;
  }
  return $nodeNumber;
}

# Parse a tree from ClonalOrigin's output.
sub maNewickParseTree ($)
{
  my ($s) = @_;
  $s =~ s/;//g;
  $s =~ /\((.+)\)(.+)/;
  my %tree;
  maNewickParseSubtree ($s, \%tree);

  # Find the time at all of the nodes.
  foreach my $node ( keys %tree ) {
    my $daughter = $tree{$node}{left};
    if ($daughter == -1)
    {
      $tree{$node}{uptime} = 0;
    }
    else
    {
      my $t = 0;
      while ($daughter > -1)
      {
        $t += $tree{$daughter}{len};
        $daughter = $tree{$daughter}{left};
      }
      $tree{$node}{uptime} = $t;
    }
    $tree{$node}{dntime} = $tree{$node}{uptime} + $tree{$node}{len};
  }
  return \%tree;
}

sub maNewickPrintTree ($)
{
  my ($tree) = @_;
  foreach my $family ( keys %$tree ) {
     print "$family:\t$tree->{$family}{left}\t$tree->{$family}{right}\t$tree->{$family}{len}";
     if (exists $tree->{$family}{down})
     {
       print "\t$tree->{$family}{down}";
     }
     else
     {
       print "\tROOT";
     }
     if (exists $tree->{$family}{uptime})
     {
       print "\t$tree->{$family}{uptime}\t$tree->{$family}{dntime}\n";
     }
     else
     {
       print "\n";
     }
  }
}

# Creates a table of binary indicators of pairs of recombinant edges.
sub maNewicktFindRedEdge ($)
{
  my ($tree) = @_;
  my $numberBranch = scalar (keys %$tree);

  # Creates a table.
  my @m;
  for (my $i = 0; $i < $numberBranch; $i++)
  {
    my @rowMap = (0) x $numberBranch;
    push @m, [ @rowMap ];
  }

  # i is source, and j is sink.
  for (my $i = 0; $i < $numberBranch; $i++)
  {
    for (my $j = 0; $j < $numberBranch; $j++)
    {
      if ($tree->{$i}{dntime} <= $tree->{$j}{uptime})
      {
        $m[$i][$j] = 0;
      }
      else
      {
        $m[$i][$j] = 1;
      }
    }
  }
  return \@m;
}

# Creates a table of binary indicators of pairs of recombinant edges that do
# change tree topology.
sub maNewicktFindRedEdgeChangeTopology ($)
{
  my ($tree) = @_;
  my $numberBranch = scalar (keys %$tree);

  # Creates a table.
  my $m = maNewicktFindRedEdge ($tree);

  # i is source, and j is sink.
  for (my $i = 0; $i < $numberBranch; $i++)
  {
    for (my $j = 0; $j < $numberBranch; $j++)
    {
      if ($i == $j)
      {
        $m->[$i][$j] = 0;
      }
      if ($tree->{$i}{left} == $j or $tree->{$i}{right} == $j)
      {
        $m->[$i][$j] = 0;
      }
      if ($tree->{$i}{len} > 0 and $tree->{$j}{len} > 0)
      {
        if ($tree->{$i}{down} == $tree->{$j}{down})
        {
          $m->[$i][$j] = 0;
        }
      }
    }
  }
  return $m;
}

# Creates a table of binary indicators of pairs of recombinant edges that do
# NOT change tree topology.
sub maNewicktFindRedEdgeNotChangeTopology ($)
{
  my ($tree) = @_;
  my $numberBranch = scalar (keys %$tree);

  # Creates a table.
  my $m = maNewicktFindRedEdge ($tree);

  # i is source, and j is sink.
  for (my $i = 0; $i < $numberBranch; $i++)
  {
    for (my $j = 0; $j < $numberBranch; $j++)
    {
      my $c = 0;
      if ($i == $j)
      {
        $c = 1;
      }
      if ($tree->{$i}{left} == $j or $tree->{$i}{right} == $j)
      {
        $c = 1;
      }
      if ($tree->{$i}{len} > 0 and $tree->{$j}{len} > 0)
      {
        if ($tree->{$i}{down} == $tree->{$j}{down})
        {
          $c = 1;
        }
      }
      if ($c == 0)
      {
        $m->[$i][$j] = 0;
      }
    }
  }
  return $m;
}

# Creates a table of binary indicators of particular pairs of recombinant edges.
#  -pairs 0,3:0,4:1,3:1,4
#  -pairs 3,0:3,1:4,0:4,1
sub maNewicktFindRedEdgePair ($$)
{
  my ($tree, $pair) = @_;
  my $numberBranch = scalar (keys %$tree);

  # Creates a table.
  my $m = maNewicktFindRedEdge ($tree);

  my @v;
  my @e = split /:/, $pair;
  for my $element (@e)
  {
    push @v, [ split /,/, $element ]; 
  }

  # i is source, and j is sink.
  for (my $i = 0; $i < $numberBranch; $i++)
  {
    for (my $j = 0; $j < $numberBranch; $j++)
    {
      my $c = 0;
      for my $vi (0 .. $#v)
      {
        if ($v[$vi][0] == $i and $v[$vi][1] == $j)
        {
          $c = 1;
        }
      }
      if ($c == 0)
      {
        $m->[$i][$j] = 0;
      }
    }
  }
  return $m;
}



1;
