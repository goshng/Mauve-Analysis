#ifndef MAINWINDOWIMPL_H
#define MAINWINDOWIMPL_H
//
//#include "gelmanrubinimpl.h"
//#include "paramcons.h"
//#include "paramconsmult.h"
//#include "parammr.h"
//#include "paramtreecons.h"
//#include "colouredimpl.h"
//#include "pdimpl.h"
//#include "pheatimpl.h"

#include "outputfile.h"
#include "heatimpl.h"
#include "../warg/src/param.h"
//
class MainWindowImpl
{
public:
  MainWindowImpl();
  ~MainWindowImpl();
  void openXMLFile(char * qstrs);
  void on_actionHeat_map_activated(int correctforprior);

protected:
  std::string outputfilename;
  Param * param;
  Param * ioparam;
  int explorerSite;
  int explorerCutoff;
  OutputFile * outputFile;
  Data * data;
  void loadIteration(bool startOver=false);
};
#endif
