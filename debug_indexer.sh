#!/bin/bash
PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

for defname in "1337x" "eztv" "kickasstorrents-to"; do
  echo "=== $defname ==="
  SCHEMA=$(curl -s "http://localhost:9696/api/v1/indexer/schema" -H "X-Api-Key: $PROWLARR_KEY" \
    | python3 -c "
import sys,json
data=json.load(sys.stdin)
m=next((x for x in data if x.get('definitionName','').lower()=='$defname'.lower()), None)
if m:
    m['name']='$defname'
    m['enableRss']=True
    m['enableAutomaticSearch']=True
    m['appProfileId']=1
    m['priority']=25
    print(json.dumps(m))
" 2>/dev/null)
  curl -s -X POST "http://localhost:9696/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_KEY" \
    -H "Content-Type: application/json" \
    -d "$SCHEMA" | python3 -m json.tool
  echo ""
done
