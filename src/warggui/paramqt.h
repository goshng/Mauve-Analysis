#ifndef PARAMQT_H
#define PARAMQT_H
//
#include <gsl/gsl_math.h>
#include "../warg/src/param.h"
//
using namespace weakarg;
using namespace std;
#include <string>
#include <vector>

namespace Daniweb
{
    using namespace std;

    typedef string::size_type (string::*find_t)(const string& delim, 
                                                string::size_type offset) const;

    /// <summary>
    /// Splits the string s on the given delimiter(s) and
    /// returns a list of tokens without the delimiter(s)
    /// </summary>
    /// <param name=s>The string being split</param>
    /// <param name=match>The delimiter(s) for splitting</param>
    /// <param name=removeEmpty>Removes empty tokens from the list</param>
    /// <param name=fullMatch>
    /// True if the whole match string is a match, false
    /// if any character in the match string is a match
    /// </param>
    /// <returns>A list of tokens</returns>
    vector<string> Split(const string& s,
                         const string& match,
                         bool removeEmpty=false,
                         bool fullMatch=false);
}

class ParamQt : public Param
{
public:

  ParamQt();
  ~ParamQt();
  inline void setTreeData(RecTree * t, string &strblocks)
  {
    delete(rectree);
    rectree=t;
    if (data==NULL)
      {
        vector<int> blocks;
        vector<string> blocksString = Daniweb::Split (strblocks, ",");
        for (int i = 0; i < blocksString.size(); i++)
          blocks.push_back(atoi(blocksString[i].c_str()));
        data=new Data(rectree->getN(),blocks);
      }
  }///<Sets the tree
  inline void clearTreeData()
  {
    if(data==NULL) delete(data);
  }
  bool isCons;
  virtual inline void incrTimeScale()
  {
    timeScale*=1.1;
  };
  virtual inline void decrTimeScale()
  {
    timeScale/=1.1;
  };
  inline void setTimeScale(double ts)
  {
    timeScale=ts;
  };
  inline double getRateScale()
  {
    return rateScale;
  }
  inline void setRateScale(double r)
  {
    rateScale=r;
  }
  inline double getTimeScale()
  {
    return timeScale;
  }
  double getRM();
  //inline void clearConv() {convnames.clear();convdata.clear();}
  inline void addConv(string name, double data)
  {
    for(unsigned int i=0; i<convnames.size(); i++)
      {
        if(name.compare(convnames.at(i))==0)
          {
            convdata[i]=data;
            return;
          }
      }
    convnames.push_back(name);
    convdata.push_back(data);
  }
  inline string getConvName(int index)
  {
    if(index>=(int)convnames.size())
      {
        cerr<<"Error in paramqt: index "<<index<<" doesn't exist in convnames"<<endl;
        throw;
      };
    return convnames.at(index);
  }
  inline double getConvData(int index)
  {
    if(index>=(int)convdata.size())
      {
        cerr<<"Error in paramqt: index "<<index<<" doesn't exist in convdata"<<endl;
        throw;
      };
    return convdata.at(index);
  }
  inline int countConv()
  {
    return convdata.size();
  }



  inline void setNumber(long i)
  {
    iteration=i;
  }///* Sets the iteration we are on
  inline long getNumber()
  {
    return(iteration);
  }///* Sets the iteration we are on
  inline void toggleRecView()
  {
    recview++;
    if(recview>=3) recview=0;
  }
  inline void setNameType(int i)
  {
    nametype=i;
  }
  inline void setRecView(int i)
  {
    if(i>=0 &&i<3) recview=i;
  }
  inline int getRecView()
  {
    return(recview);
  }

  double rateScale;
  double timeScale;
  long iteration;
  int recview;
  int labview;
  int nametype;
  vector<double> convdata;// convergence diagnostics
  vector<string> convnames;// convergence diagnostics
  string labels;
  string names;
  void setNames(string qn)
  {
    names=qn;
  }
  void setLabels(string qn)
  {
    labels=qn;
  }
  void makeCF(vector <vector<double> > *v);///<Accounts for clonal frame proportions in v
  int lastCommonAncestor(int s1, int s2);///< Returns the last common ancestor between two individuals
  vector<int>  consistentAgeList(vector<double> *res);///< Returns a list of node ordersthat is consistent if -f option is used, and puts their ages in res
  double pairwiseDistance(int s1, int s2);///<Returns the pairwise distance between sequence s1 and s2
  vector<double> pairwiseDistanceList();///<List of the unique pairwise distances i9n order for(c1=0..N-1 for(c2=c1+1..N-1)).
  vector<vector<double> > pairwiseDistanceMatrix(bool print=false);///< returns a pairwise distance matrix for the current tree
  int recCount(int s1, int s2);///< Gets the number of recombination events from s2 to s1 (or ancestors) before they coalesce
  vector<vector<int> > recCountMatrix(bool print);///< Gets the pairwise count of recombination events
  vector<vector<double> > recPriorMatrix();///< recombination prior matrix, pairwise
};
#endif
