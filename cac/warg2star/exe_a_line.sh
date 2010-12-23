lockfile=filelock
if ( set -o noclobber; echo "$$" > "$lockfile") 2> /dev/null; 
then
  # BK: this will cause the lock file to be deleted in case of other exit
  trap 'rm -f "$lockfile"; exit $?' INT TERM EXIT

  # critical-section BK: (the protected bit)
  WHICHLINE=$1
  COMMANDFILE=$2
  LINE=$(sed -n "${WHICHLINE}p" "${COMMANDFILE}")
  $LINE

  rm -f "$lockfile"
  trap - INT TERM EXIT
else
  echo "Failed to acquire lockfile: $lockfile." 
  echo "Held by $(cat $lockfile)"
fi
