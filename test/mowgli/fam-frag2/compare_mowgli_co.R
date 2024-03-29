x <- read.table("compare_mowgli_co.txt")
postscript("compareMowgliCoRecombining.ps", width=10, height=10, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(5, 5, 0.5, 0.5))
plot (x$V2, x$V3, xlab="Recombination intensity", ylab="Number of recombining gene transfer", cex.lab=2, cex.axis=2)
par(oldpar)
dev.off()
cor(x$V2,x$V3)
cor.test(x$V2,x$V3)

postscript("compareMowgliCoHgt.ps", width=10, height=10, horizontal = FALSE, onefile = FALSE, paper = "special")
oldpar <- par (mar=c(5, 5, 0.5, 0.5))
plot (x$V2, x$V4, xlab="Recombination intensity", ylab="Number of horizontal gene transfer", cex.lab=2, cex.axis=2)
par(oldpar)
dev.off()
cor(x$V2,x$V4)
cor.test(x$V2,x$V4)
