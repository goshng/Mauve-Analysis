function trim() { echo $1; }

# This will be deleted.
if [[ "$OSTYPE" =~ "linux" ]]; then
  SEQ=seq
elif [[ "$OSTYPE" =~ "darwin" ]]; then
  SEQ=jot
fi

