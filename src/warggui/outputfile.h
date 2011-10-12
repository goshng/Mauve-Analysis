#ifndef OUTPUTFILE_H
#define OUTPUTFILE_H
#include <string>
#include "tinyxml.h"
#include "paramqt.h"
#include "../warg/src/param.h"
//
using namespace std;
//
class OutputFile
{
public:
  OutputFile(string &qstrs, bool makeVectors=true);
  inline int getL()
  {
    return blocksInt.at(blocksInt.size()-1);
  }
  inline int getB()
  {
    return blocksInt.size()-1;
  }
  inline string getBlocks()
  {
    return blocks;
  }
  bool getIt(ParamQt * p);
  void startOver();
  void reset();
  inline int getCurIt()
  {
    return currentIteration;
  }
  void addOtherData(string name,double val);
  inline vector<double>*getThetas()
  {
    vector<double> *v=new vector<double>(thetas);
    return v;
  }
  inline vector<double>*getRhos()
  {
    vector<double> *v=new vector<double>(rhos);
    return v;
  }
  inline vector<double>*getDeltas()
  {
    vector<double> *v=new vector<double>(deltas);
    return v;
  }
  inline vector<double>*getLikelihoods()
  {
    vector<double> *v=new vector<double>(likelihoods);
    return v;
  }
  inline vector<double>*getPriors()
  {
    vector<double> *v=new vector<double>(priors);
    return v;
  }
  inline vector<double>*getNumRecEdges()
  {
    vector<double> *v=new vector<double>(numrecedges);
    return v;
  }
  inline vector<double>*getGenoRec()
  {
    vector<double> *v=new vector<double>(genorec);
    return v;
  }
  inline vector<double>*getGenoBeg()
  {
    vector<double> *v=new vector<double>(genobeg);
    return v;
  }
  inline vector<double>*getGenoEnd()
  {
    vector<double> *v=new vector<double>(genoend);
    return v;
  }
  vector<double>*getRhoOverTheta();
  vector<double>*getRoverM(ParamQt*param);
  vector<double>*getRhoPerSite();
  vector<double>*getThetaPerSite();
  vector<double>*getPosteriors();
  vector<double>*getTMRCA()
  {
    vector<double> *v=new vector<double>(tmrcas);
    return v;
  }
  vector<double>*getTTotal()
  {
    vector<double> *v=new vector<double>(ttotals);
    return v;
  }
  inline bool isinitialised()
  {
    return(outputinitialised);
  }
  void countVectors();
  inline string getFileName()
  {
    return("File name is not saved.");
  }
  inline string getComment()
  {
    return(comment);
  }
  void readNames(string str);
  inline string getNames()
  {
    return(names);
  };
  inline void addRegions(string str)
  {
    vector<string> regionsString = Daniweb::Split (str, ",");
    for (int i = 0; i < regionsString.size(); i++)
      regions.push_back(atoi(regionsString[i].c_str()));
  }// adds to the list of regions, keeping the list sorted and unique
  inline vector<int> getRegions()
  {
    return(regions);
  }

protected:
  TiXmlDocument mDoc;
  string comment;
  string blocks;
  vector<int> blocksInt;
  string names;
  string regionsString;

  bool outputinitialised;

  int currentIteration;
  vector<int> previousL;
  vector<double>thetas;
  vector<double>rhos;
  vector<double>deltas;
  vector<double>likelihoods;
  vector<double>priors;
  vector<double>numrecedges;
  vector<double>genorec;
  vector<double>relgenorec;
  vector<double>genobeg;
  vector<double>genoend;
  vector<double>tmrcas;
  vector<double>ttotals;
  vector<int> regions;
};
#endif
