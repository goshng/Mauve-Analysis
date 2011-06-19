function manuscript {
  SPECIES=cornellf
  REPETITION=3
  set-more-global-variable $SPECIES $REPETITION
  CLONALFRAMEREPLICATE=1
  RUNID=1
  MANUSCRIPTOUTPUT=manuscript/output
  manuscript-sequence-alignment
  manuscript-watterson
  manuscript-tree
}

function manuscript-sequence-alignment {
  OUT=manuscript/$FUNCNAME.txt
  COREXMFA=$DATADIR/core_alignment.xmfa
  cp -p $COREXMFA $MANUSCRIPTOUTPUT
  echo "$COREXMFA is copied to $MANUSCRIPTOUTPUT"

  XMFA=$RUNANALYSIS/summary-core-alignment.txt
  TOTALLENGTH=$(grep ^TotalLengthOfCoreAlignment $XMFA | cut -d":" -f2)
  echo "Total length of the core alignment is $TOTALLENGTH" > $OUT
  NUMBERBLOCK=$(grep ^NumberOfBlock $XMFA | cut -d":" -f2)
  echo "Total number of the blocks is $NUMBERBLOCK" >> $OUT

  # Plot
  BLOCKSIZE_HISTOGRAM_PDF=manuscript/output/blocksize.pdf
  BLOCKSIZE_HISTOGRAM_PS=manuscript/output/blocksize.ps
  BLOCKSIZE=$(grep ^BlockSize $XMFA | cut -d":" -f2)
  RTEMP=$RANDOM.R
  TXTTEMP=$RANDOM.txt
  echo $BLOCKSIZE > $TXTTEMP
cat>$RTEMP<<EOF
x <- scan("$TXTTEMP")
pdf ("$BLOCKSIZE_HISTOGRAM_PDF",  width=10, height=10, onefile = FALSE, paper = "special")
hist(x, breaks=20, xlab="Block Sizes", main="", xlim=c(0,20000))
dev.off()
postscript ("$BLOCKSIZE_HISTOGRAM_PS",  width=10, height=10, horizontal = FALSE, onefile = FALSE, paper = "special")
hist(x, breaks=20, xlab="Block Sizes", main="", xlim=c(0,20000))
dev.off()
EOF
  Rscript $RTEMP
  rm $RTEMP
  rm $TXTTEMP
  echo "Generating plots $BLOCKSIZE_HISTOGRAM_PS and $BLOCKSIZE_HISTOGRAM_PDF"

  cat $OUT
  echo -e "END of $FUNCNAME\n"
}


function manuscript-watterson {
  OUT=manuscript/$FUNCNAME.txt
  RUNLOG=$RUNANALYSIS/run.log
  WATTERSON_ESTIMATE=$(grep "^Watterson estimate" $RUNLOG | cut -d":" -f2)
  echo "Watterson estimate is $WATTERSON_ESTIMATE" > $OUT

  cat $OUT
  echo -e "END of $FUNCNAME\n"
}

function manuscript-tree {
  TREE=manuscript/species.tre
  perl pl/getClonalTree.pl \
    $RUNCLONALFRAME/output/${CLONALFRAMEREPLICATE}/core_clonalframe.out.${RUNID} \
    $TREE
  sed -i '' -e's/1:/SDE1:/' $TREE
  sed -i '' -e's/2:/SDE2:/' $TREE
  sed -i '' -e's/6:/SDE:/'  $TREE
  sed -i '' -e's/3:/SDD:/'  $TREE
  sed -i '' -e's/8:/SD:/'   $TREE
  sed -i '' -e's/4:/SPY1:/' $TREE
  sed -i '' -e's/5:/SPY2:/' $TREE
  sed -i '' -e's/7:/SPY:/'  $TREE
  sed -i '' -e's/9:/ROOT:/' $TREE
  echo "The species tree is in $TREE"
  cat $TREE
  echo "Use FigTree to create the PDF and PS versions of the tree!"
  echo -e "END of $FUNCNAME\n"
}
