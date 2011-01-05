/*
 * File: ExSequence.cpp
 * Created by: Julien Dutheil
 * Created on: Dec Tue 03 17:13 2008
 * Last modified: Dec Tue 03 17:13 2008
 * 
 * Introduction to the Sequence class.
 *
 * HOW TO USE THAT FILE:
 * - General comments are written using the * * syntaxe.
 * - Code lines are switched off using '//'. To activate those lines, just remove the '//' characters!
 * - You're welcome to extensively modify that file!
 */

/*----------------------------------------------------------------------------------------------------*/

/*
 * We start by including what we'll need, and sort the inclusions a bit:
 */

/*
 * From the STL:
 */
#include <iostream> //to be able to output stuff in the terminal.

/*
 * We'll use the standard template library namespace:
 */
using namespace std;

/*
 * From SeqLib:
 */
//#include <Seq/alphabets> /* this include all alphabets in one shot */
#include <Seq/Sequence.h> /* this include the definition of the Sequence object */
#include <Seq/SequenceTools.h> /* this include some tool sto deal with sequences */
#include <Seq/DNAToRNA.h> /* A few translators here... */
#include <Seq/NucleicAcidsReplication.h>
//#include <Seq/StandardGeneticCode.h>

/*
 * All Bio++ functions are also in a namespace, so we'll use it:
 */
using namespace bpp;

/*----------------------------------------------------------------------------------------------------*/
/*
 * Now starts the real stuff...
 */


int main(int args, char ** argv)
{
  /*
   * We surround our code with a try-catch block, in case some error occurs:
   */
  try
  {
    cout << "Hello World!" << endl;

    /*
     * A key set of objects in Bio++ is the Alphabet family.
     * Here is how to get one of those:
     */
    //Sequence *sequence = new Sequence("my first sequence", "GATTACAATGATTACATGGT", &AlphabetTools::DNA_ALPHABET);
    //cout << sequence->getName() << endl;
    //cout << sequence->toString() << endl;
    //cout << sequence->size() << " positions." << endl;

    /*
     * Accessing the single positions:
     */
//    for(unsigned int i = 0; i < sequence->size(); i++)
//    {
//      cout << sequence->getChar(i) << endl;
//    }
    
    /* ----------------
     * QUESTION 1: write a simple code that draws a dot-plot in the terminal
     * (for two short sequences).
     * ----------------
     */

    /*
     * Sequence object are derived from a more general structure called SymbolList.
     * Nothing really important here, you just have to know that the Site objects, that we'll
     * meet later, are also SymbolList objects. Hence all methods presented here will
     * also work with Site objects.
     */
//    Sequence * seq1 = sequence->clone();
//    Sequence * seq2 = sequence->clone();
//    seq2->deleteElement(4);
//    Sequence * seq3 = sequence->clone();
//    seq3->addElement(4, "T");
//    Sequence * seq4 = sequence->clone();
//    seq4->setElement(4, "A");

//    cout << "Seq1: " << seq1->toString() << endl;
//    cout << "Seq2: " << seq2->toString() << endl;
//    cout << "Seq3: " << seq3->toString() << endl;
//    cout << "Seq4: " << seq4->toString() << endl;

    /*
     * A bit of cleaning...
     */
//    delete seq1;
//    delete seq2;
//    delete seq3;
//    delete seq4;
    
    /* ----------------
     * QUESTION 2: be sure to understand the code written so far!
     * Check:
     * - what is the position of the first element in the sequence?
     * - what happens if you try to insert an Uracile nucleotide in a DNA sequence?
     * - look at the online documentation for Sequence object, their are additional methods available...
     * ----------------
     */

    /*
     * Now we'll see what we can do with sequences...
     *
     * Several methods are available in the SequenceTools static class.
     * 'static' mean that this class can be used without any instance, you can just call
     * directly any of their method. In bio++, there are several {*}Tools class which are all static,
     * and deal with particular data structures. There is also a SiteTools for instance, and a CodonSiteTools.
     * These three classes inherit from the general SymbolListTools class, and add more specialized functions.
     */
//    Sequence* subSequence = SequenceTools::subseq(*sequence, 6, 8);
//    cout << "SubSeq: " << subSequence->toString() << endl;
//    delete subSequence;

//    Sequence* reverseSequence = SequenceTools::reverse(*sequence);
//    cout << "RevSeq: " << reverseSequence->toString() << endl;
//    double idty = SequenceTools::getPercentIdentity(*sequence, *reverseSequence);
//    cout << "Is that a palyndrome? "<< idty << endl;
//    delete reverseSequence;

    /*
     * We'll now do a bit of /in silico/ molecular biology.
     * Basically, this means decoding/recoding sequences according to given alphabets.
     *
     * First we need to understand how sequences are coded.
     * A sequence (or a site) is coded as a vector of int codes, and the correspondance between 
     * int code and the actual character string is ensured by the Alphabet object (see previous exercise).
     * So when you create a Sequence object from a string, you are actually *parsing* its content.
     * Try the following:
     */
//    cout << "This sequence is coded with a " << sequence->getAlphabet()->getAlphabetType() << endl;
//    for(unsigned int i = 0; i < sequence->size(); i++)
//    {
//      cout << sequence->getChar(i) << "\t" << sequence->getValue(i) << "\t" << (*sequence)[i] << endl;
//    }

    /*
     * To change the Alphabet of a sequence, you need to decode and recode it:
     */
//    Sequence * protSequence = new Sequence(sequence->getName(), sequence->toString(), &AlphabetTools::PROTEIN_ALPHABET);
//    cout << "This sequence is now coded with a " << protSequence->getAlphabet()->getAlphabetType() << endl;
//    delete protSequence;

//    Sequence * rnaSequence = new Sequence(sequence->getName(), sequence->toString(), &AlphabetTools::RNA_ALPHABET);
//    cout << "This sequence is now coded with a " << rnaSequence->getAlphabet()->getAlphabetType() << endl;
//    delete rnaSequence;

//    CodonAlphabet *codonAlphabet = new StandardCodonAlphabet(&AlphabetTools::DNA_ALPHABET);
//    Sequence * codonSequence = new Sequence(sequence->getName(), sequence->toString(), codonAlphabet);
//    cout << "This sequence is now coded with a " << codonSequence->getAlphabet()->getAlphabetType() << endl;
//    for(unsigned int i = 0; i < codonSequence->size(); i++)
//    {
//      cout << codonSequence->getChar(i) << "\t" << codonSequence->getValue(i) << endl;
//    }
//    delete codonSequence;
//    delete codonAlphabet;

    /*
     * To make more complexe deparsing/reparsing, you need *Translator* objects.
     * These objects allow you convert from an alphabet to another in a very general way.
     *
     * Example 1: changing DNA to RNA:
     */

//    Translator* translator = new DNAToRNA();
//    Sequence *trSequence = translator->translate(*sequence);
//    cout << "Original  : " << sequence->toString() << endl;
//    cout << "Translated: " << trSequence->toString() << endl;
//    delete trSequence;
//    delete translator;

    /*
     * Example 2: getting the complement of sequence, in the same alphabet:
     */
//    translator = new NucleicAcidsReplication(&AlphabetTools::DNA_ALPHABET, &AlphabetTools::DNA_ALPHABET);
//    trSequence = translator->translate(*sequence);
//    cout << "Original  : " << sequence->toString() << endl;
//    cout << "Translated: " << trSequence->toString() << endl;
//    delete trSequence;
//    delete translator;
    
    /*
     * Example 3: The same but with an RNA complement:
     */
//    translator = new NucleicAcidsReplication(&AlphabetTools::DNA_ALPHABET, &AlphabetTools::RNA_ALPHABET);
//    trSequence = translator->translate(*sequence);
//    cout << "Original  : " << sequence->toString() << endl;
//    cout << "Translated: " << trSequence->toString() << endl;
//    delete trSequence;
//    delete translator;
    
    /* ----------------
     * QUESTION 3: Using what you've learnt, and using the documentation of Bio++, translates the Sequence object 'sequence' into a protein sequence.
     * ----------------
     */

    
  }
  catch(Exception& e)
  {
    cout << "Bio++ exception:" << endl;
    cout << e.what() << endl;
    return(-1);
  }
  catch(exception& e)
  {
    cout << "Any other exception:" << endl;
    cout << e.what() << endl;
    return(-1);
  }

  return(0);
}

