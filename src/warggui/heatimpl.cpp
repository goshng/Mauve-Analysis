#include "heatimpl.h"
//
HeatImpl::HeatImpl(int n)
{
  this->n=n;
  states=vector<vector<double> >(n,vector<double>(n,0.0));
  table=vector<vector<double> >(n,vector<double>(n,0.0));
  its=0;
  expected=0.0;
}

void HeatImpl::account(ParamQt * p)
{
  param=p;
  its++;
  RecTree * rectree=p->getTree();
  expected+=p->getRho()*0.5*rectree->getTTotal();
  for (int i=0; i<rectree->numRecEdge(); i++)
    states[rectree->getRecEdge(i)->getEdgeFrom()][rectree->getRecEdge(i)->getEdgeTo()]++;
}

void HeatImpl::compute()
{
  for (int i=0; i<n; i++) for (int j=0; j<n; j++)
      table[i][j] = states[i][j]/its;
}

void HeatImpl::compute_correct(int mode)
{
  RecTree * t=param->getTree();
  int num=0;
  for (int i=0; i<n; i++) for (int j=0; j<n; j++) num+=states[i][j];
  if (corr.size()==0)
    {
      corr=vector<vector<double> >(n,vector<double>(n,0.0));
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
    }
  for (int i=0; i<n; i++) for (int j=0; j<n; j++)
      {
        double val;
        if (mode==3) val=corr[i][j]/its;
        else if (corr[i][j]==0.0||(corr[i][j]/its<3 && states[i][j]/its<3)) val=0;
        else if (mode==2) val=states[i][j]/corr[i][j];
        else if (mode==1) val=(states[i][j]/its-corr[i][j]/its)/sqrt(corr[i][j]/its);
        table[i][j] = val;
      }
}

void HeatImpl::print(ostream* f_out)
{
  for (int i=0; i<n; i++)
    {
      for (int j=0; j<n-1; j++) *f_out<<table[i][j]<<",";
      *f_out<<table[i][n-1]<<endl;
    }
}
