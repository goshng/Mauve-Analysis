# Author: Sang Chul Choi
# Date  : Mon Apr 25 17:41:53 EDT 2011

# A number of files of clonal origin are renamed: e.g.,
# mv core_co.phase2.104.xml core_co.phase2.xml.104
for i in `ls`; do
  BASENAME=$(eval echo $i | cut -d'.' -f 1,2)
  REPLICATEID=$(eval echo $i | cut -d'.' -f 3)
  TARGETNAME=$BASENAME.xml.$REPLICATEID
  mv $i $TARGETNAME
done
