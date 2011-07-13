# SPECIES, REPETITION, REPLICATE are three variables that need to be specified.
# The following variables should be chosen by considering ClonalFrame runs.
# CLONALFRAMEREPLICATE=1
# RUNID=1
function manuscript {
  SPECIES=cornellf
  REPETITION=3
  REPLICATE=1
  set-more-global-variable $SPECIES $REPETITION
  CLONALFRAMEREPLICATE=1
  RUNID=1
  MANUSCRIPTOUTPUT=manuscript/output
  # manuscript-core-alignment
  # manuscript-sequence-alignment
  # manuscript-watterson
  # manuscript-clonalframe
  # manuscript-tree
  # manuscript-heatmap
  # manuscript-summarize-clonalorigin-first
  # manuscript-keynotes
  # manuscript-simulation-clonalorigin1
  # manuscript-simulation-clonalorigin2
  # manuscript-probability-recedge
  # manuscript-tree-topology
  # manuscript-functional-category
  cp $MANUSCRIPTOUTPUT/*.eps doc/figures/
}

# ClonalFrame estimated the relative strength of recombination
# compared to mutations to be $r/m = 4.66$, indicating 
# that reconmination-driven substitutions affected more 
# sites than did mutation-driven substitutions. The first stage of ClonalOrigin 
function manuscript-clonalframe {
  CLONALFRAMEOUT=$RUNCLONALFRAME/output/${CLONALFRAMEREPLICATE}/core_clonalframe.out.${RUNID}
  echo "Use ClonalFrame GUI to read $CLONALFRAMEOUT"
  echo "Find values of r/m using ClonalFrame GUI"
  echo -e "END of $FUNCNAME\n"
}

# The number of blocks is 274.
function manuscript-core-alignment {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT
  XMFA=$DATADIR/core_alignment.xmfa
  NUMBERBLOCK=$(trim $(grep "=" $XMFA | wc -l ))
  echo "Total number of the blocks is $NUMBERBLOCK" >> $OUT
  echo -e "END of $FUNCNAME\n"
}

# The species tree of the five genomes is shown in Figure S\ref{fig:tree5}, which
# was estimated using 274 blocks of the core genome alignments with ClonalFrame. 
# Figure S\ref{fig:blocksize} shows the distribution of block lengths. The average
# length was 4215 bp.
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
  BLOCKSIZE_HISTOGRAM_PS=manuscript/output/blocksize.eps
  BLOCKSIZE=$(grep ^BlockSize $XMFA | cut -d":" -f2)
  RTEMP=$RANDOM.R
  TXTTEMP=$RANDOM.txt
  echo $BLOCKSIZE > $TXTTEMP
cat>$RTEMP<<EOF
x <- scan("$TXTTEMP",quiet=TRUE)
pdf ("$BLOCKSIZE_HISTOGRAM_PDF",  width=10, height=10, onefile = FALSE, paper = "special")
hist(x, breaks=20, xlab="Block Sizes", main="", xlim=c(0,20000))
y <- dev.off()
postscript ("$BLOCKSIZE_HISTOGRAM_PS",  width=10, height=10, horizontal = FALSE, onefile = FALSE, paper = "special")
hist(x, breaks=20, xlab="Block Sizes", main="", xlim=c(0,20000))
y <- dev.off()
y <- mean(x)
cat ("The average of the block lengths is ", y, "\n",sep="")
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  rm $TXTTEMP
  echo "Generated plots $BLOCKSIZE_HISTOGRAM_PS and $BLOCKSIZE_HISTOGRAM_PDF"
  echo "The content of $OUT is"
  echo "----"
  cat $OUT
  echo "----"

  cp $BLOCKSIZE_HISTOGRAM_PDF doc/figures
  cp $BLOCKSIZE_HISTOGRAM_PS doc/figures
  echo "Copied $BLOCKSIZE_HISTOGRAM_PDF and $BLOCKSIZE_HISTOGRAM_PS to doc/figures"
  echo -e "END of $FUNCNAME\n"
}


function manuscript-watterson {
  OUT=manuscript/$FUNCNAME.txt
  RUNLOG=$RUNANALYSIS/run.log
  echo "Reading $RUNLOG"
  WATTERSON_ESTIMATE=$(trim $(grep "^Watterson estimate" $RUNLOG | cut -d":" -f2))
  echo "Watterson estimate is $WATTERSON_ESTIMATE" > $OUT

  cat $OUT
  echo -e "END of $FUNCNAME\n"
}

# The species tree of the five genomes is shown in Figure S\ref{fig:tree5}.
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

# We need the following R packages to be installed.
# library(colorspace)
# library(gplots)
# Edit the following script to plot a heat map with correct orders. Change the
# following variables:
# NUMBERBRANCH=9
# indexReorder <- c(0,5,1,7,2,8,3,6,4) + 1
# Aname <- c("SDE1", "SDE", "SDE2", "SD", "SDD", "ROOT", "SPY1", "SPY", "SPY2")
function manuscript-heatmap {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT
  NUMBERSPECIES=5
  NUMBERBRANCH=9
  HEATMAPMATRIX=$RUNANALYSIS/heatmap-recedge-${REPLICATE}.txt
  OBSONLYMATRIX=$RUNANALYSIS/obsonly-recedge-${REPLICATE}.txt

  OUTPDF=manuscript/output/heatmap.pdf
  OUTEPS=manuscript/output/heatmap.eps
  RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
numberBranch <- $NUMBERBRANCH
numberElement <- numberBranch * numberBranch 
A <- matrix(scan("$HEATMAPMATRIX", n=numberElement), numberBranch, numberBranch, byrow = TRUE)
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    if (A[i,j] == 0)
    {
      A[i,j] <- NA
    }
    else
    {
      A[i,j] <- log2(A[i,j])
    }
  }
}

B <- A
indexReorder <- c(0,5,1,7,2,8,3,6,4) + 1
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    A[i,j] <- B[indexReorder[i],indexReorder[j]]
  }
}

library(colorspace)
library(gplots)

Aname <- c("SDE1", "SDE", "SDE2", "SD", "SDD", "ROOT", "SPY1", "SPY", "SPY2")

# b<-seq(-max(abs(A))-0.1,max(abs(A))+0.1,length.out=42)
#pdf("heatmap.pdf", height=10, width=10)

b<-seq(-2.2,2.2,length.out=42)
postscript("$OUTEPS", width=10, height=10, horizontal = FALSE, onefile = FALSE, paper = "special")

heatmap.2(A,
  Rowv=FALSE,
  Colv=FALSE,
  dendrogram= c("none"),
  distfun = dist,
  hclustfun = hclust,
  xlab = "", ylab = "",
  key=TRUE,
  keysize=1,
  trace="none",
  density.info=c("none"),
  margins=c(10, 8),
  breaks=b,
  col=diverge_hcl(41),
  na.color="green",
  labRow=Aname,
  labCol=Aname
)
y <- dev.off()

print (A)
  
A <- matrix(scan("$OBSONLYMATRIX", n=numberElement, quiet=TRUE), numberBranch, numberBranch, byrow = TRUE)
B <- A
indexReorder <- c(0,5,1,7,2,8,3,6,4) + 1
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    A[i,j] <- B[indexReorder[i],indexReorder[j]]
  }
}
print (A)
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  cp $OUTEPS $MANUSCRIPTOUTPUT
  echo "Copied $OUTEPS to $MANUSCRIPTOUTPUT"
  echo "Open Keynote file doc/mauve-analysis.key to create a figure $OUTEPS"
  echo -e "END of $FUNCNAME\n"
}

# The median of mutation
# rate per site weighted over the lengths of blocks was estimated to
# be 0.081 with (0.067,0.094) of interquartile range (IQR). Mutation rates
# per site for many alignment blocks were almost centered around the
# gobal median. The median of recombination rate per site was estimated
# to be 0.012 with (0.006,0.019) of IQR.
# The median value for the recombinant tract length was estimated
# to be 744 base pairs with (346,2848) of IQR. 
# The estimates of the three parameters were based on one of two independent
# MCMC chains. 
# The estimates from the second MCMC run were close to those of
# the first run: mutation rate estimate of 0.081 with IQR of (0.067,0.099),
# recombination rate of 0.012 with IQR of (0.006,0.020), and recombinant tract
# length estimate of 723 with IQR of (348,2870).
function manuscript-summarize-clonalorigin-first {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT

  echo "This results from menu summarize-clonalorigin1"
  UNFINISHED=$RUNCLONALORIGIN/summary/${REPLICATE}/unfinished
  MEDIAN=$RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
  echo "The content of $UNFINISHED is"
  echo "----"
  cat $UNFINISHED
  echo "----"
  echo "The content of $MEDIAN is"
  echo "----"
  cat $MEDIAN
  echo "----"
  cp $UNFINISHED manuscript/
  cp $MEDIAN manuscript/
  echo "Copied $UNFINISHED to manuscript"
  echo "Copied $MEDIAN to manuscript"

  cp $RUNANALYSIS/scatter-plot-parameter-$REPLICATE-out-theta.eps manuscript/output/
  cp $RUNANALYSIS/scatter-plot-parameter-$REPLICATE-out-rho.eps manuscript/output/
  cp $RUNANALYSIS/scatter-plot-parameter-$REPLICATE-out-delta.eps manuscript/output/
  echo "Copied the three scatter-plot-parameter figures to manuscript/output"

  echo "This results from menu summarize-clonalorigin1"
  REPLICATE=2
  UNFINISHED=$RUNCLONALORIGIN/summary/${REPLICATE}/unfinished
  MEDIAN=$RUNCLONALORIGIN/summary/${REPLICATE}/median.txt
  echo "The content of $UNFINISHED is"
  echo "----"
  cat $UNFINISHED
  echo "----"
  echo "The content of $MEDIAN is"
  echo "----"
  cat $MEDIAN
  echo "----"
  cp $UNFINISHED manuscript/$(basename $UNFINISHED)-$REPLICATE
  cp $MEDIAN manuscript/$(basename $MEDIAN)-$REPLICATE
  echo "Copied $UNFINISHED-$REPLICATE to manuscript"
  echo "Copied $MEDIAN-$REPLICATE to manuscript"

  echo -e "END of $FUNCNAME\n"
}

# open manuscript.key
# export to a pdf file.
# Then, run this script
function splitpdf {
  gs -sDEVICE=pdfwrite \
    -q -dNOPAUSE -dBATCH \
    -sOutputFile=figure$1.pdf \
    -dFirstPage=$1 \
    -dLastPage=$1 \
    manuscript/output/mauve-analysis.pdf
}
function manuscript-keynotes {
  for i in {1..2}; do
    splitpdf $i
    pdf2ps figure$i.pdf figure$i.eps
    rm figure$i.pdf
  done

  mv figure1.eps manuscript/output/
  mv figure2.eps manuscript/output/
  echo "Figures are generated from the keynote manuscript/output/mauve-analysis.pdf"
}

# s15
function manuscript-simulation-clonalorigin1 {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT
  SIMULATIONDIR=output/s15/run-analysis

  RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
x <- read.table("$SIMULATIONDIR/out.summary")
summary(x)
sd(x)
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  echo "The content of $OUT is"
  echo "----"
  cat $OUT
  echo "----"
  echo -e "END of $FUNCNAME\n"
}

# s16
function manuscript-simulation-clonalorigin2 {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT
  SIMULATIONDIR=output/s16/run-analysis

  # The second figures.
  OUTEPS1=manuscript/output/h1-R.eps
  OUTEPS2=manuscript/output/h1-R-inset.eps
  RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
library(plotrix) 
x <- read.table("$SIMULATIONDIR/s16-heatmap.txt")
y <- read.table("$SIMULATIONDIR/s16-yes-heatmap.txt")

for (i in 1:81) {
  v <- round(mean(x[,i]) - mean(y[,i]),digit=3)
  s <- mean(x[,i+81])
  supper <- round(mean(x[,i]) + 2*s,digit=3) 
  slower <- round(mean(x[,i]) - 2*s,digit=3) 
  if ( mean(y[,i]) < slower || mean(y[,i]) > supper ) {
    print (paste(i,"not okay"))
  } 
  print (paste(sep="     ", i,round(mean(y[,i]),digit=3),round(mean(x[,i]),digit=3),v,round(s,digit=3),slower,supper))
}

cix <- c()
ciy <- c()
ciyliw <- c()
ciyuiw <- c()
for (i in 1:81) {
  if (mean(y[,i]) > 0)
  {
    cix <- c(cix,mean(y[,i]))
    a <- as.vector(quantile(x=x[,i],probs=c(0.05,0.5,0.95)))
    ciyliw <- c(ciyliw,a[2]-a[1])
    ciy <- c(ciy,a[2])
    ciyuiw <- c(ciyuiw,a[3]-a[2])
  }
}

# Draw the main figure.
xmax <- max(cix,ciy) + 1
insetsize <- 300
postscript("$OUTEPS1", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(4, 4, 0.5, 0.5))
plotCI(cix,ciy,uiw=ciyuiw,liw=ciyliw,main="",xlab="True",ylab="Estimate",xlim=c(0,xmax),ylim=c(0,xmax),pch=20)
abline(a=0,b=1,lty="dotted")
lines(c(0,insetsize,insetsize,0,0),c(0,0,insetsize,insetsize,0),lty="longdash")
par(oldpar)
dev.off()

# Draw the inset figure.
xmax <- insetsize
postscript("$OUTEPS2", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(4, 4, 0.5, 0.5))
plotCI(cix,ciy,uiw=ciyuiw,liw=ciyliw,main="",xlab="True",ylab="Estimate",xlim=c(0,xmax),ylim=c(0,xmax),pch=20)
abline(a=0,b=1,lty="dotted")
par(oldpar)
dev.off()
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  echo "Created $OUTEPS1 and $OUTEPS2 to $MANUSCRIPTOUTPUT"

  # The second figures.
  OUTEPS1=manuscript/output/h2-R.eps
  OUTEPS2=manuscript/output/h2-R-inset.eps
  OUTEPS3=manuscript/output/h2-R-inset2.eps
  RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
library(plotrix)
x <- read.table("$SIMULATIONDIR/s16-heatmap.txt")
z <- read.table("$RUNANALYSIS/obsonly-recedge-$REPLICATE.txt")

for (i in 1:81) {
  v <- round(z[,i] / mean(x[,i]),digit=3)
  sz <- z[,i+81]
  sx <- mean(x[,i+81])

  if (z[,i] == 0)
  {
    yi <- 0
  }
  else
  {
    y <- c(z[,i], x[,i])
    yi <- round((which(sort(y) == z[,i]) - 1) / length(x[,i]),digit=3)
  }
  print (paste(sep="     ", i,round(z[,i],digit=3),round(mean(x[,i]),digit=3),v,yi,round(sz,digit=3),round(sx,digit=3)))
}

cix <- c()
ciy <- c()
ciyliw <- c()
ciyuiw <- c()
for (i in 1:81) {
  if (z[,i] > 0)
  {
    cix <- c(cix,z[,i])
    a <- as.vector(quantile(x=x[,i],probs=c(0.05,0.5,0.95)))
    ciyliw <- c(ciyliw,a[2]-a[1])
    ciy <- c(ciy,a[2])
    ciyuiw <- c(ciyuiw,a[3]-a[2])
  }
}

# Draw the main figure.
insetsize <- 200
xmax <- max(cix,ciy) + 1
postscript("$OUTEPS1", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(4, 4, 0.5, 0.5))
plotCI(cix,ciy,uiw=ciyuiw,liw=ciyliw,main="",xlab="Real",ylab="Simulated",xlim=c(0,xmax),ylim=c(0,xmax),pch=20)
abline(a=0,b=1,lty="dotted")
lines(c(0,insetsize,insetsize,0,0),c(0,0,insetsize,insetsize,0),lty="longdash")
par(oldpar)
dev.off()

# Draw the inset figure.
insetsize <- 15
xmax <- 200
postscript("$OUTEPS2", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(4, 4, 0.5, 0.5))
plotCI(cix,ciy,uiw=ciyuiw,liw=ciyliw,main="",xlab="Real",ylab="Simulated",xlim=c(0,xmax),ylim=c(0,xmax),pch=20)
abline(a=0,b=1,lty="dotted")
lines(c(0,insetsize,insetsize,0,0),c(0,0,insetsize,insetsize,0),lty="longdash")
par(oldpar)
dev.off()

# Draw another inset figure.
xmax <- 15
postscript("$OUTEPS3", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(4, 4, 0.5, 0.5))
plotCI(cix,ciy,uiw=ciyuiw,liw=ciyliw,main="",xlab="Real",ylab="Simulated",xlim=c(0,xmax),ylim=c(0,xmax),pch=20)
abline(a=0,b=1,lty="dotted")
par(oldpar)
dev.off()
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  echo "Created $OUTEPS1, $OUTEPS2, and $OUTEPS3 to $MANUSCRIPTOUTPUT"

  # The third figure.
  OUTEPS1=manuscript/output/ri-R.eps
  RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
x <- read.table ("$SIMULATIONDIR/ri.txt")
postscript("$OUTEPS1", width=6, height=6, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(5, 4, 0.5, 0.5))
plot (x\$V2, x\$V3, xlim=c(0,9), ylim=c(0,9),cex=0.2, xlab="True", ylab="Estimate",main="")
abline(a=0,b=1,lty=2)
par(oldpar)
dev.off()
cor(x\$V2,x\$V3)
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  echo "Created $OUTEPS1 to $MANUSCRIPTOUTPUT"

  echo -e "END of $FUNCNAME\n"
}

# Menu probability-recedge-gene must be called before.
# Execute menu *probability-recedge-gene*
# This generates a table of genes and their fragments transferred
# not the posterior probability of recombination along the ref. genome.
# Menu recombination-intensity1-probability
function manuscript-probability-recedge {
  
  echo -e "END of $FUNCNAME\n"
}

# map-tree-topology
# There is a part of extracting tree topologies.
function manuscript-tree-topology {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT 
  OUTEPS1=manuscript/output/ri-R.eps
  RTEMP=$RANDOM.R
cat>$RTEMP<<EOF
x <- scan ("$RUNANALYSIS/ri-$REPLICATE-combined.all", quiet=TRUE)

y <- unlist(lapply(split(x,f=x),length)) 

y.sorted <- sort(y, decreasing=T)

# print(y.sorted)

y.sum <- sum(y)

for (i in 1:8)
{
  print(y.sorted[i]/y.sum*100)
}
EOF
  Rscript $RTEMP >> $OUT
  rm $RTEMP
  echo "The content of $OUT is"
  echo "----"
  cat $OUT
  echo "----"
  echo -e "END of $FUNCNAME\n"
}

function manuscript-functional-category {
  OUT=manuscript/$FUNCNAME.txt
  rm -f $OUT 

  echo -e "END of $FUNCNAME\n"
}
