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

void ParamQt::setCF(vector <vector<double> > *v,int count)
{
  QStringList qn;
  vector <vector<double> > res = *v;
  for(unsigned int c1=0; c1<res.size(); c1++)
    {
      for(unsigned int c2=0; c2<res[c1].size(); c2++)
        {
          res[c1][c2]/=count;
        }
    }
  // res[0-3] are the means; res[4-7] are the 2nd moments E(x^2).
  for(unsigned int c1=0; c1<res[0].size(); c1++)
    {
      if(res[1][c1]==0 && res[3][c1]==0) qn.push_back(QString(""));
      else
        {
          qn.push_back( QString("m=") +  QString::number(res[1][c1],'f',0) + QString("/")+QString::number(res[0][c1],'f',0) + QString(" r=") + QString::number(res[3][c1],'f',0) + QString("/") + QString::number(res[2][c1],'f',0) );
//+ QString(" (") + QString::number(res[5][c1],'f',0) + QString(",") +  QString::number(res[7][c1],'f',0) + QString(")") );// this is one (poor) way of displaying variation information
        }
    }
  setLabels(qn);
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
