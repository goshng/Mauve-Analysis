use strict;
use warnings;

use Getopt::Long;
use Pod::Usage;

$| = 1; # Do not buffer output

my $VERSION = 'cac.pl 1.0';

my $man = 0;
my $help = 0;
my %params = ('help' => \$help, 'h' => \$help);    
GetOptions( \%params,
            'help|h',
            'verbose',
            'version' => sub { print $VERSION."\n"; exit; },
            'printjob',
            'printwarg',
            'killwarg',
            'jobidfile=s',
            'command=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

compute-block-length.pl - Computes the lengths of blocks

=head1 VERSION

compute-block-length.pl 1.0

=head1 SYNOPSIS

perl compute-block-length.pl.pl [-h] [-help] [-version] [-verbose] [-base basename] 

=head1 DESCRIPTION

compute-block-length.pl counts the lengths of blocks.

perl cac.pl -printjob -command "ps -ef | grep warg | wc"
perl cac.pl -printjob
perl cac.pl -printwarg
perl cac.pl -killwarg
perl cac.pl -jobidfile y

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** INPUT OPTIONS *****>

=item B<-base> <basename>

The alignment files are in a directory called run-lcb. They are prefixed with
core_alignment.xmfa, and suffixed with dot and numbers: i.e.,
core_alignment.xmfa.1.  The base name includes the base directory as well so
that the script can locate an alignment file with its full path.

=item B<-block> <number>

This allows to compute the length of a single block.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make compute-block-length.pl better.

=head1 COPYRIGHT

Copyright (C) 2011 Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


my $printjob = 0;
my $killwarg = 0;
my $printwarg = 0;
my $jobidfile; 
my $command = "ps -ef | grep warg | wc";

if (exists $params{printwarg}) {
  $printwarg = 1;
} 

if (exists $params{printjob}) {
  $printjob = 1;
} 

if (exists $params{killwarg}) {
  $killwarg = 1;
} 

if (exists $params{command}) {
  $command = $params{command};
} 

if (exists $params{jobidfile}) {
  $jobidfile = $params{jobidfile};
} 


sub getComputeNode ();
sub getComputeJobID ();
sub printJob ($$);
sub printWarg ($$);
sub killWarg ($);
sub jobIDFile ($);
sub jobIDFilexxx ();

if ($printjob == 1)
{
  my @n = getComputeNode ();
  printJob (\@n, $command);
} 
elsif ($printwarg == 1)
{
  my @n = getComputeNode ();
  my @jobid = getComputeJobID ();
  printWarg (\@n, \@jobid);    
}
elsif ($killwarg == 1)
{
  my @n = getComputeNode ();
  killWarg (\@n);    
}
elsif (defined ($jobidfile))
{
  my @n = getComputeNode ();
  jobIDFile (\@n);
}

sub jobIDFile ($)
{
  my ($address) = @_;
  open JOBIDFILE, ">$jobidfile";
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {
    open WARG, "ssh -x $address->[$i] ps -ef | grep warg |";
    while (<WARG>)
    {
      #          ^^^^^  
      # sc2265   12887 12218 99 May12 ?        23:39:19 ./warg -a 1 1 0.1 1 1 1 1 1 0 0 0 -x 1000000 -y 1000000 -z 10000 input/2/cornellf-3.tree input/2/core_alignment.1.xmfa.210 output/2/1/core_co.phase2.xml.210
      if (/(\S+)\s+\.\/warg -a 1 1 0.1 1 1 1 1 1 0 0 0\s+-x\s+\d+\s+-y\s+\d+\s+-z\s+\d+\s+\S+\s+(\S+)\s+(\S+)/)
      {
        my $xml = $3;
        $xml =~ /output\/(\d+)\/(\d+)\/core_co.phase2.xml.(\d+)/;
        my $REPETITION = $1;
        my $REPLICATE = $2;
        my $BLOCK = $3;
        print JOBIDFILE "-a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 1000000 -z 10000 input/$REPETITION/cornellf-3.tree input/$REPETITION/core_alignment.$REPLICATE.xmfa.$BLOCK output/$REPETITION/$REPLICATE/core_co.phase2.xml.$BLOCK\n";
      }
    }
    close WARG;
  }
  close JOBIDFILE;
}

sub jobIDFilexxx ()
{
  open JOBIDFILE, ">$jobidfile";

  open X, "x";
  while (<X>)
  {
    # output/7/1/core_co.phase2.xml.113 (17:02:04):      55      55    1375
    if (/output\/(\d+)\/(\d+)\/core_co.phase2.xml.(\d+)/)
    {
      my $REPETITION = $1;
      my $REPLICATE = $2;
      my $BLOCK = $3;
      print JOBIDFILE "-a 1,1,0.1,1,1,1,1,1,0,0,0 -x 1000000 -y 1000000 -z 10000 input/$REPETITION/cornellf-3.tree input/$REPETITION/core_alignment.$REPLICATE.xmfa.$BLOCK output/$REPETITION/$REPLICATE/core_co.phase2.xml.$BLOCK\n";
    }
  }
  close X;
  
  close JOBIDFILE;
}

sub killWarg ($)
{
  my ($address) = @_;
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {
    open WARG, "ssh -x $address->[$i] ps -ef | grep warg |";
    while (<WARG>)
    {
      #          ^^^^^  
      # sc2265   12887 12218 99 May12 ?        23:39:19 ./warg -a 1 1 0.1 1 1 1 1 1 0 0 0 -x 1000000 -y 1000000 -z 10000 input/2/cornellf-3.tree input/2/core_alignment.1.xmfa.210 output/2/1/core_co.phase2.xml.210
      if (/(\w+)\s+(\d+)/)
      {
        #print "ssh -x $address->[$i] kill $2\n";
        system "ssh -x $address->[$i] kill $2";
      }
    }
    close WARG;
  }
}

sub printWarg ($$)
{
  my ($address, $jobid) = @_;
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {
    open WARG, "ssh -x $address->[$i] ps -ef | grep warg |";
    while (<WARG>)
    {
      # sc2265   12887 12218 99 May12 ?        23:39:19 ./warg -a 1 1 0.1 1 1 1 1 1 0 0 0 -x 1000000 -y 1000000 -z 10000 input/2/cornellf-3.tree input/2/core_alignment.1.xmfa.210 output/2/1/core_co.phase2.xml.210
      if (/(\S+)\s+\.\/warg -a 1 1 0.1 1 1 1 1 1 0 0 0\s+-x\s+\d+\s+-y\s+\d+\s+-z\s+\d+\s+\S+\s+(\S+)\s+(\S+)/)
      {
        print "$3 ($1): ";
        system "ssh -x $address->[$i] grep number /tmp/$jobid->[$i]/$3 | wc";
      }
    }
    close WARG;
  }
}

sub printJob ($$)
{
  my ($address, $command) = @_;
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {
    system ("ssh -x $address->[$i] $command");
  }
}

sub getComputeNode ()
{
  my @v;
  open QSTAT, "qstat -f|";
  while (<QSTAT>)
  {
    if (/(compute-\d+-\d+)\.v4linux/)
    {
      push @v, $1;
    }
  }
  close QSTAT;
  return @v; 
}

sub getComputeJobID ()
{
  my @v;
  open QSTAT, "qstat -f|";
  while (<QSTAT>)
  {
    if (/Job Id:\s+(.+)/)
    {
      push @v, $1;
    }
  }
  close QSTAT;
  return @v;
}
