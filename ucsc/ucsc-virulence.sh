KENT=/usr/local/software/kent
DBNAMECHOICES=(SdeqATCC12394 SdeqGGS124 SddyATCC27957 SpyMGAS315 SpyMGAS10750)
for i in {0..4}; do
  DBNAME=${DBNAMECHOICES[$i]}
  hgLoadBed $DBNAME virulence $DBNAME.virulencegenes.bed
done

