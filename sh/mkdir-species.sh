# Create direcotires for storing analyses and their results.
# ----------------------------------------------------------
# The species directory is created in output subdirectory. The cluster's file
# system is almost the same as the local one. 
# The followings are the directories to create:
# 
# /Users/goshng/Documents/Projects/mauve/output/cornell
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/data
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-mauve
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-clonalframe
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-clonalorigin
# /Users/goshng/Documents/Projects/mauve/output/cornell/1/run-analysis
# 
# if 
# BASEDIR=/Users/goshng/Documents/Projects/mauve/output/cornell
# 
# I use 
function mkdir-species {
  mkdir $BASEDIR/run-analysis
  mkdir $BASEDIR \
        $NUMBERDIR \
        $DATADIR \
        $RUNMAUVE \
        $RUNCLONALFRAME \
        $RUNCLONALORIGIN \
        $RUNANALYSIS

  ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR \
                             $CAC_NUMBERDIR \
                             $CAC_DATADIR \
                             $CAC_RUNMAUVE \
                             $CAC_RUNCLONALFRAME \
                             $CAC_RUNCLONALORIGIN \
                             $CAC_RUNANALYSIS

  ssh -x $X11_USERHOST mkdir $X11_BASEDIR \
                             $X11_NUMBERDIR \
                             $X11_DATADIR \
                             $X11_RUNMAUVE \
                             $X11_RUNCLONALFRAME \
                             $X11_RUNCLONALORIGIN \
                             $X11_RUNANALYSIS
}


