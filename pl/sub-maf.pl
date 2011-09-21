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

# Count the number of lines for each block of a MAF-format file.
# The first element is the number of lines before the first sequence alignment.
# The rest of elements are numbers of lines for all of the alignments. Each
# block is assumed to contain lines from `a' to the blank line.
sub peachMafCountFromMauveXmfa2Maf ($)
{
  my ($f) = @_;
  my @v;
  my $c = 1;
  open MAF, $f or die "cannot open < $f $!";
  my $line = <MAF>;
  push @v, $c;
  while ($line = <MAF>)
  {
    $c++;
    if ($line =~ /^a/)
    {
      $c = 1;
    }
    elsif ($line =~ /^$/)
    {
      push @v, $c;
    }
  }
  close MAF;
  return @v;
}

1;
