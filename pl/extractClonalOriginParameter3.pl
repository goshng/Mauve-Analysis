#!/opt/local/bin/perl -w
use strict;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use XML::Parser;

# Based on computeMedians.pl <ClonalOrigins XML or xml.bz2>\n";
# Based on extractClonalOriginParameter2.pl <ClonalOrigins XML or xml.bz2>\n";
# Generating trace plots
if(@ARGV==0){
 
	die "Usage: extractClonalOriginParameter.pl <ClonalOrigins XML or xml.bz2>\n";
}

my @lens;
my @meantheta;
my @meandelta;
my @meanrho;
my $itercount=0;
my $curtheta=0;
my $curdelta=0;
my $currho=0;
my $tag;
my $fsNumber;
my $content;
my $logLine;
my $lineNumber = 0;

my $blockcount=scalar(@ARGV);	# assume one block per file

#print "Gen\tf\titer\tll\tprior\ttheta\trho\tdelta\n";
# extract posterior mean estimates of global parameters from each file
foreach my $f (@ARGV){
	my $fs;
  
	if($f =~ /\.bz2$/){
		$fs = bunzip2 $f => "tmpxml" or die "IO::Uncompress::Bunzip2 failed: $Bunzip2Error\n";
		$fs = "tmpxml";
	}else{
		$fs = $f;
	}
  $f =~ /.+\.(\d+)\.xml\w*/;
  $fsNumber = $1;

  # DEBUG: some incomplete - remove these later.
  if ($fsNumber == 225 
      or $fsNumber == 83
      or $fsNumber == 63)
  {
    next;
  }
  
  # Check the number of iterations.
  open (FILE, "grep number $fs |") or die "ERROR: Could not open $f: $!\n";
  my $lineNumber = 0;
  while (<FILE>)
  {
    $lineNumber++;
  }
  close (FILE);
  next if $lineNumber != 101;

	my $parser = new XML::Parser();

	$parser->setHandlers(      Start => \&startElement,
                           End => \&endElement,
                           Char => \&characterData,
                           Default => \&default);

	$itercount=0;
	$curtheta=0;
	$curdelta=0;
	$currho=0;
	my $doc;
  
	eval{ $doc = $parser->parsefile($fs)};
	print STDERR "Unable to parse XML of $f, error $@\n" if $@;
	next if $@;
}

exit;

sub startElement {
       my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
       SWITCH: {
              if ($element eq "Iteration") {
                     $itercount++;
                     $logLine = "$lineNumber\t$fsNumber\t$itercount";
                     $lineNumber++;
                     last SWITCH;
              }
              if ($element eq "delta") {
                     last SWITCH;
              }
              if ($element eq "rho") {
                     last SWITCH;
              }
       }
}

sub endElement {
  my ($p, $elt) = @_;
	$tag = "";
  if ($elt eq "ll" 
      or $elt eq "prior" 
      or $elt eq "theta" 
      or $elt eq "rho" 
      or $elt eq "delta")
  {
    $logLine .= "\t$content";
  } 
                     
  if ($elt eq "Iteration" and $itercount > 1)
  {
    print $logLine, "\n";
  }
  elsif ($elt eq "Iteration" and $itercount == 1)
  {
    $lineNumber--;
  }
}

sub characterData {
       my( $parseinst, $data ) = @_;
	$data =~ s/\n|\t//g;
  if ($tag eq "ll" 
      or $tag eq "prior" 
      or $tag eq "theta" 
      or $tag eq "rho" 
      or $tag eq "delta")
  {
    $content = $data;
  }
	if($tag eq "Blocks"){
		$data =~ s/.+\,//g;
		push( @lens, $data ) if(length($data)>1);
	}
}

sub default {
}
