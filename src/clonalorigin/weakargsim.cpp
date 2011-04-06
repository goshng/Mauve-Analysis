/** \file weakargsim.cpp
 * The main source file for simulating under ClonalOrigin model. 
 * This is the main source file for the project of simulating data under
 * ClonalOrigin model. 
 */
#ifdef HAVE_CONFIG_H
#include "config.h"
#endif

#include "rectree.h"
#include "param.h"
#include "move.h"
#include "data.h"
#include "rng.h"
#include <cstring>
#include <fstream>
#include "mpiutils.h"
#include "weakarg.h"
#include "wargxml.h"

#include <cstdlib>
#include "SimpleOpt.h"


using namespace std;
namespace weakarg
{
bool initializeTree(Data* &datap, RecTree* &rectree,vector<string> inputfiles,string datafile);///< initialises the rectree based on the inputfiles specified.
RecTree * makeGreedyTree(Data * data,WargXml * infile,vector< vector<double> >  * sumdetails,int *count,vector<double> * pars,vector<double> *sumdists);///< makes a greeedy "best tree" from a previous warg run
vector<double> readInputFiles(Data* &data, RecTree* &rectree,vector<double> &sumdists,vector<int> &keepregions,vector<int> &previousL,vector<string> inputfiles,string datafile,int greedystage);///< Reads the input files and processes them according to the stage of the input procedure.

ProgramOptions& opt() {
    static ProgramOptions po;	// define a single instance of ProgramOptions per process.
    return po;
}


} // end namespace weakarg

string getVersion() {
    string ret;
#ifdef PACKAGE_STRING
    ret.append(PACKAGE_STRING);
#else
    ret.append("warg");
#endif
    ret.append(" build date ");
    ret.append(__DATE__);
    ret.append(" at ");
    ret.append(__TIME__);
    return(ret);
}

void printVersion() {
    cout<<getVersion()<<endl;
}

using namespace weakarg;
// main function goes outside the weakarg namespace so that
// the linker can find it

static const char * help=
    "\
    Usage: weakargsim [OPTIONS] treefile datafile outputfile\n\
    \n\
    Options:\n\
    -w NUM      	Sets the number of pre burn-in iterations (default is 100000)\n\
    -N NUM        Sets the number of isolates (the default is 100)\n\
    -T NUM        Sets the value of theta, the scaled mutation rate (the default is 100)\n\
    -R NUM        Sets the value of rho, the scaled recombination rate (the default is 100)\n\
    -D NUM        Sets the value of delta, the mean size of imports (the default is 500)\n\
    -B NUM,...    Sets the number and length of the fragments (the default is 400,400,400,400,400,400,400)\n\
    -C T,N        Sets the population size constant and equal to N before time T (cf. below)\n\
    -E T,R        Sets the population size exponentially growing with rate R before time T (cf. below)\n\
    -s NUM        Use the given seed to initiate random number generator\n\ 
                  (by default the seed is generated from /dev/urandom on\n\
                  Linux systems and from the clock on Windows systems)\n\
    -o FILE       Export the data to the given file in XMFA format (cf. below)\n\
    -c FILE       Export the clonal genealogy to the given file in the Newick format (cf. below)\n\
    -l FILE       Export the local trees to the given file in the seq-gen format (cf. below)\n\
    -d FILE       Export the graph of ancestry as a DOT graph to the given file (cf. below)\n\
    -a            Include the ancestral material in the DOT graph (cf. below)\n\
    -i NUM,...,NUM	Set the SIX parameters for creating random Recombination Trees\n\
			under the inference model.  The parameters are:\n\
    	N	(integer)	The number of sequences in the sample (default 10)\n\
    	n_B	(integer)	The number of block boundaries in the sample (default 8)\n\
    	l_B	(integer)	The length of each block: L=n_B * l_B (default 500)\n\
    	delta	(real)		The average length of imports (default 500.0)\n\
    	theta	(real)		The mutation rate NOT per site (default 100.0)\n\
    	rho	(real)		The recombination rate NOT per site (default 50.0)\n\
    -v          	Verbose mode\n\
    -h          	This help message\n\
    -V          	Print Version info\n\
    ";

/**
 * Command line options.
 * A header file SimpleOpt.h is used to parse the command line of the program.
 */
enum { OPT_HELP,
       OPT_NUM_ISOLATES,
       OPT_THETA,
       OPT_RHO,
       OPT_DELTA,
       OPT_LENGTH_FRAGMENT,
       OPT_RANDOM,
       OPT_OUTPUT_FILE,
       OPT_CLONALTREE_FILE,
       OPT_LOCALTREE_FILE,
       //OPT_DOT_FILE,
       OPT_INCLUDE_ANCESTRAL_MATERIAL };

/**
 * Command line options.
 * A header file SimpleOpt.h is used to parse the command line of the program.
 */
CSimpleOpt::SOption g_rgOptions[] = {
    // ID       TEXT          TYPE
    { OPT_NUM_ISOLATES, 
      "-N", SO_REQ_SEP }, // "-N ARG"
    { OPT_THETA,
      "-T", SO_REQ_SEP }, // "-T ARG"
    { OPT_RHO,
      "-R", SO_REQ_SEP }, // "-R ARG"
    { OPT_DELTA,
      "-D", SO_REQ_SEP }, // "-D ARG"
    { OPT_LENGTH_FRAGMENT, 
      "-B", SO_REQ_SEP }, // "-B ARG"
    { OPT_RANDOM, 
      "-s", SO_REQ_SEP }, // "-s ARG"
    { OPT_OUTPUT_FILE, 
      "-o", SO_REQ_SEP }, // "-o ARG"
    { OPT_CLONALTREE_FILE, 
      "-c", SO_REQ_SEP }, // "-c ARG"
    { OPT_LOCALTREE_FILE, 
      "-l", SO_REQ_SEP }, // "-l ARG"
    //{ OPT_DOT_FILE, 
      //"-d", SO_REQ_SEP }, // "-d ARG"
    { OPT_INCLUDE_ANCESTRAL_MATERIAL, 
      "-a", SO_NONE },    // "-a"
    { OPT_HELP, 
      "-h", SO_NONE },    // "-h"
    { OPT_HELP, 
      "--help", SO_NONE },// "--help"
    SO_END_OF_OPTIONS     // END
};

int main(int argc, char *argv[])
{
    string comment="Command line: ";
    for(int c1=0; c1< argc; c1++) {
        comment.append(argv[c1]);
        comment.append(" ");
    }
    comment.append("\nVersion: ");
    comment.append(getVersion());
    vector<string> inputfiles;
    initmpi(argc,argv);
    makerng(true);
    //optind=0;
    bool upgma=false;
    int c;
    char * pch;
    double simparrho=50.0;
    double simpartheta=100.0;
    double simpardelta=500.0;
    int simparN=10;
    int simparnumblocks=8;
    int simparblocksize=500;
    std::stringstream ss;
    unsigned long seed=0;
    bool readparams=false;
    bool setregions=false;

  int n = 5; 
  double theta = 100.0;
  double rho = 100.0;
  double delta = 500; 
  string blockArg("400,400,400");
  int randomSeed = -1;
  const char * dataFilename = "1.fa";
  const char * localtreeFilename = "1lt.tre";
  const char * globaltreeFilename = "1gt.tre";
  const char * dotFilename = "1.dot";
  bool includeAncestralMaterial = false; 

  CSimpleOpt args(argc, argv, g_rgOptions);
  while (args.Next()) {
    if (args.LastError() == SO_SUCCESS) {
      switch (args.OptionId())
      {
        case OPT_HELP:
          ShowUsage();
          return 0;
          break;
        case OPT_NUM_ISOLATES:
          simparN = strtol (args.OptionArg(), NULL, 10);
          break;
        case OPT_THETA:
          simpartheta = strtod (args.OptionArg(), NULL);
          break;
        case OPT_RHO:
          simparrho = strtod (args.OptionArg(), NULL);
          break;
        case OPT_DELTA:
          simpardelta = strtol (args.OptionArg(), NULL, 10);
          break;
        case OPT_LENGTH_FRAGMENT:
          blockArg = args.OptionArg();
          break;
        case OPT_RANDOM:
          randomSeed = strtol (args.OptionArg(), NULL, 10);
          break;
        case OPT_OUTPUT_FILE:
          dataFilename = args.OptionArg();
          break;
        case OPT_CLONALTREE_FILE:
          globaltreeFilename = args.OptionArg();
          break;
        case OPT_LOCALTREE_FILE:
          localtreeFilename = args.OptionArg();
          break;
        case OPT_DOT_FILE:
          dotFilename = args.OptionArg();
          break;
        case OPT_INCLUDE_ANCESTRAL_MATERIAL:
          includeAncestralMaterial = true;
          break;
      }
    }
    else {
      // handle error (see the error codes - enum ESOError)
      printf ("Invalid argument: %s\n", args.OptionText());
      return 1;
    }
  }


    while ((c = getopt (argc, argv, "w:x:y:z:s:va:T:R:D:L:C:r:t:i:S:G:fUhV")) != -1)
        switch (c)
        {
        case('w'):
            if(atoi(optarg)>=0)opt().preburnin=atoi(optarg);
            break;
        case('x'):
            if(atoi(optarg)>=0)opt().burnin=atoi(optarg);
            break;
        case('y'):
            if(atoi(optarg)>=0)opt().additional=atoi(optarg);
            break;
        case('z'):
            if(atoi(optarg)> 0)opt().thinin=atoi(optarg);
            break;
        case('T'):
            opt().theta=atof(optarg);
            if (optarg[0]=='s') {
                opt().theta=atof(optarg+1);
                opt().thetaPerSite=true;
            };
            break;
        case('R'):
            opt().rho=atof(optarg);
            if (optarg[0]=='s') {
                opt().rho=atof(optarg+1);
                opt().rhoPerSite=true;
            };
            break;
        case('D'):
            opt().delta=atof(optarg);
            break;
        case('s'):
            seed=strtoul(optarg,NULL,10);
            break;
        case('v'):
            opt().verbose=true;
            break;
        case('f'):
            opt().allowclonal=false;
            break;
        case('U'):
            upgma=true;
            break;
        case('a'):
            pch = strtok (optarg,",");
            for(int i=0; i<NUMMOVES; i++) {
                if(pch==NULL) {
                    cout<<"Wrong -a string."<<endl<<help<<endl;
                    return 1;
                }
                opt().movep[i]=fabs(atof(pch));
                pch = strtok (NULL, ",");
            };
            break;
        case('i'):
            pch = strtok (optarg,",");
            for(int i=0; i<6; i++) {
                if(pch==NULL) {
                    cout<<"Wrong -i string."<<endl<<help<<endl;
                    return 1;
                }
                switch(i) {
                case(0):
                    simparN=atoi(pch);
                    break;
                case(1):
                    simparnumblocks=atoi(pch);
                    break;
                case(2):
                    simparblocksize=atoi(pch);
                    break;
                case(3):
                    simpardelta=fabs(atof(pch));
                    break;
                case(4):
                    simpartheta=fabs(atof(pch));
                    break;
                case(5):
                    simparrho=fabs(atof(pch));
                    break;
                case '?':
                    cout<<"Wrong -i string."<<endl<<help<<endl;
                    return 1;
                }
                pch = strtok (NULL, ",");
            };
            break;
        case('r'):
            opt().temperreps=atoi(optarg);
            break;
        case('t'):
            opt().temperT=atof(optarg);
            break;
        case('L'):
            opt().logfile=optarg;
            break;
        case('C'):
            opt().csvoutfile=optarg;
            break;
        case('V'):
            printVersion();
            return 0;
        case('S'):
            pch= strrchr (optarg,',');
            if(pch!=NULL) {
                pch = strtok (optarg,",");
                opt().subset.push_back(atoi(pch));
                pch = strtok (NULL,",");
                opt().subsetSeed=atoi(pch);
            } else {
                pch = strtok (optarg,"/");
                while (pch != NULL) {
                    opt().subset.push_back(atoi(pch));
                    pch = strtok (NULL, "/");
                }
            }
            setregions=true;
            break;
        case('G'):
            opt().greedyWeight=atof(optarg);
            break;
        case('h'):
            cout<<help<<endl;
            return 0;
        case '?':
            cout<<"Wrong arguments: did not recognise "<<c<<" "<<optarg<<endl<<help<<endl;
            return 1;
        default:
            abort ();
        }
    seed=seedrng(seed);// <0 means use /dev/random or clock.
    comment.append("\nSeed: ");
    ss<<seed;
    comment.append(ss.str());
    if (argc-optind==3 || (opt().greedyWeight<0 && argc-optind>3)) {
        while(argc-optind>2) inputfiles.push_back(string(argv[optind++]));
    }
    if (argc-optind!=1 && argc-optind!=2) {
        cout<<"Wrong number of arguments."<<endl<<help<<endl;
        return 1;
    }

    Param p;
    RecTree*rectree=NULL;
    Data*data=NULL;
    if (argc-optind==1) {//Run on simulated tree and data
        dlog(1)<<"Simulating rectree..."<<endl;
        vector<int> blocks;
        for (int i=0; i<simparnumblocks; i++) blocks.push_back(i*simparblocksize);
        rectree=new RecTree(simparN,simparrho,simpardelta,blocks);
        dlog(1)<<"Initiating parameter"<<endl;
        p=Param(rectree,NULL);
        dlog(1)<<"Simulating data..."<<endl;
        p.setTheta(simpartheta);
        p.simulateData(blocks);
        p.setTheta(-1.0);
        data=p.getData();
        ofstream dat;
        dat.open("simulatedData.xmfa");
        data->output(&dat);
        dat.close();
        ofstream tru;
        tru.open("truth.xml");
        p.setRho(simparrho);
        p.setTheta(simpartheta);
        p.exportXMLbegin(tru,comment);
        //p.exportXMLbegin(tru);
        p.exportXMLiter(tru);
        p.exportXMLend(tru);
        tru.close();
        // alternative initialisation options
        //while (p.getRecTree()->numRecEdge()>0) p.getRecTree()->remRecEdge(i);// blank tree
        //for(int i=0;i<p.getRecTree()->numRecEdge();i++) {// remove all but a specific edge	if(p.getRecTree()->getRecEdge(i)->getEdgeTo()!=28) {p.getRecTree()->remRecEdge(i);i--;} }
    } else if(argc-optind==2 && inputfiles.size()==0) { //Load data from files
        string datafile=string(argv[optind++]);
        dlog(1)<<"Loading data..."<<endl;
        try {
            data=new Data(datafile);
        } catch(const char *) {
            exit(0);
        }
        if (upgma)
        {
            rectree=new RecTree(data,0.0,500.0,*(data->getBlocks()));
            data->subset(opt().subset,opt().subsetSeed);
        } else {
            data->subset(opt().subset,opt().subsetSeed);
            dlog(1)<<"Creating random tree..."<<endl;
            rectree=new RecTree(data->getN(),0.0,500.0,*(data->getBlocks()));
        }
        dlog(1)<<"Initiating parameter..."<<endl;
        p=Param(rectree,data);
        p.setRho(0);
    } else { //Load tree and data from files
        string datafile=string(argv[optind++]);
        try {
            readparams=initializeTree(data,rectree,inputfiles,datafile);// initialises data and rectree! (passed by reference)
        } catch(char *x) {
            cout<<x<<endl;
        }
        if(data==NULL) {
            cerr<<"Error: No Data initialised.  Was there a problem with the input file?"<<endl;
            exit(0);
        }
        if(rectree==NULL) {
            cerr<<"Error: No Rectree initialised.  Was there a problem with the input file?"<<endl;
            exit(0);
        }
        dlog(1)<<"Initiating parameter..."<<endl;
        p=Param(rectree,data);
        p.setRho(0);
        if(readparams) {
            p.readProgramOptions();
            WargXml infile(inputfiles[0]);
            p.readParamsFromFile(&infile);
        }
    }
    opt().outfile = argv[optind++];

    if(opt().preburnin>0 && (opt().movep[8]>0 || opt().movep[10]>0)) {
        cout<<"Starting Pre-burnin Metropolis-Hastings algorithm.."<<endl;
        double rho=opt().rho;
        opt().rho=0;
        long int burnin= opt().burnin, additional=opt().additional,temperreps=opt().temperreps;
        opt().burnin=opt().preburnin;
        opt().additional=0;
        p.readProgramOptions();
        p.metropolis(comment);
        opt().burnin=burnin;
        opt().additional=additional;
        opt().rho=rho;
        opt().temperreps=temperreps;
        p.readProgramOptions();
    } else if(!readparams) p.readProgramOptions();
    cout<<"Starting Metropolis-Hastings algorithm............."<<endl;
    p.metropolis(comment);

    dlog(1)<<"Cleaning up..."<<endl;
    if(p.getRecTree()) delete(p.getRecTree());
    if(data) delete(data);
    gsl_rng_free(rng);

    endmpi();
    return 0;
}

void ShowUsage() {
  cout << help << endl;
}

int
main (int argc, char * argv[]) 
{
  int n = 5; 
  double theta = 100.0;
  double rho = 100.0;
  double delta = 500; 
  string blockArg("400,400,400");
  int randomSeed = -1;
  const char * dataFilename = "1.fa";
  const char * localtreeFilename = "1lt.tre";
  const char * globaltreeFilename = "1gt.tre";
  const char * dotFilename = "1.dot";
  bool includeAncestralMaterial = false; 

  CSimpleOpt args(argc, argv, g_rgOptions);
  while (args.Next()) {
    if (args.LastError() == SO_SUCCESS) {
      switch (args.OptionId())
      {
        case OPT_HELP:
          ShowUsage();
          return 0;
          break;
        case OPT_NUM_ISOLATES:
          n = strtol (args.OptionArg(), NULL, 10);
          break;
        case OPT_THETA:
          theta = strtod (args.OptionArg(), NULL);
          break;
        case OPT_RHO:
          rho = strtod (args.OptionArg(), NULL);
          break;
        case OPT_DELTA:
          delta = strtol (args.OptionArg(), NULL, 10);
          break;
        case OPT_LENGTH_FRAGMENT:
          blockArg = args.OptionArg();
          break;
        case OPT_RANDOM:
          seed = strtoul (args.OptionArg(), NULL, 10);
          break;
        case OPT_OUTPUT_FILE:
          opt().outfile = args.OptionArg();
          break;
        case OPT_CLONALTREE_FILE:
          opt().treefile = args.OptionArg();
          break;
        case OPT_LOCALTREE_FILE:
          opt().localtreefile = args.OptionArg();
          break;
        //case OPT_DOT_FILE:
          //dotFilename = args.OptionArg();
          //break;
        case OPT_INCLUDE_ANCESTRAL_MATERIAL:
          includeAncestralMaterial = true;
          break;
      }
    }
    else {
      // handle error (see the error codes - enum ESOError)
      printf ("Invalid argument: %s\n", args.OptionText());
      return 1;
    }
  }

/*
  printf ("n = %d\n", n);
  printf ("theta = %lf\n", theta);
  printf ("rho = %lf\n", rho);
  printf ("delta = %lf\n", delta);
  printf ("block = %s\n", blockArg.c_str());
  printf ("data file = %s\n", dataFilename);
  printf ("local tree file = %s\n", localtreeFilename);
  printf ("global tree file = %s\n", globaltreeFilename);
  printf ("dot file = %s\n", dotFilename);
  printf ("anc = %d\n", includeAncestralMaterial); 
*/

  if (randomSeed == -1) {
    makerng(); 
  } else {
    rng=gsl_rng_alloc(gsl_rng_default);
    gsl_rng_set(rng, randomSeed);
  }

  vector<int> blocks=Arg::makeBlocks(blockArg);
  PopSize * popsize=NULL;

  //Interpret population size model

  //if (popsize!=NULL) popsize->show();
  //Build the ARG
  Arg * arg=new Arg(n,rho,delta,blocks,popsize);
  //Build the data and export it
  if (1) {
      Data * data=arg->drawData(theta);
      ofstream dat;
      dat.open(dataFilename);
      data->output(&dat);
      dat.close();
      delete(data);
    }
  //Extract the local trees and export them
  if (1) {
      ofstream lf;
      lf.open(localtreeFilename);
      arg->outputLOCAL(&lf);
      lf.close();
    }
  //Extract the clonal genealogy and export it
  if (1) {
      string truth=arg->extractCG();
      ofstream tru;
      tru.open(globaltreeFilename);
      tru<<truth<<endl;
      tru.close();
    }
  //Export to DOT format
  if (1) {
      ofstream dot;
      dot.open(dotFilename);
      arg->outputDOT(&dot,true);
      dot.close();
    }
  delete(arg);
  cout << "Simulate!\n";
}
///////////////////////////////////////////////////////////////////////


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
    while(!infile->eof() && sp>=0) {
        sp=infile->gotoLineContaining("<Iteration>",false);
        if(infile->eof() || sp<0) break;
        infile->seekg(sp);
        if(rectree!=NULL) delete(rectree);
        try {
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

            if(sumdetails->size()==0) {
                for(unsigned int i=0; i<mutpairwise->size(); i++) sumdetails->push_back(mutpairwise->at(i));
                (*count)=1;
            } else {
                for(unsigned int i=0; i<sumdetails->size(); i++) for(unsigned int j=0; j<sumdetails->at(i).size(); j++) sumdetails->at(i)[j]+=mutpairwise->at(i)[j];
                (*count)++;
            }
            sp=infile->gotoLineContaining("</Iteration>",false);
            infile->seekg(sp);
        } catch(char * x) {
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
    for(unsigned int c1=0; c1<inputfiles.size(); c1++) {
        if(data!=NULL) {
            delete(data);
        }
        data=new Data(datafile); // we have to keep reloading the data
        dlog(1)<<"Loading tree "<<c1<<"... "<<inputfiles[c1]<<endl;
        string treefile=inputfiles[c1];
        WargXml infile(treefile);
        if(infile.isempty()) {
            cerr<<"Warning: file "<<treefile<<" is empty. Skipping."<<endl;
            continue;
        }
        if(infile.gotoLineContaining("<Iteration>",true)<0) {// is a newick file
            if(inputfiles.size()>1) {
                cerr<<"Warning: multiple newick files given.  Only the final one will be used"<<endl;
            }
            data->subset(opt().subset,opt().subsetSeed);// apply the subset as provided on the command line
            rectree=new RecTree(data->getL(),treefile);
        } else { // is an xml output file
            if(opt().subset.size()>0) data->subset(opt().subset,opt().subsetSeed);
            else data->readRegionsFromFile(&infile);
            if(greedystage!=2) { // second pass
                previousL.push_back(previousL.back()+data->getL());
                for(unsigned int c2=0; c2<data->getRegions()->size(); c2++) 	keepregions.push_back(data->getRegions()->at(c2));
            }
            if(greedystage==0) {// not greedy
                if(rectree!=NULL) delete(rectree);
                rectree=new RecTree(data->getL(),&infile);
            } else if(greedystage==1) { // get the dists for a greedy tree
                if(rectree!=NULL) delete(rectree);
                rectree=makeGreedyTree(data,&infile,&sumdetails,&counts,&pars,&sumdists);
            } else if(greedystage==2) { // construct a final iteration from all input files
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

    if(opt().greedyWeight<0) {// create a greedy tree from the input
        pars=readInputFiles(data,rectree,sumdists,keepregions,previousL,inputfiles,datafile,1);
        readInputFiles(data,rectree,sumdists,keepregions,previousL,inputfiles,datafile,2);
    } else { // just read in the input and keep the specified regions
        if(inputfiles.size()>1) cerr<<"Warning: multiple input files specified but this is only purposeful with the -G -1 option. Ignoring all but the final one."<<endl;
        pars=readInputFiles(data,rectree,sumdists,keepregions,previousL,inputfiles,datafile,0);
    }
    for(unsigned int i=0; i<pars.size(); i++) if(pars[i]!=0) readparams=true;

    if(data!=NULL) {
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
