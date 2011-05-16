# Format seconds into a time format
# ---------------------------------
# Converts seconds to a format of hours:minutes:seconds.
#
# input: number in seconds
# output: hours:minutes:seconds
function hms
{
  s=$1
  h=$((s/3600))
  s=$((s-(h*3600)));
  m=$((s/60));
  s=$((s-(m*60)));
  printf "%02d:%02d:%02d\n" $h $m $s
}
