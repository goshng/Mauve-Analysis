#include "paramqt.h"
//
ParamQt::ParamQt(  )
{
  isCons=false;
  rateScale=1.0;
  timeScale=4.0;
  iteration=-1;
  recview=0;
  labview=1;
  nametype=0;
}

ParamQt::~ParamQt()
{
}
//

/// This is the new version of r/m
double ParamQt::getRM()
{
  vector <vector<double> > * respartial=greedyPairwiseDetails();
  vector <vector<double> > res=greedyDetails(respartial);
  double r=0,m=0;
  for(unsigned int c1=0; c1<res[0].size(); c1++)
    {
      m+=res[1][c1];
      r+=res[3][c1];
    }
  return(r/m);
}

void ParamQt::makeCF(vector <vector<double> > *v)
{
  vector <vector<double> > * respartial=greedyPairwiseDetails();
  vector <vector<double> > res=greedyDetails(respartial);

  if(v->size()==0)
    {
      for(unsigned int c1=0; c1<res.size(); c1++) v->push_back(res[c1]);
    }
  else
    {
      for(unsigned int c1=0; c1<res.size(); c1++)
        {
          for(unsigned int c2=0; c2<res[c1].size(); c2++)
            {
              v->at(c1)[c2]+=res[c1][c2];
            }
        }
    }
}

int ParamQt::lastCommonAncestor(int s1, int s2)
{
  vector<int> r1,r2;
  int lcaindexr1=-1;/// index of last common ancestor in list from s1
  r1.push_back(s1);
  while(r1.back()!=rectree->getRoot()->getId())
    {
      r1.push_back(rectree->getNode(r1.back())->getFather()->getId());
    }
  r2.push_back(s2);
  while(r2.back()!=rectree->getRoot()->getId())
    {
      r2.push_back(rectree->getNode(r2.back())->getFather()->getId());
    }
  for(unsigned int i=1; i<=max(r1.size(),r2.size()); i++)
    {
      if(r1[r1.size()-i]==r2[r2.size()-i])
        {
          lcaindexr1=r1.size()-i;
        }
      else break;
    }
  return(r1[lcaindexr1]);
}

double ParamQt::pairwiseDistance(int s1, int s2)
{
  int lca=lastCommonAncestor(s1,s2);
  double dist=2.0*(rectree->getNode(lca)->getAge());
  return(dist);
}

vector<int> ParamQt::consistentAgeList(vector<double> *res)
{
  res->clear();
  vector<int> donelist;
  int nodeon;
  bool found;
  for(int c1=0; c1<rectree->getN(); c1++)
    {
      for(int c2=c1+1; c2<rectree->getN(); c2++)
        {
          found=false;
          nodeon=lastCommonAncestor(c1,c2);
          for(unsigned int c3=0; c3<donelist.size(); c3++)
            {
              if(nodeon==donelist[c3])
                {
                  found=true;
                  c3=donelist.size();
                }
            }
          if(!found)
            {
              donelist.push_back(nodeon);
              res->push_back(rectree->getNode(nodeon)->getAge());
            }
        }
    }
  return(donelist);
}

vector<double> ParamQt::pairwiseDistanceList()
{
  vector<double> res;
  for(int c1=0; c1<rectree->getN(); c1++)
    {
      for(int c2=c1+1; c2<rectree->getN(); c2++)
        {
          res.push_back(pairwiseDistance(c1,c2));
        }
    }
  return(res);
}

vector<vector<double> > ParamQt::pairwiseDistanceMatrix(bool print)
{
  vector<vector<double> > res;
  for(int c1=0; c1<rectree->getN(); c1++)
    {
      res.push_back(vector<double>(rectree->getN(),0.0));
    }
  double dist=0.0;
  for(int c1=0; c1<rectree->getN(); c1++)
    {
      for(int c2=c1+1; c2<rectree->getN(); c2++)
        {
          dist=pairwiseDistance(c1,c2);
          res[c1][c2]=dist;
          res[c2][c1]=dist;
        }
    }
  if(print)
    {
      cout<<"DISTANCE MATRIX:"<<endl;
      for(int c1=0; c1<rectree->getN(); c1++)
        {
          for(int c2=0; c2<rectree->getN(); c2++)
            {
              cout<<res[c1][c2]<<", ";
            }
          cout<<endl;
        }
    }
  return(res);
};///< returns a pairwise distance matrix for the current tree

int ParamQt::recCount(int s1, int s2)
{
  vector<int> r1,r2;
  int lcaindexr1=-1,lcaindexr2=-1;/// index of last common ancestor in list from s1
  int reccounted=0;
// get the list of edges to the MRCA
  r1.push_back(s1);
  while(r1.back()!=rectree->getRoot()->getId())
    {
      r1.push_back(rectree->getNode(r1.back())->getFather()->getId());
    }
  r2.push_back(s2);
  while(r2.back()!=rectree->getRoot()->getId())
    {
      r2.push_back(rectree->getNode(r2.back())->getFather()->getId());
    }
  for(unsigned int i=1; i<=max(r1.size(),r2.size()); i++)
    {
      if(r1[r1.size()-i]==r2[r2.size()-i])
        {
          lcaindexr1=r1.size()-i;
          lcaindexr2=r2.size()-i;
        }
      else break;
    }
// get the recombination affecting those edges
  for(long c1=0; c1<getTree()->numRecEdge(); c1++)
    {
      for(int c2=0; c2<lcaindexr1; c2++)
        {
          if(getTree()->getEdge(c1)->getEdgeTo()==r1[c2] || getTree()->getEdge(c1)->getEdgeTo()==s1)
            {
              for(int c3=0; c3<lcaindexr2; c3++)
                {
                  if(getTree()->getEdge(c1)->getEdgeFrom()==r2[c3] || getTree()->getEdge(c1)->getEdgeFrom()==s2)
                    {
                      reccounted++;
                      c3=lcaindexr2;
                      c2=lcaindexr1;
                    }
                }
            }
        }
    }
  return(reccounted);
}

vector<vector<double> > ParamQt::recPriorMatrix()
{
  RecTree * t=getTree();
// getthe expected amount of recombination between branches
  int n=getTree()->getN()*2-1;
  double expected=getRho()*0.5*t->getTTotal();
  vector<vector<double> > corr=vector<vector<double> >(n,vector<double>(n,0.0));
  double s=0;
  for (int i=0; i<n; i++) for (int j=0; j<n; j++)
      {
        double i0=t->getNode(i)->getAge();
        double j0=t->getNode(j)->getAge();
        double il=t->getNode(i)->getDist();
        double jl=t->getNode(j)->getDist();
        if (i==t->getN()*2-2) il=10.0;
        for (int a=0; a<100; a++) for (int b=0; b<100; b++)
            corr[i][j]+=t->priorEdge(i0+il*(a+1)/101.0,j0+jl*(b+1)/101.0);
        corr[i][j]*=jl*il/10000.0;
        s+=corr[i][j];
      }
  for (int i=0; i<n; i++) for (int j=0; j<n; j++) corr[i][j]*=expected/s;
//  return(corr);
// Now sum over branches for the pairwise distances

  vector<vector<double> > prior=vector<vector<double> >(t->getN(),vector<double>(t->getN(),0.0));
  for(int s1=0; s1<t->getN(); s1++)
    {
      for(int s2=0; s2<t->getN(); s2++)
        {
          vector<int> r1,r2;
          int lcaindexr1=-1,lcaindexr2=-1;/// index of last common ancestor in list from s1
// get the list of edges to the MRCA
          r1.push_back(s1);
          while(r1.back()!=rectree->getRoot()->getId())
            {
              r1.push_back(rectree->getNode(r1.back())->getFather()->getId());
            }
          r2.push_back(s2);
          while(r2.back()!=rectree->getRoot()->getId())
            {
              r2.push_back(rectree->getNode(r2.back())->getFather()->getId());
            }
          for(unsigned int i=1; i<=max(r1.size(),r2.size()); i++)
            {
              if(r1[r1.size()-i]==r2[r2.size()-i])
                {
                  lcaindexr1=r1.size()-i;
                  lcaindexr2=r2.size()-i;
                }
              else break;
            }
// do the sum
          for(int c1=0; c1<lcaindexr1; c1++)
            {
              for(int c2=0; c2<lcaindexr2; c2++)
                {
                  prior[s1][s2]+=corr[r1[c1]][r2[c2]];
                }
            }
        }
    }
  return(prior);
}

vector<vector<int> > ParamQt::recCountMatrix(bool print)
{
  vector<vector<int> > res;
  for(int c1=0; c1<rectree->getN(); c1++)
    {
      res.push_back(vector<int>(rectree->getN(),0.0));
    }
  for(int c1=0; c1<rectree->getN(); c1++)
    {
      for(int c2=0; c2<rectree->getN(); c2++)
        {
          if(c1!=c2)
            {
              res[c1][c2]=recCount(c1,c2);
            }

        }
    }
  if(print)
    {
      cout<<"RECOMBINATION COUNT MATRIX:"<<endl;
      for(int c1=0; c1<rectree->getN(); c1++)
        {
          for(int c2=0; c2<rectree->getN(); c2++)
            {
              cout<<res[c1][c2]<<", ";
            }
          cout<<endl;
        }
    }
  return(res);
};///< returns a pairwise recombination count matrix for the sequences on the clonal tree

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
                         bool removeEmpty,
                         bool fullMatch)
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

