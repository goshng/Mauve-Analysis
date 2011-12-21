#include "popsize.h"
//
PopSize::PopSize() {
  types.push_back(false);
  times.push_back(0.0);
  values.push_back(1.0);
}

void PopSize::addEvent(bool isExp,double time,double value) {
  unsigned int index=0;
  while (index<types.size() && time>times[index]) index++;
  while (index<types.size() && time==times[index] && types[index]==false) index++;
if (!isExp && value<0) {value=0.0,isExp=true;}
  types. insert(types .begin()+index,isExp);
  times. insert(times .begin()+index,time );
  values.insert(values.begin()+index,value);
}

double PopSize::convert(double time) {
  unsigned int cur=0;
  double tleft=time;
  double curSize=1.0;
  double max;
  while (1) {
      if (types[cur]==false || values[cur]==0.0) {//Constant part
          if (types[cur]==false) curSize=values[cur];
        if (curSize<0.0) {cerr << "Error: Negative population size."<<endl;exit(1);}
          double t1=times[cur],t2=times[cur+1];
          if (cur+1==types.size()) max=tleft+1; else max=(t2-t1)/curSize;
          if (tleft<max) return t1+tleft*curSize;
        else {tleft-=max;cur++;}
        } else {//Exponential part
          double beta=values[cur],t1=times[cur],t2=times[cur+1];
          if (cur+1==types.size()) max=tleft+1; else max=(exp(beta*(t2-t1))-1.0)/beta/curSize;
          if (tleft<max) {
              if (tleft*beta*curSize+1.0<0.0) {cerr << "Error: Infinite time to next event due to negative growth rate." << endl;exit(1);} else return t1+log(tleft*beta*curSize+1.0)/beta;
            } else {curSize*=exp(-beta*(t2-t1));tleft-=max;cur++;}
        }
    };
}

double PopSize::getSizeUnscaled(double time) {
  unsigned int cur=0;
  double tleft=time;
  double curSize=1.0;
  double max;
  while (1) {
      if (types[cur]==false || values[cur]==0.0) {//Constant part
          if (types[cur]==false) curSize=values[cur];
        if (curSize<0.0) {cerr << "Error: Negative population size."<<endl;exit(1);}
          double t1=times[cur],t2=times[cur+1];
          if (cur+1==types.size()) max=tleft+1; else max=(t2-t1);
          if (tleft<max) {
              return(curSize);
            } else {tleft-=max;cur++;}
        } else {//Exponential part
          double beta=values[cur],t1=times[cur],t2=times[cur+1];
          if (cur+1==types.size()) max=tleft+1; else max=t2-t1;//(exp(beta*(t2-t1))-1.0)/beta/curSize;
          if (tleft<max) {
              return(curSize*exp(-beta*(tleft)));
            } else {curSize*=exp(-beta*(t2-t1));tleft-=max;cur++;}
        }
    }
}

void PopSize::writePopSize(ostream * out,int numpoints) {
  double timeto=1.0 + times[times.size()-1];
  double tstep = timeto/numpoints;
  double curtime=0;
  *out<<"Time(Real),Time(coalescent),Population"<<endl;
  for (int c1=0;c1<=numpoints;c1++) {
      *out<<curtime<<","<<convert(curtime)<<","<<getSizeUnscaled(curtime)<<endl;
      curtime+=tstep;
    }
}

vector<double> * PopSize::getVectorSizes(double *maxtime) {
  int numpoints=1001;
  double timeto=1.0 + times[times.size()-1];
  *maxtime=timeto;
  double tstep = timeto/numpoints;
  double curtime=0;
  vector<double> * v=new vector<double>();
  for (int c1=0;c1<=numpoints;c1++) {
      v->push_back(getSizeUnscaled(curtime));
      curtime+=tstep;
    }
  return v;
}

void PopSize::show() {
  for (unsigned int i=0;i<types.size();i++) cout<<types[i]<<" "<<times[i]<<" "<<values[i]<<endl;
}

