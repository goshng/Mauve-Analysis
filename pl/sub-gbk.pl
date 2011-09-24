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

sub peachGbkLength ($)
{
  my ($f) = @_;
  open FILE, $f or die "cannot open < $f $!";
  my $line = <FILE>;
  close FILE;
  my @e = split /\s+/, $line;
  return $e[2]; 
}

1;
__END__
=head1 NAME

sub-gbk.pl - Parsers of Genbank files

=head1 SYNOPSIS

  my $fnaSequence = maFastaParse ($fna);

=head1 VERSION

v1.0, Sat Jul 16 07:20:14 EDT 2011

=head1 DESCRIPTION

FASTA file parser.

=head1 FUNCTIONS

=over 4

=item sub maFastaParse ($)

  Argument 1: FASTA file
  Return: String

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 COPYRIGHT

Copyright (C) 2011 Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
