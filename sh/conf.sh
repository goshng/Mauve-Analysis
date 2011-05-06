function conf {
  CONFFILE=conf/README
  PROJECTNAME=$(grep PROJECTNAME $CONFFILE | cut -d":" -f2)
  CAC_USERNAME=$(grep CAC_USERNAME $CONFFILE | cut -d":" -f2)
  CAC_LOGIN=$(grep CAC_LOGIN $CONFFILE | cut -d":" -f2)
  CAC_ROOT=$(grep CAC_ROOT $CONFFILE | cut -d":" -f2)
  X11_USERNAME=$(grep X11_USERNAME $CONFFILE | cut -d":" -f2)
  X11_LOGIN=$(grep X11_LOGIN $CONFFILE | cut -d":" -f2)
  X11_ROOT=$(grep X11_ROOT $CONFFILE | cut -d":" -f2)
  BATCHEMAIL=$(grep BATCHEMAIL $CONFFILE | cut -d":" -f2)
  BATCHACCESS=$(grep BATCHACCESS $CONFFILE | cut -d":" -f2)
  QUEUENAME=$(grep QUEUENAME $CONFFILE | cut -d":" -f2)
}
