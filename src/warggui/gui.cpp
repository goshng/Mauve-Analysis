#include <cstring>
#include <cstdlib>
#include <gsl/gsl_rng.h>
#include "mainwindowimpl.h"
#include "../warg/src/rng.h"
#include "../warg/src/mpiutils.h"

bool verbose=false;

namespace weakarg
{
	//void opt() {};
	ProgramOptions& opt() {static ProgramOptions po;return po;}
}

static const char * help=
    "\n\
    Usage: gui [OPTIONS] <filename>\n\
	gui file.xml > file.out \n\
	gui -o file.xml -H 3 > file.out \n\
	gui -o file.xml -b -H 3 > file.out \n\
	For graphical use, no options are necessary.  \n\
	To pre-run a limited set of functions, or use batch \n\
	mode, the following options can be used.\n\
	NOTE: They are processed IN ORDER, so be sure to open\n\
	the file before using it, and set output names before\n\
	producing the output!\n\
	\n\
	Options:\n\
	-b		Batch mode.  Perform operations then quit \n\
			without displaying the gui.\n\
	-o <filename>	Open the specified input XML file.\n\
	-c <filename><:num>	\n\
			Write a csv file of the main features.  If\n\
			:num is provided then it changes the variables\n\
			in the output (default 2):\n\
				:1 - Parameters only\n\
				:2 - Parameters + Number of recedges\n\
				:3 - Parameters + Clonal Pairwise Distances\n\
				:4 - All of the above.\n\
	-T <filename>	Redirect the batch processed output \n\
			from stdout to the file specified.\n\
			Specify "" to display to the gui.\n\
	-t <list>	Perform a convergence of trees test \n\
			between the open file and the set of \n\
			specified files (separated by commas).\n\
	-g <list><:num>	Perform a gelman-rubin test \n\
			between the open file and the set of \n\
			specified files (separated by commas). \n\
			<num> takes the same meaning as for -c.\n\
	-S <filename>	Redirect the Score against true tree output \n\
			from stdout to the file specified.\n\
			Specify "" to display to the gui.\n\
	-s <filename>	Perform a score against true tree test\n\
			against the newick-format file specified.\n\
	-C <i>		Performs a consensus-of-trees either with\n\
			the specified cutoff (integer i=0-100) or \n\
			an extended consensus if i<0.\n\
	-H 0/1/2/3	Extract the heatmap. Pass 0 for no prior correction,\n\
			1 for correction in number of std, 2 for correction\n\
			measured in proportion or 3 for prior only.\n\
	-d 0/1/2/3	Extract the pairwise clonal tree heatmap. Pass 0 for \n\
			no prior correction,\n\
			1 for correction in number of std, 2 for correction\n\
			measured in proportion or 3 for prior only.\n\
	-e <operation>:<value>:<filename>\n\
			Extract iterations and thin. <operation> is either\n\
			either \"thin\" with value \"x\" to thin every\n\
			x'th iteration, or \"extract\" with value \"x-y\" to extract\n\
			iterations between x and y.  The outputfile is after\n\
			the final colon.\n\
	-E <filenames>:<filename>\n\
			Combines the list of output files specified NOT \n\
			including the current one, separated by commas, and\n\
			outputs to the file after the colon.\n\
	-n 		Start in the display mode without recombination (You must\n\
			specify the outputfile with -o).\n\
	-h		This help message.\n\
	\n\
	Examples:\n\
	\n\
	-o test1.xml -t test2.xml -b:\n\
		Performs a convergence of tree test between files\n\
		test1.xml and test2.xml, printing the results to\n\
		stdout and exiting the program.\n\
	-o test1.xml -t test2.xml:\n\
		As above, but leave the gui window open.\n\
	-o test1.xml -T "" -t test2.xml:\n\
		As above, but opens the results in the gui \n\
		and with the gui window open.\n\
	-o test1.xml -t test2.xml,test3.xml -b:\n\
		Performs a convergence of tree test between files\n\
		test1.xml, test2.xml and test3.xml.\n\
	-t test1.xml -o test2.xml -b:\n\
		Fails.\n\
    ";

int main(int argc, char *argv[])
{

  srand(time(NULL));
  MainWindowImpl mainwindowimpl;

  int grmode=2;
  int expmode=2;
  optind=0;
  bool batch=true;
  int priorcorrectHM=3;
  int priorcorrectPD=0;
  int recstart=0;
  int c;
  char *xmlfilename = NULL;

/*
  while ((c = getopt (argc, argv, "c:o:s:d:C:S:T:t:g:be:E:H:hn")) != -1)
  {
    switch (c)
    {
      case('o'): xmlfilename = strdup(optarg);break;
      case('b'): batch = true;break;
      case('H'): priorcorrectHM = atoi(optarg);break;
      default:
        cout<<"Wrong arguments: did not recognise "<<c<<" "<<optarg<<endl<<help<<endl;return 1;
        abort ();
    }
  }  
*/
  if (argc == 2)
  {
    xmlfilename = strdup(argv[1]);
    if (xmlfilename != NULL)
    {
      mainwindowimpl.openXMLFile(xmlfilename);
      mainwindowimpl.on_actionHeat_map_activated(priorcorrectHM);
      free (xmlfilename);
    }
  }
  else
  {
    cerr << "Error in the command line: ./gui file.xml";
  }
	return(0);
}
