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

#include <limits>
#include <iostream>
#include <iomanip>
#include <cstdlib>
#include "SimpleOpt.h"


using namespace std;
namespace weakarg
{
bool initializeTree(Data* &datap, RecTree* &rectree,vector<string> inputfiles,string datafile);///< initialises the rectree based on the inputfiles specified.
RecTree * makeGreedyTree(Data * data,WargXml * infile,vector< vector<double> >  * sumdetails,int *count,vector<double> * pars,vector<double> *sumdists);///< makes a greeedy "best tree" from a previous warg run
vector<double> readInputFiles(Data* &data, RecTree* &rectree,vector<double> &sumdists,vector<int> &keepregions,vector<int> &previousL,vector<string> inputfiles,string datafile,int greedystage);///< Reads the input files and processes them according to the stage of the input procedure.

/**
 * Reads a l-th line of a file.
 */
string readLine (string& filename, unsigned l = 1);
vector<int> readBlock (string& filename, unsigned b = 0);

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
    --block-file FILE\n\
                  A block file contains numbers delimited by comma,\n\
                  spaces, or newline (default: in.block)\n\
    --tree-file FILE\n\
                  A tree file contains a list of newick formatted strings\n\
                  (default: in.tree)\n\
    --xml-file FILE\n\
                  An XML file contains a list of recedges\n\
    --out-file FILE\n\
                  A base name of output file names. (default: out)\n\
                  For example, an alignment file name is the output \n\
                  file base name suffixed \".xmfa\".\n\
    --gene-tree\n\
                  Gene trees for all of iteration and site are exported.\n\
                  Not random!\n\
    --block-length\n\
                  Length of a block (used with --gene-tree)\n\
    -o FILE       Export the data to the given file in XMFA format\n\
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
    -v            Verbose mode\n\
    -h, --help    This help message\n\
    -V, --version Print Version info\n\
    ";

/**
 * Shows the help message.
 */
void ShowUsage() {
    cout << help << endl;
}

/**
 * Command line options.
 * A header file SimpleOpt.h is used to parse the command line of the program.
 */
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
       OPT_BLOCK_LENGTH,
       OPT_GENE_TREE,
       OPT_NUMBER_DATA,
       OPT_OUTPUT_FILE,
       OPT_CLONALTREE_FILE,
       OPT_LOCALTREE_FILE,
       //OPT_DOT_FILE,
       OPT_INCLUDE_ANCESTRAL_MATERIAL
     };

/**
 * Command line options.
 * A header file SimpleOpt.h is used to parse the command line of the program.
 */
CSimpleOpt::SOption g_rgOptions[] = {
    // ID       TEXT          TYPE
    {   OPT_NUM_ISOLATES,
        "-N", SO_REQ_SEP
    }, // "-N ARG"
    {   OPT_THETA,
        "-T", SO_REQ_SEP
    }, // "-T ARG"
    {   OPT_RHO,
        "-R", SO_REQ_SEP
    }, // "-R ARG"
    {   OPT_DELTA,
        "-D", SO_REQ_SEP
    }, // "-D ARG"
    {   OPT_LENGTH_FRAGMENT,
        "-B", SO_REQ_SEP
    }, // "-B ARG"
    {   OPT_RANDOM,
        "-s", SO_REQ_SEP
    }, // "-s ARG"
    {   OPT_BLOCK_FILE,
        "--block-file", SO_REQ_SEP
    }, // "--block-file ARG"
    {   OPT_OUT_FILE,
        "--out-file", SO_REQ_SEP
    }, // "--out-file ARG"
    {   OPT_TREE_FILE,
        "--tree-file", SO_REQ_SEP
    }, // "--tree-file ARG"
    {   OPT_XML_FILE,
        "--xml-file", SO_REQ_SEP
    }, // "--xml-file ARG"
    {   OPT_NUMBER_DATA,
        "--number-data", SO_REQ_SEP
    }, // "--number-data ARG"
    {   OPT_OUTPUT_FILE,
        "-o", SO_REQ_SEP
    }, // "-o ARG"
    {   OPT_CLONALTREE_FILE,
        "-c", SO_REQ_SEP
    }, // "-c ARG"
    {   OPT_LOCALTREE_FILE,
        "-l", SO_REQ_SEP
    }, // "-l ARG"
    {   OPT_BLOCK_LENGTH,
        "--block-length", SO_REQ_SEP
    },    // "-a"
    {   OPT_GENE_TREE,
        "--gene-tree", SO_NONE
    },    // "-a"
    //{ OPT_DOT_FILE,
    //"-d", SO_REQ_SEP }, // "-d ARG"
    {   OPT_INCLUDE_ANCESTRAL_MATERIAL,
        "-a", SO_NONE
    },    // "-a"
    {   OPT_HELP,
        "-h", SO_NONE
    },    // "-h"
    {   OPT_HELP,
        "--help", SO_NONE
    },// "--help"
    {   OPT_VERSION,
        "--version", SO_NONE
    },// "--version"
    {   OPT_VERSION,
        "-V", SO_NONE
    },// "-V"
    SO_END_OF_OPTIONS     // END
};

/**
 * A species tree is given. Blocks should be given.
 */
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
    string blockFilename = "in.block";
    string treeFilename = "in.tree";
    string xmlFilename = "";
    unsigned long numberData = 1;
    bool includeAncestralMaterial = false;
    opt().outfile = "out";
    char * optarg;
    bool exportGenetree = false;
    int blockLength; 

    //int n = 5;
    //double theta = 100.0;
    //double rho = 100.0;
    //double delta = 500;
    //string blockArg("400,400,400");
    //int randomSeed = -1;
    //const char * dataFilename = "1.fa";
    //const char * localtreeFilename = "1lt.tre";
    //const char * globaltreeFilename = "1gt.tre";
    //const char * dotFilename = "1.dot";
    //bool includeAncestralMaterial = false;

    CSimpleOpt args(argc, argv, g_rgOptions);
    while (args.Next()) {
        if (args.LastError() == SO_SUCCESS) {
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
            case OPT_NUM_ISOLATES:
                simparN = strtol (args.OptionArg(), NULL, 10);
                break;
            case OPT_THETA:
                optarg = args.OptionArg();
                if (optarg[0]=='s') {
                    simpartheta = strtod (optarg + 1, NULL);
                    opt().thetaPerSite=true;
                } else {
                    simpartheta = strtod (optarg, NULL);
                    opt().thetaPerSite=false;
                } 
                break;
            case OPT_RHO:
                optarg = args.OptionArg();
                if (optarg[0]=='s') {
                    simparrho = strtod (optarg + 1, NULL);
                    opt().rhoPerSite=true;
                } else {
                    simparrho = strtod (optarg, NULL);
                    opt().rhoPerSite=false;
                } 
                break;
            case OPT_DELTA:
                simpardelta = strtol (args.OptionArg(), NULL, 10);
                break;
            //case OPT_LENGTH_FRAGMENT:
                //blockArg = args.OptionArg();
                //break;
            case OPT_RANDOM:
                seed = strtoul (args.OptionArg(), NULL, 10);
                break;
            case OPT_BLOCK_FILE:
                blockFilename = args.OptionArg();
                break;
            case OPT_OUT_FILE:
                opt().outfile = args.OptionArg();
                break;
            case OPT_TREE_FILE:
                treeFilename = args.OptionArg();
                break;
            case OPT_XML_FILE:
                xmlFilename = args.OptionArg();
                break;
            case OPT_BLOCK_LENGTH:
                blockLength = strtol (args.OptionArg(), NULL, 10);
                break;
            case OPT_GENE_TREE:
                exportGenetree = true;
                break;
            case OPT_NUMBER_DATA:
                numberData = strtoul (args.OptionArg(), NULL, 10);
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

//std::cerr << "before seed: " << seed << std::endl;
    if (exportGenetree == false) {
      seed=seedrng(seed);// <0 means use /dev/random or clock.
    }
    comment.append("\nSeed: ");
    ss<<seed;
    comment.append(ss.str());

    Param p;
    RecTree* rectree=NULL;
    Data* data=NULL;

    dlog(1)<<"Simulating rectree..."<<endl;
    vector<int> blocks;

    /**
     * A list of lengths of blocks is given.
     */
    int totalLengthBlock;
    if (exportGenetree == false)
    {
        blocks = readBlock (blockFilename);
        totalLengthBlock = blocks.back();
        if (opt().rhoPerSite == true)
        {
            simparrho *= totalLengthBlock;
        }
        if (opt().thetaPerSite == true)
        {
            simpartheta *= totalLengthBlock;
        }
    }
    else
    {
      totalLengthBlock = blockLength;
    }


    if (xmlFilename.length() == 0)
    {
        /**
         * A newick formatted string for a species is given.
         */
        string treeNewick = readLine (treeFilename);
     
        /**
         * A newick formatted string for a species is given.
         */
        treeNewick = readLine (treeFilename);
        rectree=new RecTree(treeNewick, simparrho, simpardelta, blocks);
    }
    else
    {
        WargXml infile(xmlFilename);
        rectree = new RecTree(totalLengthBlock, &infile);
    }

    dlog(1)<<"Initiating parameter"<<endl;
    p=Param(rectree,NULL);

    if (exportGenetree == false)
    {
      dlog(1)<<"Simulating data..."<<endl;
      p.setTheta(simpartheta);
      for (unsigned long i = 1; i <= numberData; i++) 
      {
        p.simulateData(blocks);
        //p.setTheta(-1.0);
        data=p.getData();
        std::stringstream ss;
        ss << "." << i << ".xmfa";

        string dataFilename = opt().outfile + ss.str();

        ofstream dat;
        dat.open(dataFilename.data());
        data->output(&dat);
        dat.close();
      }
      string trueFilename = opt().outfile + ".xml";
      ofstream tru;
      tru.open(trueFilename.data());
      p.setRho(simparrho);
      p.setTheta(simpartheta);
      p.setDelta(simpardelta);
      p.exportXMLbegin(tru,comment);
      p.exportXMLiter(tru);
      p.exportXMLend(tru);
      tru.close();

    }
    else
    {
      // Export gene trees.
      string dataFilename = opt().outfile;
      ofstream dat;
      dat.open(dataFilename.data());
      rectree->rankLocalTree(&dat);
      dat.close();
    }

    dlog(1)<<"Cleaning up..."<<endl;
    if(p.getRecTree()) delete(p.getRecTree());
    if(data) delete(data);
    gsl_rng_free(rng);

    endmpi();
    return 0;
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

string 
readLine (string& filename, unsigned l)
{
    string aline;
    ifstream f(filename.data());
    if (!f) {
        cerr << "Can't open a file " << filename << endl;
        exit (1);
    }
    for (unsigned i = 0; i < l; i++) {
        getline (f, aline);
    }
    f.close();
    return aline;
}

vector<int>
readBlock (string& filename, unsigned b)
{
    vector<int> blocks;
    ifstream f(filename.data());
    if (!f) {
        cerr << "Can't open a file " << filename << endl;
        exit (1);
    }
    int accumulatedBlockSize = 0;
    blocks.push_back(0);
    while (!f.eof()) {
        int i;
        f >> i;
        if (!f.fail()) {
            accumulatedBlockSize += i;
            blocks.push_back(accumulatedBlockSize);
        } 
    }
    f.close();
    return blocks;
}

}
