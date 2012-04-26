# This is for revision.
x <- read.table("output/SPECIESNAME/3/run-analysis/obsiter-recedge-1.txt")
#x <- read.table("output/SPECIESNAME/3/run-analysis/obsiter-recedge-1.txt")
x.exp <- read.table("/Users/goshng/Documents/Projects/Mauve/output/SPECIESNAME/3/run-analysis/exponly-recedge.txt")

# Use this for the submitted version
#x <- read.table("output/cornellf/3/run-analysis/obsiter-recedge-REPLICATE.txt")
#x.exp <- read.table("/Users/goshng/Documents/Projects/Mauve/output/cornellf/3/run-analysis/exponly-recedge-2.txt")

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

# All of the three branches, and their sum
internal.branch.aswell <- function (spy.name, sde.name)
{
  y <- 1:numberBranch

  numberSample <- length(x[,1])
  x.v <- c()
  for (k in 1:numberSample)
  {
    v.spy.sde <- 0
    v.sde.spy <- 0
    for (i in spy.name)
    {
      for (j in sde.name)
      {
        x.donor <- y[Aname == i]
        x.recip <- y[Aname == j]
        spy.sde <- A[x.donor,x.recip]
        x.donor <- y[Aname == j]
        x.recip <- y[Aname == i]
        sde.spy <- A[x.donor,x.recip]
        # cat(spy.sde, sde.spy, x[k,spy.sde], x[k,sde.spy], "\n")
        v.spy.sde <- v.spy.sde + x[k,spy.sde]
        v.sde.spy <- v.sde.spy + x[k,sde.spy]
      }
    }
    x.v <- c(x.v, v.spy.sde/v.sde.spy)
  }

  # Compute the exp. value.
  x.exp.v <- 0
  for (k in 1:1)
  {
    v.spy.sde <- 0
    v.sde.spy <- 0
    for (i in spy.name)
    {
      for (j in sde.name)
      {
        x.donor <- y[Aname == i]
        x.recip <- y[Aname == j]
        spy.sde <- A[x.donor,x.recip]
        x.donor <- y[Aname == j]
        x.recip <- y[Aname == i]
        sde.spy <- A[x.donor,x.recip]
        v.spy.sde <- v.spy.sde + x.exp[k,spy.sde]
        v.sde.spy <- v.sde.spy + x.exp[k,sde.spy]
      }
    }
    x.exp.v <- v.spy.sde/v.sde.spy
  }

  p.val <- sum (x.exp.v > x.v)/length(x.v)
  cat(spy.name, "->", sde.name, "\n")
  cat("For each iteration of ClonalOrigin, or each recombinant tree,\n")
  cat("sum of recombinant edges from SPY branches to SDE branches,\n")
  cat("and sum of recombinant edges from SDE branches to SPY branches,\n")
  cat("Take the ratio of the first to the second. The following quantile is\n")
  cat("0.025, 0.5 or median, 0.0975 quantile values of the ratios of 1001 data points.\n")
  cat("We obtained the ratio for the prior to count how many data points of the\n")
  cat("1001 values less than the ratio for the prior.\n")
  cat("The p-value is the fraction of them.\n")
  cat("Quantile (0.025, 0.5 or median, 0.975) is", quantile(x.v,  probs = c(0.025, 0.5, 0.975)), "\n")
  cat("Mean is", mean(x.v), "\n")
  cat("The exp value is", x.exp.v, "\n")
  cat("The P value is", p.val, "\n\n")
  # x.v
}

# External branches, not sum but ratios
# SDE1 <-> SPY1
external.branch.only <- function ()
{
  y <- 1:numberBranch
  spy.name <- c("SPY1", "SPY2")
  sde.name <- c("SDE1", "SDE2")

  numberSample <- length(x[,1])
  x.v <- c()
  for (k in 1:numberSample)
  {
    for (i in spy.name)
    {
      for (j in sde.name)
      {
        x.donor <- y[Aname == i]
        x.recip <- y[Aname == j]
        spy.sde <- A[x.donor,x.recip]
        x.donor <- y[Aname == j]
        x.recip <- y[Aname == i]
        sde.spy <- A[x.donor,x.recip]
        # cat(spy.sde, "vs.", sde.spy, "\n")
        v <- x[k,spy.sde]/x[k,sde.spy]
        x.v <- c(x.v,v)
        # cat(v,"\t",sep="")
      }
    }
    # cat("0\n")
  }
  x.exp.v <- 17.2146947/7.8732323 
  p.val <- sum (x.exp.v > x.v)/length(x.v)
  cat("All of external branches:\n")
  cat("For each recombinant tree out of 1001, we take the ratio of number\n")
  cat("of recombinant edges from 2 SPY to 2 SDE to number of edges from\n")
  cat("2 SDE to 2 SPY. The 4004 data points have the following quantiles\n")
  cat("of 0.025, 0.5 or median, 0.975. We counted how many of the 4004\n")
  cat("are less than the ratio for the prior.\n")
  cat("Quantile (0.025, 0.5 or median, 0.975) is", quantile(x.v,  probs = c(0.025, 0.5, 0.975)), "\n")
  cat("The exp value is", x.exp.v, "\n")
  cat("The P value is", p.val, "\n\n")

  for (i in spy.name)
  {
    for (j in sde.name)
    {
      x.v <- c()
      for (k in 1:numberSample)
      {
        x.donor <- y[Aname == i]
        x.recip <- y[Aname == j]
        spy.sde <- A[x.donor,x.recip]
        x.donor <- y[Aname == j]
        x.recip <- y[Aname == i]
        sde.spy <- A[x.donor,x.recip]
        # cat(spy.sde, "vs.", sde.spy, "\n")
        v <- x[k,spy.sde]/x[k,sde.spy]
        x.v <- c(x.v,v)
        # cat(v,"\t",sep="")
      }
      p.val <- sum (x.exp.v > x.v)/length(x.v)
      cat(i, "->", j, "external branches:\n")
      cat("For each recombinant tree out of 1001, we take the ratio of number\n")
      cat("of recombinant edges from,", i, "to", j, "to number of edges from\n")
      cat(j, "to", i, "The 1001 data points have the following quantiles\n")
      cat("of 0.025, 0.5 or median, 0.975. We counted how many of the 1001\n")
      cat("are less than the ratio for the prior.\n")
      cat("Quantile (0.025, 0.5 or median, 0.975) is", quantile(x.v,  probs = c(0.025, 0.5, 0.975)), "\n")
      cat("The exp value is", x.exp.v, "\n")
      cat("The P value is", p.val, "\n\n")
    }
  }
}

spy.name <- c("SPY1", "SPY2", "SPY")
sde.name <- c("SDE1", "SDE2", "SDE")
internal.branch.aswell(spy.name, sde.name)
spy.name <- c("SPY1", "SPY2")
sde.name <- c("SDE1", "SDE2")
internal.branch.aswell(spy.name, sde.name)
external.branch.only() 
