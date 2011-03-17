#!/opt/local/bin/perl -w
use strict;
use IO::Uncompress::Bunzip2 qw(bunzip2 $Bunzip2Error);
use XML::Parser;

# Based on computeMedians.pl <ClonalOrigins XML or xml.bz2>\n";
# Based on extractClonalOriginParameter.pl <ClonalOrigins XML or xml.bz2>\n";
# This is a 2nd part of the parameter extraction.
if(@ARGV==0){
	die "Usage: extractClonalOriginParameter2.pl <ClonalOrigins XML or xml.bz2>\n";
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
my $content;
my %recedge;
my $blockLength;
my $alignmentLength;

####################################################
# Map
my $numberOfTaxa = 5;
my $numberOfLineage = 2 * $numberOfTaxa - 1;
my $genomeLength = 2200000;
#my $genomeLength = 60220;


# mapImport index is 1-based, and blockImmport index is 0-based.
# map starts at 1.
# block starts at 0.
my @blockImport;
my @mapImport;
for (my $i = 0; $i < $numberOfLineage; $i++)
{
  my @mapPerLineage;
  for (my $j = 0; $j < $numberOfLineage; $j++)
  {
    my @asinglemap = (0) x $genomeLength;
    push @mapPerLineage, [ @asinglemap ];
  }
  push @mapImport, [ @mapPerLineage ];
}


my $offsetPosition = 0;

####################################################

my $blockcount=scalar(@ARGV);	# assume one block per file

# extract posterior mean estimates of global parameters from each file
foreach my $f (@ARGV){
	my $fs;
print STDERR $f, "\n";
	if($f =~ /\.bz2$/){
		$fs = bunzip2 $f => "tmpxml" or die "IO::Uncompress::Bunzip2 failed: $Bunzip2Error\n";
		$fs = "tmpxml";
	}else{
		$fs = $f;
	}

  $f =~ /.+\.(\d+)\.xml/;
  my $fsNumber = $1;
  $f =~ /(.+)\/run-clonalorigin/;
  my $baseDir = $1;
  my $alignment = "$baseDir/run-lcb/core_alignment.xmfa.$fsNumber";

  #####################################################
  # Find the position and strand in the alignment file.
  open(FILE,"grep \"1:\" $alignment|") or die "$!";
  my $l = <FILE>;
  my $startpos; 
  my $endpos;
  my $strand;
  if ($l =~ /1\:(\d+)-(\d+)\s+(.)/)
  {
    $startpos = $1;
    $endpos = $2;
    $strand = $3;
  }
  else
  {
    die "parse error in $alignment";
  }
  die "strand" unless $strand eq "+" or $strand eq "-";
  close(FILE);
  if ($strand eq "+")
  {
    $offsetPosition = $startpos;
    $alignmentLength = $endpos - $startpos;
  }
  else 
  {
    $offsetPosition = $endpos;
    $alignmentLength = $startpos - $endpos;
  }
  #####################################################

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
  #last; # DEBUG
}

# convert to per-site values of theta and rho
#for( my $i=0; $i<@meantheta; $i++){
	#$meantheta[$i] /= $lens[$i];
	#$meanrho[$i] /= $meandelta[$i] + $lens[$i];
#}

#print "theta\trho\tdelta\n";
#for( my $i=0; $i<@meantheta; $i++){
  #print $meantheta[$i], "\t", $meanrho[$i], "\t", $meandelta[$i], "\n";
#}

for (my $i = 0; $i < $genomeLength; $i++)
{
  my $pos = $i;
  print "$pos";
  for (my $j = 0; $j < $numberOfLineage; $j++)
  {
    for (my $k = 0; $k < $numberOfLineage; $k++)
    {
      print "\t", $mapImport[$j][$k][$pos];
    }
  }
  print "\n";
}

exit;

sub startElement {
       my( $parseinst, $element, %attrs ) = @_;
	$tag = $element;
       SWITCH: {
              if ($element eq "Iteration") {
                     $itercount++;

                # blockImport ...
                @blockImport = ();
                for (my $i = 0; $i < $numberOfLineage; $i++)
                {
                  my @mapPerLineage;
                  for (my $j = 0; $j < $numberOfLineage; $j++)
                  {
                    my @asinglemap = (0) x $blockLength;
                    push @mapPerLineage, [ @asinglemap ];
                  }
                  push @blockImport, [ @mapPerLineage ];
                }


                     last SWITCH;
              }
              if ($element eq "delta") {
                     last SWITCH;
              }
              if ($element eq "rho") {
                     last SWITCH;
              }
              if ($element eq "recedge") {
                     last SWITCH;
              }
              if ($element eq "Tree") {
                     $content = "";
                     last SWITCH;
              }
       }
}

sub endElement {
  my ($p, $elt) = @_;
	$tag = "";
  if ($elt eq "Tree")
  {
    # print STDERR $content, "\n";
  }
  if ($elt eq "recedge")
  {
    #print $recedge{start}, "\t";
    #print $recedge{end}, "\t";
    #print $recedge{efrom}, "\t";
    #print $recedge{eto}, "\t";
    #print $recedge{afrom}, "\t";
    #print $recedge{ato}, "\n";
    for (my $i = $recedge{start}; $i < $recedge{end}; $i++)
    {
      $blockImport[$recedge{eto}][$recedge{efrom}][$i]++;
    }
  }
  
  if ($elt eq "Iteration")
  {
    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $i;
      for (my $j = 0; $j < $numberOfLineage; $j++)
      {
        for (my $k = 0; $k < $numberOfLineage; $k++)
        {
          if ($blockImport[$j][$k][$pos] > 0) 
          {
            $blockImport[$j][$k][$pos] = 1;
          }
        }
      }
    }

    for (my $i = 0; $i < $blockLength; $i++)
    {
      my $pos = $offsetPosition + $i;
      for (my $j = 0; $j < $numberOfLineage; $j++)
      {
        for (my $k = 0; $k < $numberOfLineage; $k++)
        {
          $mapImport[$j][$k][$pos] += $blockImport[$j][$k][$i];
        }
      }
    }
  }

  if ($elt eq "outputFile")
  {
    print STDERR "outFile: [ $offsetPosition ]\n";
    print STDERR "outFile: [ $blockLength ]\n";
    print STDERR "outFile: [ $itercount ]\n";
    for (my $i = 1; $i <= $blockLength; $i++)
    {
      my $pos = $offsetPosition + $i;
      for (my $j = 0; $j < $numberOfLineage; $j++)
      {
        for (my $k = 0; $k < $numberOfLineage; $k++)
        {
          # $mapImport[$j][$k][$pos] /= $itercount;
        }
      }
    }
  }
}

sub characterData {
       my( $parseinst, $data ) = @_;
	$data =~ s/\n|\t//g;
	if($tag eq "Tree"){
    $content .= $data;    
	}
	if($tag eq "start"){
    $recedge{start} = $data;
	}
	if($tag eq "end"){
    $recedge{end} = $data;
	}
	if($tag eq "efrom"){
    $recedge{efrom} = $data;
	}
	if($tag eq "eto"){
    $recedge{eto} = $data;
	}
	if($tag eq "afrom"){
    $recedge{afrom} = $data;
	}
	if($tag eq "ato"){
    $recedge{ato} = $data;
	}

	if($tag eq "Blocks"){
		if ($data =~ s/.+\,//g)
    {
      $blockLength = $data;
      print STDERR "Blocks: [ $blockLength ]\n";
    }
		push( @lens, $data ) if(length($data)>1);
	}
}

sub default {
}
