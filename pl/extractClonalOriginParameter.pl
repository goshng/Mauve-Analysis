#!/opt/local/bin/perl -w
use strict;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use XML::Parser;

# Based on computeMedians.pl <ClonalOrigins XML or xml.bz2>\n";
if(@ARGV==0){
 
	die "Usage: extractClonalOriginParameter.pl <ClonalOrigins XML or xml.bz2>\n";
}

my @lens;
my @meantheta;
my @meandelta;
my @meanrho;
my @itercounts;
my @fsNumbers;
my $itercount=0;
my $curtheta=0;
my $curdelta=0;
my $currho=0;
my $tag;

my $blockcount=scalar(@ARGV);	# assume one block per file

# extract posterior mean estimates of global parameters from each file
foreach my $f (@ARGV){
	my $fs;
	if($f =~ /\.bz2$/){
		$fs = bunzip2 $f => "tmpxml" or die "IO::Uncompress::Bunzip2 failed: $Bunzip2Error\n";
		$fs = "tmpxml";
	}else{
		$fs = $f;
	}
  $fs =~ /.+\.(\d+)\.xml/;
  my $fsNumber = $1;
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
	print "Unable to parse XML of $f, error $@\n" if $@;
	next if $@;
	print "parsed $f\n";
	$curtheta /= $itercount;
	$curdelta /= $itercount;
	$currho /= $itercount;
	push( @meantheta, $curtheta );
	push( @meandelta, $curdelta );
	push( @meanrho, $currho );
  push( @itercounts, $itercount);
  push( @fsNumbers, $fsNumber);
}

# convert to per-site values of theta and rho
for( my $i=0; $i<@meantheta; $i++){
	$meantheta[$i] /= $lens[$i];
	$meanrho[$i] /= $meandelta[$i] + $lens[$i];
}

print "theta\trho\tdelta\tblock\tcount\n";
for( my $i=0; $i<@meantheta; $i++){
  print $meantheta[$i], "\t", $meanrho[$i], "\t", $meandelta[$i], "\t", $fsNumbers[$i], "\t", $itercounts[$i], "\n";
}

exit;

sub startElement {
       my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
       SWITCH: {
              if ($element eq "Iteration") {
                     $itercount++;
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
	$tag = "";
}

sub characterData {
       my( $parseinst, $data ) = @_;
	$data =~ s/\n|\t//g;
	$curtheta += $data if ($tag eq "theta");
	$curdelta += $data if ($tag eq "delta");
	$currho += $data if ($tag eq "rho");
	if($tag eq "Blocks"){
		$data =~ s/.+\,//g;
		push( @lens, $data ) if(length($data)>1);
	}
}

sub default {
}
