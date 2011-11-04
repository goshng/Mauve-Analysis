#include <fstream>
#include <iostream>
#include <string>
#include <cstring>
#include <cstdlib>
#include "SimpleOpt.h"
#include "rectree.h"
#include "param.h"
#include "move.h"
#include "data.h"
#include "rng.h"
#include "mpiutils.h"
#include "weakarg.h"
#include "wargxml.h"

using namespace std;

namespace weakarg
{
bool initializeTree(Data* &datap, RecTree* &rectree,vector<string> inputfiles,string datafile);///< initialises the rectree based on the inputfiles specified.
RecTree * makeGreedyTree(Data * data,WargXml * infile,vector< vector<double> >  * sumdetails,int *count,vector<double> * pars,vector<double> *sumdists);///< makes a greeedy "best tree" from a previous warg run
vector<double> readInputFiles(Data* &data, RecTree* &rectree,vector<double> &sumdists,vector<int> &keepregions,vector<int> &previousL,vector<string> inputfiles,string datafile,int greedystage);///< Reads the input files and processes them according to the stage of the input procedure.
ProgramOptions& opt()
{
  static ProgramOptions po;	// define a single instance of ProgramOptions per process.
  return po;
}
} // end namespace weakarg

// Command function prototypes
int runCommandMcmc (unsigned long seed,
                    string& xmfaFile);
int runCommandSim ();
int runCommandSump ();

string getVersion()
{
  string ret;
#ifdef PACKAGE_STRING
  ret.append(PACKAGE_STRING);
#else
  ret.append("warg2");
#endif
  ret.append(" build date ");
  ret.append(__DATE__);
  ret.append(" at ");
  ret.append(__TIME__);
  return(ret);
}

void printVersion()
{
  cout << getVersion() << endl;
}

static const char * help=
  "\
    NOTE: This program is created based on warg developed by Xavier Didelot.\n\
          Please, cite his Genetics paper (Genetics 186: 1435--1449)\n\
          if you use this program.\n\
    \n\
    Usage: warg2 <command> [Options]\n\
    \n\
    commands:\n\
    sim           Simulate data under ClonalOrigin model.\n\
    mcmc          Infer parameters using data under ClonalOrigin model.\n\
    sump          Summarize posterior samples from the inference made\n\
                  using mcmc command.\n\
    \n\
    sim options:\n\
    --tau NUM     The population splitting time\n\
    --a12 NUM     Relative rate of coalescent from population 1\n\
    --a21 NUM     Relative rate of coalescent from population 2\n\
    -N NUM        Number of replicates (the default is 10)\n\
    -T NUM        Sets the value of theta, the scaled mutation rate (the default is 100)\n\
    -R NUM        Sets the value of rho, the scaled recombination rate (the default is 100)\n\
    -D NUM        Sets the value of delta, the mean size of imports (the default is 500)\n\
    --block FILE  A block file contains numbers delimited by comma,\n\
                  spaces, or newline. The total length of the core genome is the\n\
                  sum of the numbers in the block file.\n\
                  (default: in.block)\n\
    --tree FILE   A tree file contains a newick formatted string\n\
                  (default: in.tree)\n\
    --xml FILE    An XML file that created from mcmc command.\n\
                  (default: in.xml)\n\
    --out FILE    A base name of output file names. (default: out)\n\
                  For example, an alignment file name is the output \n\
                  file base name suffixed \".xmfa\".\n\
    sim usages:\n\
    warg2 sim --block in.block --tree in.tree --N 2\n\
              -T s0.1 -R s0.05 -D 500 --out out\n\
                  With a block configuration and a species tree a recombinant\n\
                  tree is created using the recombination rate per site and\n\
                  the average tract length. The recombinant tree is used to\n\
                  create DNA sequence data using the mutation rate per site.\n\
                  Three files are created: out.1.xmfa, out.2.xmfa,\n\
                  and out.1.xml. The out.1.xmfa and out.2.xmfa contains the\n\
                  multiple sequence alignments from the two times of DNA\n\
                  sequence evolution simulation for the recombination tree\n\
                  created in the out.1.xml.\n\
    warg2 sim --xml in.xml --N 2 -T s0.1 --out out\n\
                  With the recombinant tree described in in.xml file sequence\n\
                  alignment data files are created using the mutation rate per\n\
                  site. Two replicate files are created: out.1.xmfa and\n\
                  out2.xmfa.\n\
    warg2 sim --tau 0.1 --a12 0.1 --a21 0.3 --block in.block --tree in.tree\n\
              --N 2 -T s0.1 -R s0.05 -D 500 --out out\n\
                  A recombinant tree is created under a differential coalescent\n\
                  rates and splitting event. Three files are created:\n\
                  out.1.xmfa, out.2.xmfa, and out.xml files.\n\
    \n\
    mcmc options:\n\
    --xmfa FILE   An XMFA data file (default: in.xmfa)\n\
    -w NUM        Sets the number of pre burn-in iterations (default is 100000)\n\
    -x NUM        Sets the number of burn-in iterations (default is 100000)\n\
    -y NUM        Sets the number of iterations after burn-in (default is 100000)\n\
    -z NUM        Sets the number of iterations between samples (default is 100)\n\
    -T NUM        Sets the value of theta. Use sNUM instead of NUM for per-site\n\
    -R NUM        Sets the value of rho. Use sNUM instead of NUM for per-site\n\
    -D NUM        Sets the value of delta\n\
    --tree FILE   A tree file contains a newick formatted string\n\
                  (default: in.tree)\n\
    --out FILE    A base name of output file names. (default: out)\n\
                  For example, an alignment file name is the output \n\
                  file base name suffixed \".xmfa\".\n\
    \n\
    sump options:\n\
    --xml FILE    An XML file that created from mcmc command.\n\
    --topology    Enable the feature of summaring gene tree topologies.\n\
    \n\
    Options:\n\
\n\
    -v            Verbose mode\n\
    -h, --help    This help message\n\
    -V, --version Print Version info\n\
    ";

void ShowUsage()
{
  cout << help << endl;
}

enum { OPT_HELP,
       OPT_VERSION,
       OPT_NUM_ISOLATES,
       OPT_THETA,
       OPT_RHO,
       OPT_DELTA,
       OPT_LENGTH_FRAGMENT,
       OPT_RANDOM,
       OPT_BLOCK_FILE,
       OPT_OUT_FILE,
       OPT_TREE_FILE,
       OPT_XML_FILE,
       OPT_XMFA_FILE,
       OPT_BLOCK_LENGTH,
       OPT_GENE_TREE,
       OPT_CMD_SIM_GIVEN_TREE,
       OPT_CMD_SIM_GIVEN_RECTREE,
       OPT_NUMBER_DATA,
       OPT_OUTPUT_FILE,
       OPT_CLONALTREE_FILE,
       OPT_LOCALTREE_FILE,
       OPT_INCLUDE_ANCESTRAL_MATERIAL,
       OPT_CMD_SIM,
       OPT_CMD_MCMC,
       OPT_CMD_SUMP
     };

CSimpleOpt::SOption g_rgOptions[] =
{
  // ID       TEXT          TYPE
  {
    OPT_NUM_ISOLATES,
    "-N", SO_REQ_SEP
  }, // "-N ARG"
  {
    OPT_THETA,
    "-T", SO_REQ_SEP
  }, // "-T ARG"
  {
    OPT_RHO,
    "-R", SO_REQ_SEP
  }, // "-R ARG"
  {
    OPT_DELTA,
    "-D", SO_REQ_SEP
  }, // "-D ARG"
  {
    OPT_LENGTH_FRAGMENT,
    "-B", SO_REQ_SEP
  }, // "-B ARG"
  {
    OPT_RANDOM,
    "-s", SO_REQ_SEP
  }, // "-s ARG"
  {
    OPT_BLOCK_FILE,
    "--block-file", SO_REQ_SEP
  }, // "--block-file ARG"
  {
    OPT_OUT_FILE,
    "--out-file", SO_REQ_SEP
  }, // "--out-file ARG"
  {
    OPT_TREE_FILE,
    "--tree-file", SO_REQ_SEP
  }, // "--tree-file ARG"
  {
    OPT_XMFA_FILE,
    "--xmfa", SO_REQ_SEP
  }, // "--xml ARG"
  {
    OPT_XML_FILE,
    "--xml-file", SO_REQ_SEP
  }, // "--xml-file ARG"
  {
    OPT_NUMBER_DATA,
    "--number-data", SO_REQ_SEP
  }, // "--number-data ARG"
  {
    OPT_OUTPUT_FILE,
    "-o", SO_REQ_SEP
  }, // "-o ARG"
  {
    OPT_CLONALTREE_FILE,
    "-c", SO_REQ_SEP
  }, // "-c ARG"
  {
    OPT_LOCALTREE_FILE,
    "-l", SO_REQ_SEP
  }, // "-l ARG"
  {
    OPT_BLOCK_LENGTH,
    "--block-length", SO_REQ_SEP
  },    // "-a"
  {
    OPT_GENE_TREE,
    "--gene-tree", SO_NONE
  },    // "-a"
  {
    OPT_CMD_SIM_GIVEN_TREE,
    "--cmd-sim-given-tree", SO_NONE
  },    // "-a"
  {
    OPT_CMD_SIM_GIVEN_RECTREE,
    "--cmd-sim-given-rectree", SO_NONE
  },    // "-a"
  {
    OPT_INCLUDE_ANCESTRAL_MATERIAL,
    "-a", SO_NONE
  },    // "-a"
  {
    OPT_HELP,
    "-h", SO_NONE
  },    // "-h"
  {
    OPT_HELP,
    "--help", SO_NONE
  },// "--help"
  {
    OPT_VERSION,
    "--version", SO_NONE
  },// "--version"
  {
    OPT_VERSION,
    "-V", SO_NONE
  },// "-V"
  { OPT_CMD_MCMC, "mcmc", SO_NONE },
  { OPT_CMD_SIM, "sim", SO_NONE },
  { OPT_CMD_SUMP, "sump", SO_NONE },
  SO_END_OF_OPTIONS     // END
};

using namespace weakarg;

int main(int argc, char *argv[])
{
  bool cmdMcmc = false;
  bool cmdSim = false;
  bool cmdSump = false;
  unsigned long seed = 0;
  string xmfaFile("in.xmfa");
  vector<string> inputfiles;

  // Print the help message without any arguments.
  if (argc == 1)
    {
      ShowUsage();
      return 0;
    }

  // Parsing a command and its options.
  CSimpleOpt args(argc, argv, g_rgOptions);
  while (args.Next())
    {
      if (args.LastError() == SO_SUCCESS)
        {
          switch (args.OptionId())
            {
            case OPT_HELP:
              ShowUsage();
              return 0;
              break;
            case OPT_VERSION:
              printVersion();
              return 0;
              break;
            case OPT_CMD_SIM: cmdSim = true; break;
            case OPT_CMD_MCMC: cmdMcmc = true; break;
            case OPT_CMD_SUMP: cmdSump = true; break;
            case OPT_RANDOM: 
              seed = strtoul(args.OptionArg(),NULL,10);
              break;
            case OPT_XMFA_FILE: 
              xmfaFile = string (args.OptionArg());
              break;
            }
        }
      else
        {
          // handle error (see the error codes - enum ESOError)
          printf ("Invalid argument: %s\n", args.OptionText());
          return 1;
        }
    }

  // Check if there is a single command.
  unsigned int checkSingleCommand = 0;
  if (cmdSim == true) checkSingleCommand++; 
  if (cmdMcmc == true) checkSingleCommand++; 
  if (cmdSump == true) checkSingleCommand++; 
  if (checkSingleCommand != 1)
    {
      cerr << "One command must be given among sim, mcmc, and sump." << endl;
      return 1;
    }

  // Run one command.
  if (cmdSim == true)
    {
      cout << "Command Sim is executed ..." << endl;
    }
  else if (cmdMcmc == true)
    {
      cout << "Command MCMC is executed ..." << endl;
      runCommandMcmc (seed, xmfaFile);
    }
  else if (cmdSump == true)
    {
      cout << "Command Sump is executed ..." << endl;
    }
}

int runCommandMcmc (unsigned long seed,
                    string& datafile)
{
  makerng(true);
  seed = seedrng(seed);
  cout << "seed: " << seed << endl
       << "xmfa: " << xmfaFile << endl;

  Param p;
  RecTree* rectree = NULL;
  Data* data = NULL;
  bool readparams = false;
  vector<string> inputfiles;
  try
    {
      readparams = initializeTree(data,rectree,inputfiles,datafile);// initialises data and rectree! (passed by reference)
    }
  catch(char *x)
    {
      cout<<x<<endl;
    }
  if(data==NULL)
    {
      cerr<<"Error: No Data initialised.  Was there a problem with the input file?"<<endl;
      exit(0);
    }
  if(rectree==NULL)
    {
      cerr<<"Error: No Rectree initialised.  Was there a problem with the input file?"<<endl;
      exit(0);
    }
  p = Param(rectree,data);
  p.setRho(0);
  if(readparams)
    {
      p.readProgramOptions();
      WargXml infile(inputfiles[0]);
      p.readParamsFromFile(&infile);
    }
}

int runCommandSim ()
{

}

int runCommandSump ()
{

}

namespace weakarg
{

RecTree * makeGreedyTree(Data * data,WargXml * infile,vector< vector<double> >  * sumdetails,int *count,vector<double> * pars,vector<double> *sumdists)
{
  vector< vector<double> > tmpmut;
  RecTree * rectree=NULL;
  Param *p=NULL;
  infile->restart();
  std::streampos sp=infile->tellg(),lastsp=sp;
  for(unsigned int i=0; i<sumdetails->size(); i++) for(unsigned int j= 0; j<sumdetails->at(i).size(); j++)sumdetails->at(i)[j]*=(double)(*count);
  for(unsigned int i=0; i<pars->size(); i++) pars->at(i)*=(double)(*count);
  while(!infile->eof() && sp>=0)
    {
      sp=infile->gotoLineContaining("<Iteration>",false);
      if(infile->eof() || sp<0) break;
      infile->seekg(sp);
      if(rectree!=NULL) delete(rectree);
      try
        {
          rectree=new RecTree(data->getL(),infile);
          lastsp=sp;
          if(p!=NULL) delete(p);
          p= new Param(rectree,data);
          p->setRho(0);
          p->readProgramOptions();
          p->readParamsFromFile(infile,sp);
          vector< vector<double> > * mutpairwise=p->greedyPairwiseDetails();
          pars->at(0) += p->empiricalRho();
          pars->at(1) += p->empiricalDelta();
          pars->at(2) += p->empiricalTheta(mutpairwise);

          if(sumdetails->size()==0)
            {
              for(unsigned int i=0; i<mutpairwise->size(); i++) sumdetails->push_back(mutpairwise->at(i));
              (*count)=1;
            }
          else
            {
              for(unsigned int i=0; i<sumdetails->size(); i++) for(unsigned int j=0; j<sumdetails->at(i).size(); j++) sumdetails->at(i)[j]+=mutpairwise->at(i)[j];
              (*count)++;
            }
          sp=infile->gotoLineContaining("</Iteration>",false);
          infile->seekg(sp);
        }
      catch(char * x)
        {
          cerr<<"Error making greedy tree: "<<x<<endl;
          exit(0);
        }
    }
  for(unsigned int i=0; i<sumdetails->size(); i++) for(unsigned int j= 0; j<sumdetails->at(i).size(); j++)sumdetails->at(i)[j]/=(double)(*count);
  for(unsigned int i=0; i<pars->size(); i++) pars->at(i)/=(double)(*count);

  *sumdists = vector<double>(p->greedyCalcDists(sumdetails->at(1),sumdetails->at(0)));
  p->greedyApply(*sumdists);
  delete(p);
  infile->clear();
  infile->seekg(lastsp);
  return(rectree);
}


vector<double> readInputFiles(Data* &data, RecTree* &rectree,vector<double> &sumdists,vector<int> &keepregions,vector<int> &previousL,vector<string> inputfiles,string datafile,int greedystage)
{
  bool setregions=false;
  if(opt().subset.size()>0 || opt().subsetSeed !=-1) setregions=true;
  vector <vector<double> >sumdetails;
  vector<double>pars(3,0.0); // parameters
  int counts=0;// counts for the parameters

  dlog(1)<<"Loading data: "<<datafile<<endl;
  for(unsigned int c1=0; c1<inputfiles.size(); c1++)
    {
      if(data!=NULL)
        {
          delete(data);
        }
      data=new Data(datafile); // we have to keep reloading the data
      dlog(1)<<"Loading tree "<<c1<<"... "<<inputfiles[c1]<<endl;
      string treefile=inputfiles[c1];
      WargXml infile(treefile);
      if(infile.isempty())
        {
          cerr<<"Warning: file "<<treefile<<" is empty. Skipping."<<endl;
          continue;
        }
      if(infile.gotoLineContaining("<Iteration>",true)<0)  // is a newick file
        {
          if(inputfiles.size()>1)
            {
              cerr<<"Warning: multiple newick files given.  Only the final one will be used"<<endl;
            }
          data->subset(opt().subset,opt().subsetSeed);// apply the subset as provided on the command line
          rectree=new RecTree(data->getL(),treefile);
        }
      else  // is an xml output file
        {
          if(opt().subset.size()>0) data->subset(opt().subset,opt().subsetSeed);
          else data->readRegionsFromFile(&infile);
          if(greedystage!=2)  // second pass
            {
              previousL.push_back(previousL.back()+data->getL());
              for(unsigned int c2=0; c2<data->getRegions()->size(); c2++) 	keepregions.push_back(data->getRegions()->at(c2));
            }
          if(greedystage==0)  // not greedy
            {
              if(rectree!=NULL) delete(rectree);
              rectree=new RecTree(data->getL(),&infile);
            }
          else if(greedystage==1)  // get the dists for a greedy tree
            {
              if(rectree!=NULL) delete(rectree);
              rectree=makeGreedyTree(data,&infile,&sumdetails,&counts,&pars,&sumdists);
            }
          else if(greedystage==2)  // construct a final iteration from all input files
            {
              if(rectree!=NULL && c1==0) delete(rectree);
              if(c1==0) rectree=new RecTree(previousL.back(),&infile,false);
              rectree->addEdgesFromFile(&infile,previousL[c1]);
            }
        }
    }
  return(pars);
}

bool initializeTree(Data* &data, RecTree* &rectree,vector<string> inputfiles,string datafile)
{
  vector<double>pars(3,0.0);
  vector<double> sumdists;
  vector<int> keepregions;
  vector<int> previousL(1,0);// List of partial L's; starts with just 0
  bool  readparams=false;

  if(opt().greedyWeight<0)  // create a greedy tree from the input
    {
      pars=readInputFiles(data,rectree,sumdists,keepregions,previousL,inputfiles,datafile,1);
      readInputFiles(data,rectree,sumdists,keepregions,previousL,inputfiles,datafile,2);
    }
  else  // just read in the input and keep the specified regions
    {
      if(inputfiles.size()>1) cerr<<"Warning: multiple input files specified but this is only purposeful with the -G -1 option. Ignoring all but the final one."<<endl;
      pars=readInputFiles(data,rectree,sumdists,keepregions,previousL,inputfiles,datafile,0);
    }
  for(unsigned int i=0; i<pars.size(); i++) if(pars[i]!=0) readparams=true;

  if(data!=NULL)
    {
      delete(data);
    }
  data=new Data(datafile); // we have to keep reloading the data
  data->subset(keepregions,-1);// apply the subset of all data we've seen
  Param * p= new Param(rectree,data);
  if(readparams) p->setTheta(pars[2]);
  p->setRho(pars[0]);
  p->setDelta(pars[2]);
  if(opt().greedyWeight<0) p->greedyApply(sumdists);
  delete(p);
  return(readparams);
}


}
