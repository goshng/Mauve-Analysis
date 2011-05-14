# Author : Sang Chul Choi
# Date   : Sat May 14 07:21:30 EDT 2011

# Find the median of the median values of three parameters.
# ---------------------------------------------------------
# The simulation s1 would create an output file.  
# It contains a matrix of column size being equal to the sample size (Note that
# the sample size is 101 when run length is 1000000, and thinning interval is
# 10000), and row being equal to the number of repetition.
#
# 
function simulate-data-clonalorigin1-analyze-s1-rscript {
  S1OUT=$1
  BATCH_R_S1=$2
cat>$BATCH_R_S1<<EOF
summaryThreeParameter <- function (f) {
  x <- scan (f, quiet=TRUE)
  x <- matrix (x, ncol=101, byrow=TRUE)
  # x <- matrix (x, ncol=100, byrow=FALSE) # 100 is the number of repetition

  y <- c() 
  for (i in 1:100) {
    y <- c(y, median(x[i,]))
  }

  cat (median(y))
  cat ("\n")
}
summaryThreeParameter ("$S1OUT.theta")
summaryThreeParameter ("$S1OUT.rho")
summaryThreeParameter ("$S1OUT.delta")
EOF
  Rscript $BATCH_R_S1 > $BATCH_R_S1.out 
}

# Find the median of the median values of three parameters.
# ---------------------------------------------------------
# The simulation s2 would create an output file. 
# It contains a matrix of column size being equal to 
# a number equal to the product of sample size (N) 
# and block size (B),
# and row being equal to the number of repetition (G).
# I take the mean of a parameter of the sample of a block. 
# The B-many mean values are used to find their median.
# I summarize G-many median values.
# N * B = 101 * 411 = 41511;
#
function simulate-data-clonalorigin1-analyze-s2-rscript {
  S2OUT=$1
  BATCH_R_S2=$2
  NUMBER_REPETITION=$3
  NUMBER_BLOCK=$4
  NUMBER_SAMPLE=$5
  NUMBER_NUMBER=$(( NUMBER_BLOCK * NUMBER_SAMPLE ))
cat>$BATCH_R_S2<<EOF
summaryThreeParameter <- function (f) {
  x <- scan (f, quiet=TRUE)
  x <- matrix (x, ncol=$NUMBER_NUMBER, byrow=TRUE)
  # x <- matrix (x, ncol=100, byrow=FALSE) # 100 is the number of repetition

  y <- c() 
  for (i in 1:$NUMBER_REPETITION) {
    x1 <- matrix (x[i,], ncol=$NUMBER_SAMPLE, byrow=TRUE)
    y1 <- c()
    for (j in 1:$NUMBER_BLOCK) {
      y1 <- c(y1, median(x1[j,]))
    }

    y <- c(y, median(y1))
  }

  cat (median(y))
  cat ("\n")
}
summaryThreeParameter ("$S2OUT.theta")
summaryThreeParameter ("$S2OUT.rho")
summaryThreeParameter ("$S2OUT.delta")
EOF
  Rscript $BATCH_R_S2 > $BATCH_R_S2.out 
}


# Analysis with clonal origin simulation
# --------------------------------------
# The recovery of the true values is evaluated. The 3 main scalar parameters of
# Clonal origin model include mutation rate, recombination rate, and average
# tract length. Each run samples $N$ values of each parameter. I repeated the
# simulation $G$ times. How can I assess the coverage of estimates on the true
# value?
# For each repetition I find a point estimate such as mean or median of each
# parameter. I will check how much the 100 point estimates cover the true value.
# I could find an interval estimate for each repetition. I could check how often
# or how many among 100 interval estimates cover the true value. If we use 95%
# interval, then I'd expect that 95 of 100 interval estimates would cover the
# true value. I need to build a matrix of 100-by-100 for each parameter. I could
# use it to compute interval estimates.
#
# s1: a single block
# s2: multiple blocks or 411 blocks
# s3: 10 blocks
# 
function simulate-data-clonalorigin1-analyze {
  PS3="Choose the simulation result of clonalorigin: "
  select SPECIES in ${SIMULATIONS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    elif [ "$SPECIES" == "s1" ]; then
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE

      SPECIESFILE=species/$SPECIES
      echo "  Reading REPETITION from $SPECIESFILE..."
      HOW_MANY_REPETITION=$(grep Repetition $SPECIESFILE | cut -d":" -f2)

      echo "Extracting the 3 parameters from ${HOW_MANY_REPETITION} XML files"
      echo "  of replicate ${REPLICATE}..."
      BASEDIR=$OUTPUTDIR/$SPECIES
      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        NUMBERDIR=$BASEDIR/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        RUNANALYSIS=$NUMBERDIR/run-analysis
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        # Files that we need to compare.
        if [ "$g" == 1 ]; then
          perl pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.1.xml \
            -out $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out
        else
          perl pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.1.xml \
            -out $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
            -append
        fi
      done

      echo "Summarizing the three parameters..."
      simulate-data-clonalorigin1-analyze-s1-rscript \
        $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      echo "Refer to the file for median values of the three parameters."
      
      break
    elif [ "$SPECIES" == "s2" ] \
         || [ "$SPECIES" == "s3" ] \
         || [ "$SPECIES" == "s4" ] \
         || [ "$SPECIES" == "s5" ] \
         || [ "$SPECIES" == "s6" ] \
         || [ "$SPECIES" == "s7" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE

      BASEDIR=$OUTPUTDIR/$SPECIES
      RUNCLONALORIGIN=$BASEDIR/1/run-clonalorigin
      NUMBER_SAMPLE2=$(echo `grep number $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.1|wc -l`)
      NUMBER_SAMPLE=$(( $CHAINLENGTH / $THIN + 1))
      echo $NUMBER_SAMPLE

      echo "Extracting the 3 parameters from ${HOW_MANY_REPETITION} XML files"
      echo "  of replicate ${REPLICATE}..."

      #echo "Summarizing the three parameters..."
      #simulate-data-clonalorigin1-analyze-s2-rscript \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R 
      #echo "  $BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R.out is created!"
      #echo "Refer to the file for median values of the three parameters."
      #break

      #BLOCK_ALLREPETITION=()
      #for b in `$SEQ $NUMBER_BLOCK`; do
        #NOTALLREPETITION=0
        #for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
          #NUMBERDIR=$BASEDIR/$g
          #DATADIR=$NUMBERDIR/data
          #RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          #RUNANALYSIS=$NUMBERDIR/run-analysis
          #CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          #CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin
          #FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml)
          #if [[ "$FINISHED" =~ "outputFile" ]]; then
            ## NOTALLREPETITION=1
            #NOTALLREPETITION=1 # This should be something else.
          #else 
            #NOTALLREPETITION=1
          #fi
        #done
        #if [ "$NOTALLREPETITION" == 0 ]; then
          ## Add the block to the analysis
          #BLOCK_ALLREPETITION=("${BLOCK_ALLREPETITION[@]}" $b)
        #fi 
      #done

      for g in `$SEQ ${HOW_MANY_REPETITION}`; do 
        NUMBERDIR=$BASEDIR/$g
        DATADIR=$NUMBERDIR/data
        RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
        RUNANALYSIS=$NUMBERDIR/run-analysis
        CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
        CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

        # Files that we need to compare.
        #for b in ${BLOCK_ALLREPETITION[@]}; do
        for b in `$SEQ $NUMBER_BLOCK`; do
          ECOP="pl/extractClonalOriginParameter5.pl \
            -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml \
            -out $BASEDIR/run-analysis/out"
          FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.$b.xml)
          if [[ "$FINISHED" =~ "outputFile" ]]; then
            if [ "$g" == 1 ] && [ "$b" == 1 ]; then
              ECOP="$ECOP -nonewline"
              #echo perl $ECOP
              #continue
            else
              if [ "$b" == $NUMBER_BLOCK ]; then
                ECOP="$ECOP -firsttab -append"
              elif [ "$b" != 1 ]; then
                ECOP="$ECOP -firsttab -nonewline -append" 
              elif [ "$b" == 1 ]; then
                ECOP="$ECOP -nonewline -append" 
              else
                echo "Not possible block $b"
                exit
              fi
            fi
            perl $ECOP
          else
            LENGTHBLOCK=$(perl pl/compute-block-length.pl \
              -base $DATADIR/${SPECIES}_${g}_core_alignment.xmfa \
              -block $b)
            echo "NOTYETFINISHED $g $b $LENGTHBLOCK" >> 1
          fi
        done
      done

      #break
      echo "Summarizing the three parameters..."
      simulate-data-clonalorigin1-analyze-s2-rscript \
        $BASEDIR/run-analysis/out \
        $BASEDIR/run-analysis/out.R \
        $HOW_MANY_REPETITION \
        $NUMBER_BLOCK \
        $NUMBER_SAMPLE 
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out \
        #$BASEDIR/run-analysis/$SPECIES.$REPLICATE.out.R \
      echo "  $BASEDIR/run-analysis/out.R.out is created!"
      echo "Refer to the file for median values of the three parameters."
      cat $BASEDIR/run-analysis/out.R.out
      break
    elif [ "$SPECIES" == "s15" ] \
         || [ "$SPECIES" == "sxx" ]; then
      read-species
      echo -n "Which replicate set of ClonalOrigin output files? (e.g., 1) "
      read REPLICATE

      BASEDIR=$OUTPUTDIR/$SPECIES
      RUNCLONALORIGIN=$BASEDIR/1/run-clonalorigin
      NUMBER_SAMPLE2=$(echo `grep number $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.1|wc -l`)
      NUMBER_SAMPLE=$(( $CHAINLENGTH / $THIN + 1))

      echo -n "Do you wish to extract mu, delta, rho (y/n)? "
      read WISH
      if [ "$WISH" == "y" ]; then
        for g in $(eval echo {1..$HOW_MANY_REPETITION}); do
          NUMBERDIR=$BASEDIR/$g
          DATADIR=$NUMBERDIR/data
          RUNCLONALORIGIN=$NUMBERDIR/run-clonalorigin
          RUNANALYSIS=$NUMBERDIR/run-analysis
          CAC_NUMBERDIR=$CAC_OUTPUTDIR/$SPECIES/$g
          CAC_RUNCLONALORIGIN=$CAC_NUMBERDIR/run-clonalorigin

          # Files that we need to compare.
          for b in $(eval echo {1..$NUMBER_BLOCK}); do
            ECOP="pl/extractClonalOriginParameter5.pl \
              -xml $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.$b \
              -withblocksize \
              -out $BASEDIR/run-analysis/out"
            FINISHED=$(tail -n 1 $RUNCLONALORIGIN/output/$REPLICATE/core_co.phase2.xml.$b)
            if [[ "$FINISHED" =~ "outputFile" ]]; then
              if [ "$g" == 1 ] && [ "$b" == 1 ]; then
                ECOP="$ECOP -nonewline"
                #echo perl $ECOP
                #continue
              else
                if [ "$b" == $NUMBER_BLOCK ]; then
                  ECOP="$ECOP -firsttab -append"
                elif [ "$b" != 1 ]; then
                  ECOP="$ECOP -firsttab -nonewline -append" 
                elif [ "$b" == 1 ]; then
                  ECOP="$ECOP -nonewline -append" 
                else
                  echo "Not possible block $b"
                  exit
                fi
              fi
              perl $ECOP
              echo -ne "$g/$HOW_MANY_REPETITION $b/$NUMBER_BLOCK done\r"
            else
              LENGTHBLOCK=$(perl pl/compute-block-length.pl \
                -base $DATADIR/core_alignment.$REPLICATE.xmfa \
                -block $b)
              echo "NOTYETFINISHED $g $b $LENGTHBLOCK" >> 1
            fi
          done
        done
      else
        echo "Skipping extracting mu, delta, rho"
      fi
      echo " done in reading!"

break
      perl pl/simulate-data-clonalorigin1-analyze.pl \
        -in $BASEDIR/run-analysis/out \
        -numbersample $NUMBER_SAMPLE \
        -out $BASEDIR/run-analysis/out.summary
break
      cat $BASEDIR/run-analysis/out.R.out
      break

    else
      echo -e "You need to enter something\n"
      continue
    fi
  done
}


