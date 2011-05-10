
PROCESSEDTIME=0
TOTALITEM=10000
for i in $(eval echo {1..$TOTALITEM}); do
  STARTTIME=$(date +%s)
  sleep 1
  ENDTIME=$(date +%s)

  ELAPSEDTIME=$(( $ENDTIME - $STARTTIME ))
  PROCESSEDTIME=$(( $PROCESSEDTIME + $ELAPSEDTIME ))
  REMAINEDITEM=$(( $TOTALITEM - $i ));
  REMAINEDTIME=$(( $PROCESSEDTIME/$i * $REMAINEDITEM / 60));
  echo -ne "More $REMAINEDTIME min. to go\r"
  #echo "elapsed time: $ELAPSEDTIME"
  #echo "elapsed time: $PROCESSEDTIME"
  #echo "remained item: $REMAINEDITEM"
  #echo "$remainedTime min."
done
