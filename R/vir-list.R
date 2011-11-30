x <- read.table("/Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/ri-virulence-list.out")
y <- read.table("output/virulence/virulent_genes.txt.spy1")
gene.desc <- read.table("output/cornellf/3/run-analysis/in.gene.description",sep="\t")
y <- y$V1
z <- x[x[,2]==1,1] %in% y

numberBranch <- 9
numberElement <- numberBranch * numberBranch 
A <- matrix(seq(1,81),nrow = 9, ncol = 9, byrow = TRUE)
B <- A
indexReorder <- c(0,5,1,7,2,8,3,6,4) + 1
for (i in 1:numberBranch)
{
  for (j in 1:numberBranch)
  {
    A[i,j] <- B[indexReorder[i],indexReorder[j]]
  }
}
Aname <- c("SDE1", "SDE", "SDE2", "SD", "SDD", "ROOT", "SPY1", "SPY", "SPY2")
Bname <- c("SDE1", "SDE2", "SDD", "SPY1", "SPY2", "SDE", "SPY", "SD", "ROOT")

listGeneByFraction <- function() {
  x50 <- x[x[,2]==50,]
  x50 <- x50[z,]
  # for (i in 3:83)
  for (i in 3:74)
  {
    x50o <- x50[order(x50[,i],decreasing=TRUE),] 
    r.gene <- x50o[x50o[,i] > 0,1]
    r.frac <- x50o[x50o[,i] > 0,i] 
    r <- data.frame(gene=r.gene,frac=r.frac)
    if (length(r.gene) > 0)
    {
      # 10 %% 9
      # trunc(10/9)
      x.donor <- trunc((i - 2 - 1) / 9) + 1
      x.recip <- ((i - 2 - 1) %% 9) + 1
      # Direction Fraction Gene Description
      # print (paste(i-2, "Donor", Bname[x.donor], "Recip", Bname[x.recip]))
      # print (r)
      cat(Bname[x.donor], "-to-", Bname[x.recip], sep="")
      for (k in 1:length(r.gene))
      {
        gene.what <- gene.desc[,2][gene.desc[,1] == as.character(r[k,]$gene)]
        cat(" & ", round(r[k,]$frac,digits=2), " & ", as.character(r[k,]$gene), " & ", as.character(gene.what), "\\\\\n", sep="")
      }
    }
  }
}

listGeneByFraction ()

threshouldVsPval <- function() {
oldpar <- par(mfrow=c(9,9), mar=c(0.1,0.1,0.1,0.1))
for (i in 3:83)
{
  pvalue <- c()
  pvalue.x <- c()
  for (j in 1:99)
  {
    r <- wilcox.test(x[x[,2]==j,i][!z], x[x[,2]==j,i][z], alternative = "greater")
    pvalue <- c(pvalue, r$p.value)
    pvalue.x <- c(pvalue.x, j/100)
  }
  plot(-1,-1,ann=FALSE,axes=FALSE,xlim=c(0,1),ylim=c(0,1))
  pvalue.small <- pvalue < 0.05
  points(pvalue.x[!pvalue.small],pvalue[!pvalue.small],cex=0.05)
  points(pvalue.x[pvalue.small],pvalue[pvalue.small],cex=0.1,col="red")
  # Axis(side=1, labels=FALSE)
  # Axis(side=2, labels=FALSE)
  box()
}
par(oldpar)
}

# threshouldVsPval()
