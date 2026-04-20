#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │  🔧  JELLYFIN MEDIASTACK — FIX DOWNLOAD CLIENT        │
# │                                                         │
# │  Checks and re-adds qBittorrent as download client     │
# │  in both Radarr and Sonarr.                            │
# └─────────────────────────────────────────────────────────┘

RADARR="http://localhost:7878"
SONARR="http://localhost:8989"
QB_PASS="mediastack123"

echo "🔑 Grabbing API keys..."
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/sonarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
  echo "❌ Could not read API keys. Are the containers running?"
  exit 1
fi

echo ""
echo "🗑️  Clearing existing download clients..."
for id in $(curl -s "$RADARR/api/v3/downloadclient" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$RADARR/api/v3/downloadclient/$id" -H "X-Api-Key: $RADARR_KEY" > /dev/null
  echo "  🗑️  Removed Radarr client ID $id"
done

for id in $(curl -s "$SONARR/api/v3/downloadclient" -H "X-Api-Key: $SONARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$SONARR/api/v3/downloadclient/$id" -H "X-Api-Key: $SONARR_KEY" > /dev/null
  echo "  🗑️  Removed Sonarr client ID $id"
done

echo ""
echo "⚙️  Adding qBittorrent to Radarr..."
curl -s -X POST "$RADARR/api/v3/downloadclient" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"localhost\"},{\"name\":\"port\",\"value\":8080},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_PASS\"},{\"name\":\"movieCategory\",\"value\":\"radarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "⚙️  Adding qBittorrent to Sonarr..."
curl -s -X POST "$SONARR/api/v3/downloadclient" \
  -H "X-Api-Key: $SONARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"localhost\"},{\"name\":\"port\",\"value\":8080},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_PASS\"},{\"name\":\"tvCategory\",\"value\":\"sonarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ qBittorrent connected to Radarr and Sonarr."
echo "   Password: $QB_PASS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
