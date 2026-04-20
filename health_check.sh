#!/bin/bash
PROWLARR="http://localhost:9696"
RADARR="http://localhost:7878"
SONARR="http://localhost:8989"
QB="http://localhost:8080"
JELLYFIN="http://localhost:8096"
JELLYSEERR="http://localhost:5055"

PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/sonarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🏥 MEDIASTACK HEALTH CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

echo ""
echo "🐳 Container status:"
for name in radarr sonarr prowlarr qbittorrent jellyfin jellyseerr; do
  status=$(docker inspect --format='{{.State.Status}}' $name 2>/dev/null)
  [ "$status" = "running" ] && echo "  ✅ $name" || echo "  ❌ $name ($status)"
done

echo ""
echo "🌐 HTTP reachability:"
for entry in "Radarr:$RADARR" "Sonarr:$SONARR" "Prowlarr:$PROWLARR" "qBittorrent:$QB" "Jellyfin:$JELLYFIN" "Jellyseerr:$JELLYSEERR"; do
  name="${entry%%:*}"
  url="${entry#*:}"
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url")
  case "$code" in 200|301|302|307) echo "  ✅ $name ($code)" ;; *) echo "  ❌ $name ($code)" ;; esac
done

echo ""
echo "📡 Radarr indexers: $(curl -s "$RADARR/api/v3/indexer" -H "X-Api-Key: $RADARR_KEY" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)"
echo "📡 Sonarr indexers: $(curl -s "$SONARR/api/v3/indexer" -H "X-Api-Key: $SONARR_KEY" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))" 2>/dev/null)"

echo ""
echo "⬇️  Radarr download client: $(curl -s "$RADARR/api/v3/downloadclient" -H "X-Api-Key: $RADARR_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['name']+' → '+next(f['value'] for f in d[0]['fields'] if f['name']=='host')) if d else print('❌ None')" 2>/dev/null)"
echo "⬇️  Sonarr download client: $(curl -s "$SONARR/api/v3/downloadclient" -H "X-Api-Key: $SONARR_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['name']+' → '+next(f['value'] for f in d[0]['fields'] if f['name']=='host')) if d else print('❌ None')" 2>/dev/null)"

echo ""
echo "📁 Radarr root folder: $(curl -s "$RADARR/api/v3/rootfolder" -H "X-Api-Key: $RADARR_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['path']) if d else print('❌ None')" 2>/dev/null)"
echo "📁 Sonarr root folder: $(curl -s "$SONARR/api/v3/rootfolder" -H "X-Api-Key: $SONARR_KEY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d[0]['path']) if d else print('❌ None')" 2>/dev/null)"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
