#include "mainwindowimpl.h"
#include "paramqt.h"

//
MainWindowImpl::MainWindowImpl()
{
  param=new ParamQt();
  outputFile=NULL;
  data=NULL;
  explorerCutoff=70;
}

MainWindowImpl::~MainWindowImpl()
{
  if(param) delete(param);
  if(outputFile) delete(outputFile);
}

// sang
void MainWindowImpl::openXMLFile(char * qstrs)
{
  outputfilename = qstrs;

  if(outputFile) delete(outputFile);
  outputFile=new OutputFile(outputfilename,false);//set this to true to recover the previous behaviour of initialising on loading.
  //param->setBlocks(outputFile->getBlocks());
  param->setNames(outputFile->getNames());
  //param->setLabels(QStringList());
  param->clearTreeData();
  data=NULL;
  //if(data!=NULL) delete(data);
  loadIteration();
}

void MainWindowImpl::loadIteration(bool startOver)
{
  if (outputFile==NULL) return;
  if (startOver)
    {
      outputFile->startOver();
      param->setNames(outputFile->getNames());
    }
  outputFile->getIt(param);
}

// sang
void MainWindowImpl::on_actionHeat_map_activated(int correctforprior)
{
  outputFile->startOver();
  HeatImpl * hi=new HeatImpl(param->getTree()->getN()*2-1);
  while (outputFile->getIt(param))
    {
      hi->account(param);
    }
  if(correctforprior>0)
    hi->compute_correct(correctforprior);
  else
    hi->compute();
  ostream* f_out;
  f_out = &cout;
  f_out << "Line 1" << endl;
  f_out << "Line 2" << endl;
  f_out << "Line 3" << endl;
  hi->print(f_out);
}


