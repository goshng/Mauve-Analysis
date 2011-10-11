//
// File: compute_watterson_estimate.cpp
// Created by: Sang Chul Choi
// Created on: Wed Dec 22 16:01:42 EST 2010
//

#include <Bpp/Seq/Alphabet.all>
#include <Bpp/Seq/Io.all>
#include <iostream>

using namespace bpp;
using namespace std;

int main(int argc, const char * argv[]) {
  //This program reads a protein alignment generated using SimProt
  //[http://www.uhnresearch.ca/labs/tillier/simprotWEB/] in various file formats
  DNA* alpha = new DNA;
  Fasta fasta;
  //cout << argv[1] << endl;
  const SequenceContainer* seqcont1 = fasta.read(argv[1], alpha);

  //Convert to alignments:
  const SiteContainer* sites1 = new VectorSiteContainer(*seqcont1);
  SiteContainer* sites2 = SiteContainerTools::getCompleteSites(*sites1);
  SiteContainer* sites3 = SiteContainerTools::getSitesWithoutGaps(*sites1);
  
  //cout << sites1->getNumberOfSequences() << "\t" << sites1->getNumberOfSites() << endl;
  //cout << sites2->getNumberOfSequences() << "\t" << sites2->getNumberOfSites() << endl;
  //cout << sites3->getNumberOfSequences() << "\t" << sites3->getNumberOfSites() << endl;

  unsigned int numberPolymorphicSites = 0;
  unsigned int lengthAlignment = sites2->getNumberOfSites();
  unsigned int numberSequence = sites2->getNumberOfSequences();
  for (unsigned int i = 0; i < lengthAlignment; i++)
  {
    const Site s = sites2->getSite (i);
    const int c0 = s[0]; 
    for (unsigned int j = 0; j < numberSequence; j++)
    {
      if (c0 != s[j])
      {
        numberPolymorphicSites++;
        break;
      }
    }
    //cout << s.toString() << endl;
  }
  //cout << "L: " << lengthAlignment << endl;
  //cout << "S: " << numberPolymorphicSites << endl;
  //cout << "N: " << numberSequence << endl;

  double d = .0L;
  for (unsigned int i = 0; i < numberSequence - 1; i++)
  {
    d += 1.0L/double (i + 1);
  }
  double w = log (double(lengthAlignment)/double(lengthAlignment - numberPolymorphicSites));
  w /= d;
  w *= lengthAlignment;

  //cout << "Watterson's estimate is " << w << endl;
  cout << w << "\t" << numberPolymorphicSites << "\t" << lengthAlignment << endl;
  //cout << endl;

  delete seqcont1;
  delete sites1;
  delete sites2;
  delete sites3;
  delete alpha;

  return 0;
}
