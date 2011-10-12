#ifndef HEATIMPL_H
#define HEATIMPL_H
//
#include <cmath>
#include "paramqt.h"
#include "../warg/src/param.h"

using namespace std;
//
class HeatImpl
{
public:
  HeatImpl(int n);
  void account(ParamQt * p);
  void compute();
  void compute_correct(int mode);
  void print(ostream* f_out);
protected:
  ParamQt * param;
  int n;
  int its;
  double expected;
  vector<vector<double> > states;
  vector<vector<double> > corr;
  vector<vector<double> > table;
};
#endif





