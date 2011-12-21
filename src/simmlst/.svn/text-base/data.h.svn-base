#ifndef DATA_H
#define DATA_H
#include <vector>
#include <string>
#include <iostream>
#include <cstdlib>
#include <fstream>
#include <sstream>

using namespace std;

/**
    @brief Sequence data for the leaves of the topology
*/
class Data {
public:
    Data(string filename);///<Reads in the data from a file
    Data(int n,vector <int> blocks);///<Creates empty data
    ~Data();
    inline char get(int i,int j) {
        return data[i][j];
    } ///<Get accessor to the data
    inline void set(int i,int j,char c) {
    	data[i][j]=c;
    	makePoly(j);
   	} ///<Set accessor to the data
    inline void set_NO_POLY_UPDATE(int i,int j,char c) {data[i][j]=c;}
    inline int getN() {
        return n;
    }///<Returns the number of isolates
    inline int getL() {
        return L;
    }///<Returns the length of the sequences
    inline int getB() {
    	return blocks.size()-1;
   	}///<Returns the number of blocks
    inline int inblock(int site) {
	int blockin=0;while(blocks[blockin+1]<=site) blockin++;
	return blockin;
    }///<Returns the block a given site is in
    inline vector<int> * getBlocks() {
   		return &blocks;
  	}///<Returns the block structure
   	void output(ostream * out);
   	inline bool isPoly(unsigned int site) {return poly[site];}///<Returns whether a site is polymorphic
   	void makePoly(unsigned int site) {
   		if (data[0][site]>3) {poly[site]=true;return;}
   		for (unsigned int i=1;i<n;i++) if (data[0][site]!=data[i][site]) {poly[site]=true;return;}
  		poly[site]=false;
  	}
  	double watterson();///<Returns watterson's estimate of theta
  	inline int numPoly() {int r=0;for (unsigned int i=0;i<L;i++) if (poly[i]) r++;return r;}///<Returns the number of polymorphic sites 
    inline bool isBegEnd(int a) {return begEnd[a];}
protected:
    char convert(char in);///<Converts a character from A,C,G,T to 0,1,2,3
    char convertBack(char in);///<Converts a character from 0,1,2,3 to A,C,G,T
    unsigned int n;///<Number of isolates
    unsigned int L;///<Length of concatenated sequences
    vector<string> data;///<Concatenated data
    vector<int> blocks;///<Starting points of blocks in concatenated data, finished with L
    vector<bool> poly;///<Indicates whether the sites are polymorphic
    vector<bool> begEnd;///<Indicates whether the sites are beginning or end of blocks
};

#endif
