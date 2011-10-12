#include <cstdlib>
#include "outputfile.h"
//
OutputFile::OutputFile(string &qstrs,bool makeVectors)
  : mDoc (qstrs.c_str())
{
  if (mDoc.LoadFile())
  {
    outputinitialised=false;
    startOver();
  }
  else
  {
    cerr << "Error in reading qstrs.c_str()" << endl;
  }
}

void OutputFile::reset()
{
  outputinitialised=false;
  int currentIteration;
  thetas.clear();
  rhos.clear();
  deltas.clear();
  likelihoods.clear();
  priors.clear();
  numrecedges.clear();
  genorec.clear();
  relgenorec.clear();
  genobeg.clear();
  genoend.clear();
  tmrcas.clear();
  ttotals.clear();
}

// Read Blocks, comment, nameMap, regions.
void OutputFile::startOver()
{
  currentIteration=-1;
  TiXmlHandle h(&mDoc);
  TiXmlElement* t;
  t = h.FirstChild("Blocks").ToElement(); blocks(t->GetText());
  t = h.FirstChild("comment").ToElement(); comment(t->GetText());
  t = h.FirstChild("nameMap").ToElement(); names(t->GetText());
  t = h.FirstChild("regions").ToElement(); regionsString(t->GetText());
}

bool OutputFile::getIt(Param * p)
{
  int deb=0;
  currentIteration++;
  p->setRho(0);
  p->setTheta(0);
  p->setLL(0);
  TiXmlHandle h(&mDoc);
  TiXmlHandle hIter = h.Child("Iteration", currentIteration);

  TiXmlElement* t;
  // <Tree>
  t = hIter.FirstChild("Tree").ToElement();
  string s(t->GetText());
  while (s.at(0)==10 || s.at(0)==13) s=s.substr(1,s.length()-1);
  while (s.at(s.size()-1)==10 || s.at(s.size()-1)==13) s=s.substr(0,s.length()-1);
  if (i==0) p->setTreeData(new RecTree(getL(),s,false,false),blocks);

  // <number>, <theta>, <delta>, <rho>, <ll>.
  t = hIter.FirstChild("number").ToElement(); p->setNumber(atol(t->GetText()));
  t = hIter.FirstChild("theta").ToElement();  p->setTheta(p->getTheta() + atof(t->GetText()));
  t = hIter.FirstChild("delta").ToElement();  p->setDelta(atof(t->GetText()));
  t = hIter.FirstChild("rho").ToElement();    p->setRho(p->getRho() + atof(t->GetText()));
  t = hIter.FirstChild("ll").ToElement();     p->setLL(p->getLL() + atof(t->GetText()));

  // <recedge>
  TiXmlElement* parent = hIter.ToElment(); 
  TiXmlElement* child = 0;
  while (child = parent->IteratreChildren("recedge", child))
    {
      int start=0,end=0,efrom=0,eto=0;
      double ato=0,afrom=0;
      t = child->FirstChild("start"); start = deb + atoi(t->GetText());
      t = child->FirstChild("end"); end = deb + atoi(t->GetText());
      t = child->FirstChild("efrom"); efrom = atoi(t->GetText());
      t = child->FirstChild("eto"); eto = atoi(t->GetText());
      t = child->FirstChild("afrom"); afrom = atof(t->GetText());
      t = child->FirstChild("ato"); ato = atof(t->GetText());
      p->getTree()->addRecEdge(afrom,ato,start,end,efrom,eto);
    }
  return true;
}

vector<double>* OutputFile::getRhoOverTheta()
{
  vector<double>*v=new vector<double>();
  for (unsigned int i=0; i<rhos.size(); i++) v->push_back(rhos[i]/thetas[i]);
  return v;
}

vector<double>* OutputFile::getRhoPerSite()
{
  int L=getL();
  int b=getB();
  vector<double>*v=new vector<double>();
  for (unsigned int i=0; i<rhos.size(); i++) v->push_back(rhos[i]/(deltas[i]*b+L-b));
  return v;
}

vector<double>* OutputFile::getThetaPerSite()
{
  int L=getL();
  vector<double>*v=new vector<double>();
  for (unsigned int i=0; i<rhos.size(); i++) v->push_back(thetas[i]/L);
  return v;
}

vector<double>* OutputFile::getPosteriors()
{
  vector<double>*v=new vector<double>();
  for (unsigned int i=0; i<likelihoods.size(); i++) v->push_back(likelihoods[i]+priors[i]);
  return v;
}

vector<double>* OutputFile::getRoverM(ParamQt*param)
{
  vector<double>*v=new vector<double>();
  startOver();
  while (getIt(param))
    {
      v->push_back(param->getRM());
    }
  startOver();
  return v;

  /*int L=getL();
  int b=getB();
  vector<double>*v=new vector<double>();
  //for (unsigned int i=0;i<rhos.size();i++) v->push_back(rhos[i]/thetas[i]*L*deltas[i]/(deltas[i]*b+L-b)*0.75*(1.0-exp(-4.0*thetas[i]/L)));
  for (unsigned int i=0;i<rhos.size();i++) v->push_back(rhos[i]/thetas[i]*L*deltas[i]/(deltas[i]*b+L-b)*3.0*thetas[i]/(3.0*L+4.0*thetas[i]));
  return v;*/
}

void OutputFile::makeCF(ParamQt*param)
{
  vector<vector<double> > *v=new vector<vector<double> >(0,vector<double>(0.0));
  startOver();
  int count=0;
  while (getIt(param))
    {
      param->makeCF(v);
      count++;
    }
  param->setCF(v,count);
  startOver();
}

vector<double>* OutputFile::getGenoRec(int id,bool getto)
{
  vector<double> * res=new vector<double>(genorec.size(),0);
  QFile f(file[0]->fileName());
  f.open(QIODevice::ReadOnly);
  QXmlStreamReader x(&f);
  int start=0;
  int end=0;
  int edge=0;
  int efrom=0;
  while (!x.atEnd())
    {
      x.readNext();
      if (x.isEndElement()&&x.name().toString().compare("recedge"  )==0)
        {
          if (edge==id && getto) for (int i=start; i<end; i++) (res->at(i))++;
          else if(efrom==id && !getto) for (int i=start; i<end; i++) (res->at(i))++;
          continue;
        }
      if (x.isStartElement()&&x.name().toString().compare("start")==0)
        {
          start=x.readElementText().toInt();
          continue;
        }
      if (x.isStartElement()&&x.name().toString().compare("end"  )==0)
        {
          end=x.readElementText().toInt();
          continue;
        }
      if (x.isStartElement()&&x.name().toString().compare("efrom")==0)
        {
          efrom=x.readElementText().toInt();
          continue;
        }
      if (x.isStartElement()&&x.name().toString().compare("eto")==0)
        {
          edge=x.readElementText().toInt();
          continue;
        }
    }
  f.close();
  for (unsigned int i=0; i<res->size(); i++)
    {
      res->at(i)/=thetas.size();
    }
  return res;
}

vector<double>* OutputFile::getRelGenoRec(ParamQt*param,int id)
{
  vector<double> * res=new vector<double>(genorec.size(),0);
  QFile f(file[0]->fileName());
  f.open(QIODevice::ReadOnly);
  QXmlStreamReader x(&f);
  double treedist;
  startOver();
  int counts=0;
  while (getIt(param))
    {
      for(int i=0; i<(int)param->getRecTree()->numRecEdge(); i++)
        {
          if(param->getRecTree()->getEdge(i)->getEdgeTo()==id)
            {
              treedist=param->getRecTree()->getEdgeTreeTime(i);
              for (unsigned int j=param->getRecTree()->getEdge(i)->getStart(); j<param->getRecTree()->getEdge(i)->getEnd(); j++) (res->at(j))+=treedist/param->getRecTree()->getTTotal();
              counts++;
            }
        }
    }
  f.close();
  for (unsigned int i=0; i<res->size(); i++) res->at(i)/=counts;
  return res;
}

vector<double>* OutputFile::getRelGenoRec(ParamQt*param)
{
  vector<double> * res=new vector<double>(genorec.size(),0);
  QFile f(file[0]->fileName());
  f.open(QIODevice::ReadOnly);
  QXmlStreamReader x(&f);
  double treedist;
  startOver();
  int counts=0;
  while (getIt(param))
    {
      for(int i=0; i<(int)param->getRecTree()->numRecEdge(); i++)
        {
          treedist=param->getRecTree()->getEdgeTreeTime(i);
          for (unsigned int j=param->getRecTree()->getEdge(i)->getStart(); j<param->getRecTree()->getEdge(i)->getEnd(); j++) (res->at(j))+=treedist/param->getRecTree()->getTTotal();
          counts++;
        }
    }
  f.close();
  for (unsigned int i=0; i<res->size(); i++) res->at(i)*=param->getDelta()/counts;
  return res;
}


void OutputFile::readNames(QString str)
{
  names.clear();
  QStringList list1 = str.split(";");
  for(unsigned int i=0; i<list1.size(); i++)
    {
      QStringList list2 = list1[i].split(",");
      if(list2.size()>1)
        {
          int index=list2[0].toInt();
          names<<list2[1];
        }
    }
}

