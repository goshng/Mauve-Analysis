
# 3. Find core alignment blocks.
# ------------------------------
# Core alignment blocks are generated from the mauve alignment. This is somewhat
# iterative procedure. I often was faced with two difficulties. The program,
# stripSubsetLCBs, is a part of progressiveMauve.  Core alignment blocks were
# filtered. Often some allignments were a little bizarre: two many gaps are
# still in some alignment. Another difficulty happens in ClonalOrigin analysis.
# ClonalOrigin's runs with some alignment blocks did not finish within bearable
# time, say a month. ClonalOrigin's run with some other alignment blocks were
# finished relatively fast. It depends on the option of chain lengths. I
# consider that runs are finished when multiple independent MCMC more or less
# converged. Those blocks had to be excluded from the analysis. At the first run
# of this whole procedure, I simply execute the stripSubsetLCBs to find core
# alignment blocks. I manually check the core alignment blocks to remove any
# weird alignments. I then proceed to ClonalFrame and the first stage of
# ClonalOrigin. I find problematic alignment blocks with which ClonalOrigin runs
# take too much computing time. Then, I come back to filter-blocks to remove
# them. I had to be careful in ordering of alignment blocks because when I remove any
# blocks that are not the last all the preceding block numbers have to change.
#
# Note that run-lcb alwasys use the output of Mauve alignment. In the 2nd stage
# of filtering you need to consider proper numbering. Say, in the first
# filtering of alignment with many gaps you removed the 3rd among 10 alignment
# blocks. In the 2nd stage, you found 6th alignment needed too long computing
# time. Then, you should remove 3rd and 7th, not 3rd and 6th because the 6th is
# actually the 7th among the first 10 alignment blocks. The 6th alignment is 6th
# among 9 alignment blocks that were from the 1st stage of filtering.
function filter-blocks {
  PS3="Choose the species for $FUNCNAME: "
  select SPECIES in ${SPECIESS[@]}; do 
    if [ "$SPECIES" == "" ];  then
      echo -e "You need to enter something\n"
      continue
    else  
      echo -n "What repetition do you wish to run? (e.g., 1) "
      read REPETITION
      echo -e 'What is the temporary id of mauve-analysis?'
      echo -e "You may find it in the following directory"
      echo -e "`pwd`/output/$SPECIES/$REPETITION/run-mauve/output/full_alignment.xmfa"
      echo -n "JOB ID: " 
      read JOBID
      echo -e "Preparing clonalframe analysis...\n"
      set-more-global-variable $SPECIES $REPETITION
      # Then, run LCB.
      echo -e "  Finding core blocks of the alignment...\n"
      echo -n "Minimum length of block: " 
      read MINIMUM_LENGTH
      mkdir-tmp 
      run-lcb $MINIMUM_LENGTH
      rmdir-tmp

      #echo -e "  $RUNLCBDIR/core_alignment.xmfa is generated\n"
      #mv $RUNLCBDIR/core_alignment.xmfa.org $RUNLCBDIR/core_alignment.xmfa
      #run-blocksplit2fasta
      #break

      echo -n 'Do you want to filter? (y/n) '
      read WANTFILTER
      if [ "$WANTFILTER" == "y" ]; then
        echo -e "Choose blocks to remove (e.g., 33,42,57): "
        read BLOCKSREMOVED
        perl pl/remove-blocks-from-core-alignment.pl \
          -blocks $BLOCKSREMOVED -fasta $RUNLCBDIR/core_alignment.xmfa.org \
          -outfile $RUNLCBDIR/core_alignment.xmfa
        echo -e "  A new $RUNLCBDIR/core_alignment.xmfa is generated\n"
        echo -e "Now, prepare clonalframe analysis.\n"
      else
        mv $DATADIR/core_alignment.xmfa.org $DATADIR/core_alignment.xmfa
      fi
       
      echo -e "The core blocks might have weird alignment."
      echo -e "Now, edit core blocks of the alignment."
      echo -e "This is the core alignment: $DATADIR/core_alignment.xmfa"
      break
    fi
  done
}

function run-lcb {
  MINIMUM_LENGTH=$1
  DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$HOME/usr/lib \
  $LCB $RUNMAUVEOUTPUTDIR/full_alignment.xmfa \
    $RUNMAUVEOUTPUTDIR/full_alignment.xmfa.bbcols \
    $DATADIR/core_alignment.xmfa.org $MINIMUM_LENGTH
}

function mkdir-tmp {
  mkdir -p $TMPINPUTDIR
  read-species-genbank-files data/$SPECIES mkdir-tmp
}

function rmdir-tmp {
  rm -rf $TMPDIR
}
