
function progressbar-initialize {
  PROCESSEDTIME=0
  TOTALITEM=$1
  ITEM=0
}

function progressbar-move {
  STARTTIME=$(date +%s)
}

function progressbar-show {
  ENDTIME=$(date +%s)
  ITEM=$(( $ITEM + 1 ))
  ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
  PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
  REMAINEDITEM=$(( $TOTALITEM - $ITEM ));
  REMAINEDTIME=$(( $PROCESSEDTIME/$ITEM * $REMAINEDITEM / 60));
}
