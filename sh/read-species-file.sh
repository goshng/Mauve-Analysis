
###############################################################################
# Function: reading species file
###############################################################################

# Do something using species file.
# --------------------------------
# Species file contains list of Genbank genome files. I use the list of a
# species file to do a few things: 1. batch file for alignment is genreated
# using the list of a species file. Two bash functions can do this:
# read-species-genbank-files and copy-batch-sh-run-mauve-called.
# Similarly, mkdir-tmp-called can replace copy-batch-sh-run-mauve-called to copy
# the Genbank genome files to somewhere using a species file.
function mkdir-tmp-called {
  line="$@" # get all args
  cp $GENOMEDATADIR/$line $TMPINPUTDIR
}

function copy-batch-sh-run-mauve-called {
  line=$1 # get all args
  isLast=$2
  filename_gbk=`basename $line`
  if [ "$isLast" == "last" ]; then
    echo "  \$INPUTDIR/$filename_gbk" >> $BATCH_SH_RUN_MAUVE 
  else
    echo "  \$INPUTDIR/$filename_gbk \\" >> $BATCH_SH_RUN_MAUVE 
  fi
}

function copy-genomes-to-cac-called {
  line="$@" # get all args
  scp -q $GENOMEDATADIR/$line $CAC_USERHOST:$CAC_DATADIR
}

function processLine {
  line="$@" # get all args
  #  just echo them, but you may need to customize it according to your need
  # for example, F1 will store first field of $line, see readline2 script
  # for more examples
  # F1=$(echo $line | awk '{ print $1 }')
  echo $line
  #cp $GENOMEDATADIR/$line $CACDATADIR
}
 
########################################################################
# I found a script at
# http://bash.cyberciti.biz/file-management/read-a-file-line-by-line/ 
# to read a file line by line. I use it to read a species file.
# I could directly read the directory to find genbank files.
# Let me try to use the script of reading line by line for the time being.
########################################################################
function read-species-genbank-files {
  wfunction_called=$2
  ### Main script stars here ###
  # Store file name
  FILE=""
  numberLine=`grep ^\[^#\] $1 | wc | awk '{print $1'}`
   
  # Make sure we get file name as command line argument
  # Else read it from standard input device
  if [ "$1" == "" ]; then
     FILE="/dev/stdin"
  else
     FILE="$1"
     # make sure file exist and readable
     if [ ! -f $FILE ]; then
      echo "$FILE : does not exists"
      exit 1
     elif [ ! -r $FILE ]; then
      echo "$FILE: can not read"
      exit 2
     fi
  fi
  # read $FILE using the file descriptors
   
  # Set loop separator to end of line
  BAKIFS=$IFS
  IFS=$(echo -en "\n\b")
  exec 3<&0
  exec 0<$FILE
  countLine=0
  isLast=""
  while read line
  do
    if [[ "$line" =~ ^# ]]; then 
      continue
    fi
    countLine=$((countLine + 1))
    if [ $countLine == $numberLine ]; then
      isLast="last"
    else
      isLast=""
    fi
    # use $line variable to process line in processLine() function
    if [ $wfunction_called == "copy-genomes-to-cac" ]; then
      copy-genomes-to-cac-called $line
    elif [ $wfunction_called == "copy-batch-sh-run-mauve" ]; then
      copy-batch-sh-run-mauve-called $line $isLast
    elif [ $wfunction_called == "mkdir-tmp" ]; then
      mkdir-tmp-called $line
    fi
  done
  exec 0<&3
   
  # restore $IFS which was used to determine what the field separators are
  BAKIFS=$ORIGIFS
}


