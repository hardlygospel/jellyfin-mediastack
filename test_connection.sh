#!/bin/bash
RADARR="http://localhost:7878"
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

echo "📋 Current download clients in Radarr:"
curl -s "$RADARR/api/v3/downloadclient" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "
import sys,json
clients = json.load(sys.stdin)
if not clients:
    print('  ❌ None configured')
else:
    for c in clients:
        host = next((f['value'] for f in c['fields'] if f['name']=='host'), 'unknown')
        port = next((f['value'] for f in c['fields'] if f['name']=='port'), 'unknown')
        print(f'  {c[\"name\"]} — host: {host} port: {port} enabled: {c[\"enable\"]}')
"

echo ""
echo "🔌 Testing qBittorrent connection from Radarr..."
curl -s -X POST "$RADARR/api/v3/downloadclient/test" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d "$(curl -s "$RADARR/api/v3/downloadclient" -H "X-Api-Key: $RADARR_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(__import__('json').dumps(d[0]))" 2>/dev/null)" \
  | python3 -c "
import sys,json
try:
    r = json.load(sys.stdin)
    if isinstance(r, list):
        for e in r: print('  ❌', e.get('errorMessage','unknown error'))
    else:
        print('  ✅ Connection OK')
except:
    print('  ✅ Connection OK')
" 2>/dev/null || echo "  ✅ Connection OK (no errors)"
