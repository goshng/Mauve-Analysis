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
                         bool fullMatch=false)
    {
        vector<string> result;                 // return container for tokens
        string::size_type start = 0,           // starting position for searches
                          skip = 1;            // positions to skip after a match
        find_t pfind = &string::find_first_of; // search algorithm for matches

        if (fullMatch)
        {
            // use the whole match string as a key
            // instead of individual characters
            // skip might be 0. see search loop comments
            skip = match.length();
            pfind = &string::find;
        }

        while (start != string::npos)
        {
            // get a complete range [start..end)
            string::size_type end = (s.*pfind)(match, start);

            // null strings always match in string::find, but
            // a skip of 0 causes infinite loops. pretend that
            // no tokens were found and extract the whole string
            if (skip == 0) end = string::npos;

            string token = s.substr(start, end - start);

            if (!(removeEmpty && token.empty()))
            {
                // extract the token and add it to the result list
                result.push_back(token);
            }

            // start the next range
            if ((start = end) != string::npos) start += skip;
        }

        return result;
    }
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
  QStringList labels;
  QStringList names;
  inline QString isolateName(int i)
  {
    if(i>=names.size() || i<0 || nametype<0)
      {
        return(QString::number(i));
      }
    else
      {
        if(nametype==1)
          {
            QStringList tmp=names[i].split("+");
            tmp.erase(tmp.begin());
            return(tmp.join(" "));
          }
        else if(nametype==2)
          {
            QStringList tmp=names[i].split("+");
            tmp.erase(tmp.begin());
            tmp=tmp.join(" ").split(".");
            tmp.erase(tmp.begin()+tmp.size()-1);
            return(tmp.join(" "));
          }

        return(names[i]);
      }
  }
  inline QString nodeLabel(int i)
  {
    if(i>=labels.size() || i<0)
      {
        return(QString(""));
      }
    else return(labels[i]);
  }
  void setNames(QStringList qn)
  {
    names=qn;
  }
  void setLabels(QStringList qn)
  {
    labels=qn;
  }
  void makeCF(vector <vector<double> > *v);///<Accounts for clonal frame proportions in v
  void setCF(vector <vector<double> > *v,int count);///< Sets the ClonalFrame proportions as labels
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
