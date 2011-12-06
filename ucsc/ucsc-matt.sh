KENT=/usr/local/software/kent
# DBNAMECHOICES=(recSde1 recSde2 recSdd recSpy1 recSpy2)
DBNAMECHOICES=(SdeqATCC12394 SdeqGGS124 SddyATCC27957 SpyMGAS315 SpyMGAS10750)
SPECIESNAMES=(sde1 sde2 sdd spy1 spy2)

for i in $(eval echo {1..5}); do
  idb=$((i-1))
  DBNAME=${DBNAMECHOICES[$idb]}
  SPECIESNAME=${SPECIESNAMES[$idb]}
  hgsql $DBNAME -e "drop table fam"
  hgLoadBed -bedDetail -renameSqlTable -trimSqlTable -tab -nobin -sqlTable=$KENT/src/hg/lib/bedDetail.sql $DBNAME fam $SPECIESNAME.bed
done
