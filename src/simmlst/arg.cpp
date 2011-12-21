#include "arg.h"
//
Arg::Arg(int n,double rho,double delta,vector<int> blocks,PopSize * popsize) {
  this->n=n;
  this->rho=rho;
  this->delta=delta;
  this->blocks=blocks;
  this->popsize=popsize;
  changeLT=vector<bool>(blocks.back(),false);
  changeLT[0]=true;
  construct();
}

void Arg::construct() {
  s.clear();
  ages.clear();
  clonal.clear();
  int L=blocks.back();
  int b=blocks.size()-1;
  vector<double> probstart(L,1.0/(b*delta+L-b));//Contains the probabilities that a recombination event starts at each point of the observed data
  for (int i=0;i<b;i++) probstart[blocks[i]]*=delta;
  int k=n;
  vector<int> toCoal;//Contains the list of lines currently in the ARG
  vector<vector<bool> > toCoalAncMat;//Describes the ancestral material of these lines
  for (int i=0;i<n;i++) {
      toCoal.push_back(i);
      toCoalAncMat.push_back(vector<bool>(L,true));
      s.push_back(vector<int>(6,-1));
      ages.push_back(0.0);
      clonal.push_back(true);
    }
  double time=0.0;
  while (k>1) {
      time+=gsl_ran_exponential(rng,2.0/(k*(k-1+rho)));
      if (gsl_rng_uniform(rng)<1.0*(k-1)/(k-1+rho)) {
//Coalescence
          int i=floor(gsl_rng_uniform(rng)*k);
          int j=i;
          while (j==i) j=floor(gsl_rng_uniform(rng)*k);
          s.push_back(vector<int>(6,-1));
          s.back()[0]=toCoal[i];
          s.back()[1]=toCoal[j];
          s[toCoal[i]][2]=s.size()-1;
          s[toCoal[j]][2]=s.size()-1;
          ages.push_back(time);
          clonal.push_back(clonal[toCoal[i]]||clonal[toCoal[j]]);
          toCoal[i]=s.size()-1;
          for (int a=0;a<L;a++) toCoalAncMat[i][a]=toCoalAncMat[i][a]||toCoalAncMat[j][a];
          toCoal[j]=toCoal.back();
          toCoalAncMat[j]=toCoalAncMat.back();
          if (i==k-1) i=j;
          toCoal.pop_back();
          toCoalAncMat.pop_back();
          k--;
          //Test for fully coalesced material
          for (int a=0;a<L;a++) if (toCoalAncMat[i][a]==true) {
                bool rem=true;
                for (int b=0;b<k;b++) if (b!=i&&toCoalAncMat[b][a]==true) {
                      rem=false;
                      break;
                    }
                if (rem==true) toCoalAncMat[i][a]=false;
              }
        } else {
//Recombination
          int i=floor(gsl_rng_uniform(rng)*k);
          double r=gsl_rng_uniform(rng);
          int beg=0;
          while (r>probstart[beg]) {
              r-=probstart[beg];
              beg++;
            }
          int len=gsl_ran_geometric(rng,1.0/delta);
          int nd=beg+len;
          for (unsigned int ii=0;ii<blocks.size();ii++) {
              int loc=blocks[ii];
              if (beg<loc && nd>loc) {nd=loc;break;}
            }
          bool ok=false;
          for (int ii=beg;ii<nd;ii++) if (toCoalAncMat[i][ii]==true) {ok=true;break;}
          if (!ok) continue;//Skip if import is empty
          ok=false;
        for (int ii=0;ii<L;ii++) if ((ii<beg || ii>=nd) && toCoalAncMat[i][ii]==true) {ok=true;break;}
          if (!ok && !clonal[toCoal[i]]) continue;//Skip if import is all and node is not clonal
          changeLT[beg]=true;
          if (nd<(int)changeLT.size()) changeLT[nd]=true;
          ages.push_back(time);
          ages.push_back(time);
          clonal.push_back(clonal[toCoal[i]]);
          clonal.push_back(false);
          s.push_back(vector<int>(6,-1));
          s.back()[0]=toCoal[i];
          s.push_back(vector<int>(6,-1));
          s.back()[0]=toCoal[i];
          s.back()[4]=beg;
          s.back()[5]=nd;
          s[toCoal[i]][2]=s.size()-2;
          s[toCoal[i]][3]=s.size()-1;
          toCoal[i]=s.size()-2;
          toCoal.push_back(s.size()-1);
          toCoalAncMat.push_back(vector<bool>(L,false));
          for (int ii=beg;ii<nd;ii++) {
              toCoalAncMat.back()[ii]=toCoalAncMat[i][ii];
              toCoalAncMat[i][ii]=false;
            }
          k++;
        }
    }
  if (popsize!=NULL) for (unsigned int i=0;i<ages.size();i++) ages[i]=popsize->convert(ages[i]);
}

Data * Arg::drawData(double theta) {
  string done;
  int L=blocks.back();
  vector<string*> genotypes(s.size(),NULL);
  genotypes[s.size()-1]=new string(L,'N');
  for (int j=0;j<L;j++) genotypes[s.size()-1]->at(j)=floor(gsl_rng_uniform(rng)*4);
  for (int i=s.size()-2;i>=0;i--) {
      genotypes[i]=new string(*(genotypes[s[i][2]]));//Copy data from first parent
      if ((s[s[i][2]][0]<0 || genotypes[s[s[i][2]][0]]!=NULL) && (s[s[i][2]][1]<0 || genotypes[s[s[i][2]][1]]!=NULL)) {
          delete(genotypes[s[i][2]]);
          genotypes[s[i][2]]=&done;
        }
      if (s[i][3]>0) {//If there is a second parent, copy the imported fragment
          int beg=s[s[i][3]][4];
          int  nd=s[s[i][3]][5];
          for (int j=beg;j<nd;j++) genotypes[i]->at(j)=genotypes[s[i][3]]->at(j);
          if ((s[s[i][3]][0]<0 || genotypes[s[s[i][3]][0]]!=NULL) && (s[s[i][3]][1]<0 || genotypes[s[s[i][3]][1]]!=NULL)) {
              delete(genotypes[s[i][3]]);
              genotypes[s[i][3]]=&done;
            }
        }
      //Add mutations
      int nbmuts=gsl_ran_poisson(rng,theta/2.0*(ages[s[i][2]]-ages[i]));
      for (int m=0;m<nbmuts;m++) {
          int loc=floor(gsl_rng_uniform(rng)*L);
          genotypes[i]->at(loc)=(genotypes[i]->at(loc)+1+(int)floor(gsl_rng_uniform(rng)*3))%4;
        }
    }
  //Create data object
  Data * data=new Data(n,blocks);
  for (int i=0;i<n;i++) {
      for (int j=0;j<L;j++) data->set_NO_POLY_UPDATE(i,j,genotypes[i]->at(j));
      delete(genotypes[i]);
    }
  return data;
}

string Arg::extractCG() {
  vector<bool> s4(s.size(),false);//Whether to keep a node or not
  vector<vector<int> > s2=s;
  //First add all nodes on clonal branches
  for (unsigned int k=0;k<s4.size();k++) s4[k]=clonal[k];
  //Second remove nodes with a single son, updating the branching matrix accordingly
  for (int i=n;i<(int)s.size();i++) {
      if (s4[i]==false) continue;
      if (s[i][0]<0 || s4[s[i][0]]==false) swap(s[i][0],s[i][1]);
      if (s[i][1]<0 || s4[s[i][1]]==false) {
          s4[i]=false;
          if (s[i][0]>=0) {
              s[s[i][0]][2]=s[i][2];
              if (s[i][2]>=0) {
                  if (s[s[i][2]][0]==i) s[s[i][2]][0]=s[i][0];
                  else s[s[i][2]][1]=s[i][0];
                }
            }
        }
    }
  //Find new root
  int ii=s.size()-1;while (s4[ii]==false) ii--;
  if (s[ii][0]<0 || s4[s[ii][0]]==false || s[ii][1]<0 || s4[s[ii][1]]==false) s4[ii]=false;
  while (s4[ii]==false) ii--;
  //Construct tree from root
  string str=buildTree(ii).append(";");
  s=s2;
  return str;
}

string Arg::extractLT(int site) {
  vector<bool> s4(s.size(),false);//Whether to keep a node or not
  vector<vector<int> > s2=s;
  //First add all nodes which are ancestral for the given site
  for (int k=0;k<n;k++) s4[k]=true;
  for (unsigned int k=0;k<s4.size()-1;k++) {
      if (s4[k]==false) continue;
      if (s[k][3]==-1) s4[s[k][2]]=true;else {
        int beg=s[s[k][3]][4];
        int  nd=s[s[k][3]][5];
        if (site>=beg && site<nd) s4[s[k][3]]=true;else s4[s[k][2]]=true;
      }
    }
//Second remove nodes with a single son, updating the branching matrix accordingly
for (int i=n;i<(int)s.size();i++) {
      if (s4[i]==false) continue;
      if (s[i][2]<0 || s4[s[i][2]]==false) swap(s[i][2],s[i][3]);
      if (s[i][0]<0 || s4[s[i][0]]==false) swap(s[i][0],s[i][1]);
      if (s[i][1]<0 || s4[s[i][1]]==false) {
          s4[i]=false;
          if (s[i][0]>=0) {
              s[s[i][0]][2]=s[i][2];
              if (s[i][2]>=0) {
                  if (s[s[i][2]][0]==i) s[s[i][2]][0]=s[i][0];
                  else s[s[i][2]][1]=s[i][0];
                }
            }
        }
    }
  //Find new root
  int ii=s.size()-1;while (s4[ii]==false) ii--;
  if (s[ii][0]<0 || s4[s[ii][0]]==false || s[ii][1]<0 || s4[s[ii][1]]==false) s4[ii]=false;
  while (s4[ii]==false) ii--;
  //Construct tree from root
  string str=buildTree(ii).append(";");
  s=s2;
  return str;
}

string Arg::buildTree(int r) {
  ostringstream stm;
  if (r<n) {
      stm<<r<<":"<<ages[s[r][2]];
    } else {
      stm<<"("<<buildTree(s[r][0])<<","<<buildTree(s[r][1])<<"):";
      if (s[r][2]<0) stm<<0.0;
      else stm<<ages[s[r][2]]-ages[r];
    }
  return stm.str();
}

void Arg::outputDOT(ostream * out,bool am) {
  *out<<"digraph G {fontsize=5;ranksep=0.02;ratio=fill;size=\"10,10\";"<<endl<<"edge[arrowhead=none];"<<endl;

//Put the sampled individuals on the same rank at the bottom of the graph
  *out<<"{rank=same;";
  for (int i=1;i<=n;i++) *out<<i<<"[shape=point] ";
  *out<<"}"<<endl;
  int lwd=2;
  vector<vector<bool> > ancmat;
  int L=blocks.back();
  int ma=0;for (unsigned int i=1;i<blocks.size();i++) ma=max(ma,blocks[i]-blocks[i-1]);
  double width=ceil(50.0/ma);
  int skip=max(1.0,floor(ma/50.0));
  for (int i=0;i<n;i++) ancmat.push_back(vector<bool>(L,true));
  for (int i=0;i<(int)ages.size();i++) {
      if (!am) {
          if (clonal[i]) *out<<i+1<<"[shape=point,width=0.00,height=0.00]"<<endl;
          else *out<<i+1<<"[shape=point,width=0.00,height=0.00,color=gray]"<<endl;
          continue;
        }
      if (i>=n) {
          ancmat.push_back(ancmat[s[i][0]]);
          if (s[i][1]>=0) {//Father of two sons
              for (int k=0;k<L;k++) ancmat.back()[k]=ancmat[s[i][0]][k]||ancmat[s[i][1]][k];
            } else if (s[s[i][0]][2]==i) //recipient
          for (int k=0;k<L;k++) {if (k>=s[s[s[i][0]][3]][4]&&k<s[s[s[i][0]][3]][5]) ancmat.back()[k]=false;}
          else//donor
          for (int k=0;k<L;k++) {if (k<s[i][4]||k>=s[i][5]) ancmat.back()[k]=false;}
        }
      *out<<i+1<<"[shape=plaintext,label=<<table CELLBORDER=\"0\" CELLSPACING=\"0\" CELLPADDING=\"0\" BORDER=\"0\">";
      *out<<"<tr><td HEIGHT=\""<<lwd<<"\" COLSPAN=\""<<floor(ma/skip)+4<<"\" bgcolor=\"white\"></td></tr>";
      for (unsigned int j=1;j<blocks.size();j++) {
          *out<<"<tr><td HEIGHT=\""<<lwd<<"\" WIDTH=\""<<lwd<<"\" bgcolor=\"white\"></td><td bgcolor=\"black\" HEIGHT=\""<<lwd<<"\" COLSPAN=\""<<floor((blocks[j]-blocks[j-1])/skip)+2<<"\"></td><td HEIGHT=\""<<lwd<<"\" WIDTH=\""<<lwd<<"\" bgcolor=\"white\"></td></tr>";
          *out<<"<tr><td HEIGHT=\"10\" WIDTH=\""<<lwd<<"\" bgcolor=\"white\"></td><td bgcolor=\"black\" WIDTH=\""<<lwd<<"\" HEIGHT=\"10\"></td>";
          for (int k=blocks[j-1];k<blocks[j];k+=skip)
            if (ancmat[i][k])
              *out<<"<td bgcolor=\"grey\" HEIGHT=\"10\" WIDTH=\""<<width<<"\"></td>";
            else
              *out<<"<td HEIGHT=\"10\" WIDTH=\""<<width<<"\" bgcolor=\"white\"></td>";
          *out<<"<td bgcolor=\"black\" WIDTH=\""<<lwd<<"\" HEIGHT=\"10\"></td>";
          *out<<"<td bgcolor=\"white\" WIDTH=\""<<lwd<<"\" HEIGHT=\"10\"></td></tr>";
          *out<<"<tr><td HEIGHT=\""<<lwd<<"\" WIDTH=\""<<lwd<<"\" bgcolor=\"white\"></td><td bgcolor=\"black\" HEIGHT=\""<<lwd<<"\" COLSPAN=\""<<floor((blocks[j]-blocks[j-1])/skip)+2<<"\"></td><td HEIGHT=\""<<lwd<<"\" WIDTH=\""<<lwd<<"\" bgcolor=\"white\"></td></tr>";
          *out<<"<tr><td HEIGHT=\"5\" COLSPAN=\""<<floor(ma/skip)+4<<"\" bgcolor=\"white\"></td></tr>";
        }
      *out<<"</table>>]"<<endl;
    }

//For standard colouring of the edges
  for (unsigned int a=0;a<s.size();a++) {
      //Clonal frame edges
      if (s[a][2]>=0) {
          int j=s[a][2];
          //if ages(a)==-1;continue;end
          if (clonal[j] && clonal[a])
            *out<<j+1<<" -> "<<a+1<<"[style=bold]"<<endl;
          else
            *out<<j+1<<" -> "<<a+1<<"[color=gray]"<<endl;
        }

      //Recombination edges
      if (s[a][3]>=0) {
          int j=s[a][3];
          //int o=s[a][2];
          //if ages(o)==-1;continue;end
          if (clonal[j] && clonal[a])
            *out<<j+1<<" -> "<<a+1<<"[style=bold]"<<endl;
          else
            *out<<j+1<<" -> "<<a+1<<"[color=gray]"<<endl;
        }
    }
  *out<<"}"<<endl;
}

void Arg::outputLOCAL(ostream * out) {
  unsigned int i=0;
  while (1) {
      string tree=extractLT(i);
      int n=0;
      while (i+1<changeLT.size() && changeLT[i+1]==false) {i++;n++;}
      *out<<"["<<n+1<<"]"<<tree<<endl;
      i++;
      if (i==changeLT.size()) break;
    }
}
