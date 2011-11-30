x <- read.table("go-list.txt.out2.new")
y <- read.table("rimap-REPLICATE-gene.txt", head=T)
# x$V1 %in% y$gene

# y$gene %in% x$V1

m1 <- merge(x, y, by.x = "V1", by.y = "gene")
wilcox.test(m1$all[m1$V2 > 0], m1$all[!m1$V2 > 0])
wilcox.test(m1$topology[m1$V2 > 0], m1$topology[!m1$V2 > 0])
wilcox.test(m1$notopology[m1$V2 > 0], m1$notopology[!m1$V2 > 0])
wilcox.test(m1$sde2spy[m1$V2 > 0], m1$sde2spy[!m1$V2 > 0])
wilcox.test(m1$spy2sde[m1$V2 > 0], m1$spy2sde[!m1$V2 > 0])
wilcox.test(m1$mattsde2spy[m1$V2 > 0], m1$mattsde2spy[!m1$V2 > 0])
wilcox.test(m1$mattspy2sde[m1$V2 > 0], m1$mattspy2sde[!m1$V2 > 0])
