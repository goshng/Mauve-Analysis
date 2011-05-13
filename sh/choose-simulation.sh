
# 0. For simulation I make directories in CAC and copy genomes files to the data
# directory. 
function choose-simulation {
  PS3="Choose the simulation for clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else
      echo -e "  Creating simulation directories output..."
      mkdir-simulation $SPECIES
      echo -e "done"

      SPECIESFILE=species/$SPECIES
      echo "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)
      
      echo -e "  Creating directories of $HOW_MANY_REPETITION repetitions..."
      for REPETITION in `$SEQ $HOW_MANY_REPETITION`; do
        mkdir-simulation-repeat $SPECIES $REPETITION
      done

      echo -e "Execute simulate-data!"
      break
    fi
  done
}

# Creates a species directory in the output directory.
# ----------------------------------------------------
# The argument is the name of species or analysis. You can find them in the
# subdirectory called species.
function mkdir-simulation {
  echo -n "  Creating a simulation $1 at $OUTPUTDIR ..."
  echo -e " done"
  mkdir $OUTPUTDIR/$1
  mkdir $OUTPUTDIR/$1/run-analysis
  echo -n "  Creating a simulation $1 at $CAC_OUTPUTDIR in $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir $CAC_OUTPUTDIR/$1
  echo -e " done"
  echo -n "  Creating a simulation $1 at $X11_OUTPUTDIR in $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir $X11_OUTPUTDIR/$1
  echo -e " done"
}

# Creates directories in each repeat directory.
# ---------------------------------------------
# The first argument is the species name, and the second is the repeat number.
# Both of them are required.
function mkdir-simulation-repeat {
  BASEDIR=$OUTPUTDIR/$1/$2
  DATADIR=$BASEDIR/data
  RUNMAUVE=$BASEDIR/run-mauve
  RUNCLONALFRAME=$BASEDIR/run-clonalframe
  RUNCLONALORIGIN=$BASEDIR/run-clonalorigin
  RUNANALYSIS=$BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $BASEDIR ..."
  mkdir $BASEDIR \
        $DATADIR \
        $RUNMAUVE \
        $RUNCLONALFRAME \
        $RUNCLONALORIGIN \
        $RUNANALYSIS
  echo -e " done"
  CAC_BASEDIR=$CAC_OUTPUTDIR/$1/$2
  CAC_DATADIR=$CAC_BASEDIR/data
  CAC_RUNMAUVE=$CAC_BASEDIR/run-mauve
  CAC_RUNCLONALFRAME=$CAC_BASEDIR/run-clonalframe
  CAC_RUNCLONALORIGIN=$CAC_BASEDIR/run-clonalorigin
  CAC_RUNANALYSIS=$CAC_BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $CAC_BASEDIR ... of $CAC_USERHOST ..."
  ssh -x $CAC_USERHOST mkdir $CAC_BASEDIR \
                             $CAC_DATADIR \
                             $CAC_RUNMAUVE \
                             $CAC_RUNCLONALFRAME \
                             $CAC_RUNCLONALORIGIN \
                             $CAC_RUNANALYSIS
  echo -e " done"
  X11_BASEDIR=$X11_OUTPUTDIR/$1/$2
  X11_DATADIR=$X11_BASEDIR/data
  X11_RUNMAUVE=$X11_BASEDIR/run-mauve
  X11_RUNCLONALFRAME=$X11_BASEDIR/run-clonalframe
  X11_RUNCLONALORIGIN=$X11_BASEDIR/run-clonalorigin
  X11_RUNANALYSIS=$X11_BASEDIR/run-analysis
  echo -e "  Creating data, run-mauve, run-cloneframe, run-clonalorigin,"
  echo -n "    run-analysis at $X11_BASEDIR ... of $X11_USERHOST ..."
  ssh -x $X11_USERHOST mkdir $X11_BASEDIR \
                             $X11_DATADIR \
                             $X11_RUNMAUVE \
                             $X11_RUNCLONALFRAME \
                             $X11_RUNCLONALORIGIN \
                             $X11_RUNANALYSIS
  echo -e " done"
}

