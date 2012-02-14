#!/usr/bin/perl -w
use strict;
use warnings;

use File::Path qw(mkpath);
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
            'copywarg',
            'printjob',
            'printtmp',
            'printwarg',
            'killwarg',
            'jobidfile=s',
            'only=i',
            'command=s'
            ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2) if $man;

=head1 NAME

cac.pl - monitor or kill warg jobs in compute nodes

=head1 VERSION

cac.pl 1.0

=head1 SYNOPSIS

perl cac.pl [-h] [-help] [-version] [-verbose] 

=head1 DESCRIPTION

perl cac.pl -printjob -command "ps -ef | grep warg | wc"

perl cac.pl -printjob

perl cac.pl -printwarg

perl cac.pl -killwarg

perl cac.pl -jobidfile y

perl cac.pl -printtmp

perl cac.pl -copywarg

=head1 OPTIONS

=over 8

=item B<-help> | B<-h>

Print the help message; ignore other arguments.

=item B<-version>

Print program version; ignore other arguments.

=item B<-verbose>

Prints status and info messages during processing.

=item B<***** COMMAND OPTIONS *****>

=item B<-copywarg>

perl cac.pl -copywarg

This allows to copy all of the output files of warg command. CO1's output files
are in directory output, and CO2's output files in directory output2. Because it
copy files to a directory named output. You can run the command at an empty
directory or the main output directory such as Documents/Projects/m2.

=back

=head1 AUTHOR

Sang Chul Choi, C<< <goshng_at_yahoo_dot_co_dot_kr> >>

=head1 BUGS

If you find a bug please post a message rnaseq_analysis project at codaset dot
com repository so that I can make compute-block-length.pl better.

=head1 COPYRIGHT

Copyright (C) 2011-2012 Sang Chul Choi

=head1 LICENSE

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut


my $printjob = 0;
my $killwarg = 0;
my $printwarg = 0;
my $printtmp = 0;
my $jobidfile; 
my $only;
my $command = "ps -ef | grep warg | wc -l";

if (exists $params{printtmp}) {
  $printtmp = 1;
} 

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

if (exists $params{only}) {
  $only = $params{only};
} 

if (exists $params{jobidfile}) {
  $jobidfile = $params{jobidfile};
} 


sub getComputeNode ();
sub getComputeJobID ();
sub printJob ($$);
sub printWarg ($$);
sub copyWarg ($$);
sub printTmp ($$);
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
elsif ($printtmp == 1)
{
  my @n = getComputeNode ();
  my @jobid = getComputeJobID ();
  printTmp (\@n, \@jobid);    
}
elsif (exists $params{copywarg}) 
{
  my @n = getComputeNode ();
  my @jobid = getComputeJobID ();
  copyWarg (\@n, \@jobid);    
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

sub printTmp ($$)
{
  my ($address, $jobid) = @_;
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {

    print "ssh -x $address->[$i] ls /tmp/$jobid->[$i]/\n";
  }
}


sub printWarg ($$)
{
  my ($address, $jobid) = @_;
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {
    print "$address->[$i]\n";
    open WARG, "ssh -x $address->[$i] ps -ef | grep warg |";
    while (<WARG>)
    {
      # sc2265   12887 12218 99 May12 ?        23:39:19 ./warg -a 1 1 0.1 1 1 1 1 1 0 0 0 -x 1000000 -y 1000000 -z 10000 input/2/cornellf-3.tree input/2/core_alignment.1.xmfa.210 output/2/1/core_co.phase2.xml.210
      #print $_, "\n";
      if (/(\S+)\s+\.\/warg -a 1 1 0.1 1 1 1 1 1 0 0 0\s+-x\s+\d+\s+-y\s+\d+\s+-z\s+\d+\s+\S+\s+(\S+)\s+(\S+)/)
      {
        if ($3 eq "-D")
        {
# sc2265    4586  4585 95 21:17 ?        00:10:55 ./warg -a 1 1 0.1 1 1 1 1 1 0 0
# 0 -x 10000000 -y 100000000 -z 100000 -T s0.080814517322956 -D 743.702415841584
# -R s0.0118491287894766 input/3/clonaltree.nwk input/3/core_alignment.xmfa.274
# output/3/core_co.phase3.xml.274
          if (/(\S+)\s+\.\/warg -a 1 1 0.1 1 1 1 1 1 0 0 0\s+-x\s+\d+\s+-y\s+\d+\s+-z\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)/)
          {
            print "$3 ($1): ";
            system "ssh -x $address->[$i] grep number /tmp/$jobid->[$i]/$3 | wc -l";
            #my $id = $3;
            #$id =~ /\.xml\.(\d+)/;
            #print "$1\t";
          }
        }
        else
        {
          print "$3 ($1): ";
          system "ssh -x $address->[$i] grep number /tmp/$jobid->[$i]/$3 | wc -l";
          #my $id = $3;
          #$id =~ /\.xml\.(\d+)/;
          #print "$1\t";
        }
      }
    }
    close WARG;
  }
}

sub copyWarg ($$)
{
  my ($address, $jobid) = @_;
  for (my $i = 0; $i <= $#{ $address }; $i++)
  {
    open WARG, "ssh -x $address->[$i] ps -ef | grep warg |";
    while (<WARG>)
    {
      # sc2265   12887 12218 99 May12 ?        23:39:19 ./warg -a 1 1 0.1 1 1 1 1 1 0 0 0 -x 1000000 -y 1000000 -z 10000 input/2/cornellf-3.tree input/2/core_alignment.1.xmfa.210 output/2/1/core_co.phase2.xml.210
      #print $_, "\n";
      my $outputdir = "";
      if (/(\S+)\s+\.\/warg -a 1 1 0.1 1 1 1 1 1 0 0 0\s+-x\s+\d+\s+-y\s+\d+\s+-z\s+\d+\s+\S+\s+(\S+)\s+(\S+)/)
      {
        if ($3 eq "-D")
        {
          # CO2
# sc2265    4586  4585 95 21:17 ?        00:10:55 ./warg -a 1 1 0.1 1 1 1 1 1 0 0
# 0 -x 10000000 -y 100000000 -z 100000 -T s0.080814517322956 -D 743.702415841584
# -R s0.0118491287894766 input/3/clonaltree.nwk input/3/core_alignment.xmfa.274
# output/3/core_co.phase3.xml.274
          if (/(\S+)\s+\.\/warg -a 1 1 0.1 1 1 1 1 1 0 0 0\s+-x\s+\d+\s+-y\s+\d+\s+-z\s+\d+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+\S+\s+(\S+)\s+(\S+)/)
          {
            #print "CO2 $3 ($1): ";
            my $outputfile = $3;
            $outputfile =~ /(.+)\//;
            $outputdir = $1;
            #unless (-d $outputdir) {
              #mkpath $outputdir;
            #} 
            #system "scp -q $address->[$i]:/tmp/$jobid->[$i]/$outputfile $outputfile";
          }
        }
        else
        {
          # CO1
          #print "CO1 $3 ($1): ";
          my $outputfile = $3;
          $outputfile =~ /(.+)\//;
          $outputdir = $1;
          #unless (-d $outputdir) {
            #mkpath $outputdir;
          #} 
          #system "scp -q $address->[$i]:/tmp/$jobid->[$i]/$outputfile $outputfile";
        }
      }

      # 
      my $outputbasedir;
      my $codir;
      if (length($outputdir) > 0)
      {
        $outputdir =~ /(.+)\//;
        $outputbasedir = $1;
        $outputbasedir =~ /(.+)\//;
        $codir = $1;
        unless (-d $outputbasedir) {
          mkpath $outputbasedir;
        } 
        system "scp -qr $address->[$i]:/tmp/$jobid->[$i]/$outputbasedir $codir";
        # print "\n";
        last;
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
    print "$address->[$i]\t";
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
