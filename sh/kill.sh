
ssh -x $1 ps ax | grep warg | awk '{print $1}'| ssh -x $1 xargs -i kill {} 2&>/dev/null
