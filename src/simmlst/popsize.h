#ifndef POPSIZE_H
#define POPSIZE_H
#include <iostream>
#include <vector>
#include <cmath>
//
using namespace std;
//
class PopSize {

    public:
      PopSize();
      void addEvent(bool isExp,double time,double value);
      double convert(double time);
      double getSizeUnscaled(double time);
      void show();
      void writePopSize(ostream * out,int numpoints=1001);
      vector<double> * getVectorSizes(double *maxtime);
    protected:
      vector<bool> types;
      vector<double> times;
      vector<double> values;
  };
#endif
