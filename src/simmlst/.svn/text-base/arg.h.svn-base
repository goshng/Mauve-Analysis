#ifndef ARG_H
#define ARG_H
#include <iostream>
#include <vector>
#include <list>
#include <cmath>
#include <gsl/gsl_randist.h>
#include "data.h"
#include "popsize.h"

extern gsl_rng * rng;

using namespace std;

/**
    @brief This class represents a "small" ARG, that is one where all lines carry some ancestral material
*/
class Arg {

    public:
      Arg(int n,double rho,double delta,vector<int> blocks,PopSize * popsize=NULL);///<Creates an ARG for n isolates, with recombination rate rho, tract length delta and block structure as given by the vector "blocks"
      Data * drawData(double theta);///<Create sequence data for the leaves of the ARG using theta/2 as mutation rate
      string extractCG();///<Extracts the clonal genealogy of the ARG
      string extractLT(int site);///<Extracts the local tree at the given site
      void outputDOT(ostream * out,bool am);///<Create a DOT description of the ARG and export it
      void outputLOCAL(ostream * out);///<Export the local trees
      static vector<int> makeBlocks(string str) {
        vector<int> v;
        int s=0;
        char * pch;
        pch = strtok ((char*)str.data(),",");
        v.push_back(s);
        while (pch!=NULL) {
            s+=atoi(pch);
            v.push_back(s);
            pch = strtok (NULL, ",");
          };
        return v;
      }
    protected:
      void construct();///<Construction of the ARG, called by class constructor
      int n;///<Number of isolates
      double rho;///<Scaled recombination rate
      double delta;///<Average tract length
      vector<int> blocks;///<Structure of the observed data
      vector<vector<int> > s;///<List of the nodes in the ARG, with s[.][0] and s[.][1] being the two children, s[.][2] and s[.][3] being the two parents, s[.][4] and s[.][5] being the start and end point of an import
      vector<double> ages;///<Ages of the nodes in the ARG
      vector<bool> clonal;///<Whether a node is part of the clonal genealogy or not
      vector<bool> changeLT;///<Indicates whether the local tree change at the sites
      string buildTree(int r);
      PopSize * popsize;///<Model for population size
  };
#endif
