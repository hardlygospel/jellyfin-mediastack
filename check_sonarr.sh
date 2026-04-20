#!/bin/bash
SONARR="http://localhost:8989"
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/sonarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

echo "📋 Sonarr indexers:"
curl -s "$SONARR/api/v3/indexer" -H "X-Api-Key: $SONARR_KEY" \
  | python3 -c "
import sys,json
d=json.load(sys.stdin)
print(f'  {len(d)} indexer(s)') if d else print('  ❌ None')
"

echo ""
echo "⬇️  Sonarr download client:"
curl -s "$SONARR/api/v3/downloadclient" -H "X-Api-Key: $SONARR_KEY" \
  | python3 -c "
import sys,json
clients=json.load(sys.stdin)
if not clients: print('  ❌ None configured')
else:
  for c in clients:
    host=next((f['value'] for f in c['fields'] if f['name']=='host'),'?')
    port=next((f['value'] for f in c['fields'] if f['name']=='port'),'?')
    print(f'  {c[\"name\"]} — host: {host} port: {port} enabled: {c[\"enable\"]}')
"

echo ""
echo "📁 Sonarr root folders:"
curl -s "$SONARR/api/v3/rootfolder" -H "X-Api-Key: $SONARR_KEY" \
  | python3 -c "
import sys,json
folders=json.load(sys.stdin)
if not folders: print('  ❌ None')
else: [print(f'  {f[\"path\"]}') for f in folders]
"

echo ""
echo "📺 Series in Sonarr:"
curl -s "$SONARR/api/v3/series" -H "X-Api-Key: $SONARR_KEY" \
  | python3 -c "
import sys,json
series=json.load(sys.stdin)
if not series: print('  None added yet')
else: [print(f'  [{s[\"id\"]}] {s[\"title\"]} — monitored: {s[\"monitored\"]}') for s in series[:5]]
"
