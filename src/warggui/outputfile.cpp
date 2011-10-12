#include <cstdlib>
#include "outputfile.h"
#include "paramqt.h"
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
  TiXmlHandle root(&mDoc);
  TiXmlElement* t;
  TiXmlHandle h = root.FirstChild("outputFile");

  t = h.FirstChild("Blocks").ToElement(); blocks = t->GetText();
  while (blocks.at(0)==10 || blocks.at(0)==13) blocks=blocks.substr(1,blocks.length()-1);
  while (blocks.at(blocks.size()-1)==10 || blocks.at(blocks.size()-1)==13) blocks=blocks.substr(0,blocks.length()-1);
  vector<string> blocksString = Daniweb::Split (blocks, ",");
  for (int i = 0; i < blocksString.size(); i++)
    blocksInt.push_back(atoi(blocksString[i].c_str()));

  t = h.FirstChild("comment").ToElement(); comment = t->GetText();
  t = h.FirstChild("nameMap").ToElement(); names = t->GetText();
  t = h.FirstChild("regions").ToElement(); regionsString = t->GetText();
}

bool OutputFile::getIt(ParamQt * p)
{
  int deb=0;
  currentIteration++;
  p->setRho(0);
  p->setTheta(0);
  p->setLL(0);
  TiXmlHandle root(&mDoc);
  TiXmlHandle h = root.FirstChild("outputFile");
  TiXmlHandle hIter = h.Child("Iteration", currentIteration);

  TiXmlElement* t;
  // <Tree>
  t = hIter.FirstChild("Tree").ToElement();
  if (t == NULL) // Can I use hIter to return false?
    return false;
  string s(t->GetText());
  while (s.at(0)==10 || s.at(0)==13) s=s.substr(1,s.length()-1);
  while (s.at(s.size()-1)==10 || s.at(s.size()-1)==13) s=s.substr(0,s.length()-1);
  p->setTreeData(new RecTree(getL(),s,false,false),blocks);

  // <number>, <theta>, <delta>, <rho>, <ll>.
  t = hIter.FirstChild("number").ToElement(); p->setNumber(atol(t->GetText()));
  t = hIter.FirstChild("theta").ToElement();  p->setTheta(p->getTheta() + atof(t->GetText()));
  t = hIter.FirstChild("delta").ToElement();  p->setDelta(atof(t->GetText()));
  t = hIter.FirstChild("rho").ToElement();    p->setRho(p->getRho() + atof(t->GetText()));
  t = hIter.FirstChild("ll").ToElement();     p->setLL(p->getLL() + atof(t->GetText()));

  // <recedge>
  TiXmlElement* parent = hIter.ToElement(); 
  TiXmlElement* child = 0;
  while (child = (TiXmlElement*) parent->IterateChildren("recedge", child))
    {
      int start=0,end=0,efrom=0,eto=0;
      double ato=0,afrom=0;
      t = child->FirstChildElement("start"); start = deb + atoi(t->GetText());
      t = child->FirstChildElement("end"); end = deb + atoi(t->GetText());
      t = child->FirstChildElement("efrom"); efrom = atoi(t->GetText());
      t = child->FirstChildElement("eto"); eto = atoi(t->GetText());
      t = child->FirstChildElement("afrom"); afrom = atof(t->GetText());
      t = child->FirstChildElement("ato"); ato = atof(t->GetText());
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


void OutputFile::readNames(string str)
{
  names.clear();
  names = str;
}

