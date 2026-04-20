#!/bin/bash
PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

echo "=== Current indexers in Prowlarr ==="
curl -s "http://localhost:9696/api/v1/indexer" -H "X-Api-Key: $PROWLARR_KEY" | python3 -c "import sys,json; [print(x['id'], x['name']) for x in json.load(sys.stdin)]"

echo ""
echo "=== Attempting to add YTS and showing full response ==="
SCHEMA=$(curl -s "http://localhost:9696/api/v1/indexer/schema" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "
import sys,json
data=json.load(sys.stdin)
m=next(x for x in data if x.get('definitionName','').lower()=='yts')
m['name']='YTS'
m['enableRss']=True
m['enableAutomaticSearch']=True
m['appProfileId']=1
m['priority']=25
print(json.dumps(m))")

curl -s -X POST "http://localhost:9696/api/v1/indexer" \
  -H "X-Api-Key: $PROWLARR_KEY" \
  -H "Content-Type: application/json" \
  -d "$SCHEMA" | python3 -m json.tool
