 takeOnlyArgumentsAfterDashArgs=TRUE
 args=commandArgs(takeOnlyArgumentsAfterDashArgs)
 if (length(args)<1) {
   print("R --no-save --args arg1 arg2... < script > out.dat");
   stop();
 } 
 
 whichParameter = as.integer(args[1])
 cat("which parameter", whichParameter, "\n");
 date()
 a <- 1
 for (v in seq(10000000)) {
   a <- a + v;
   a <- a - v;
 }
 date()

