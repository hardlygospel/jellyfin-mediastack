#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │  🔧  JELLYFIN MEDIASTACK — FIX DOWNLOAD CLIENT        │
# │                                                         │
# │  Adds qBittorrent as download client in Radarr         │
# │  and Sonarr.                                           │
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
echo "⚙️  Adding qBittorrent to Radarr..."
curl -s -X POST "$RADARR/api/v3/downloadclient" \
  -H "X-Api-Key: $RADARR_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"localhost\"},{\"name\":\"port\",\"value\":8080},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_PASS\"},{\"name\":\"movieCategory\",\"value\":\"radarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "⚙️  Adding qBittorrent to Sonarr..."
curl -s -X POST "$SONARR/api/v3/downloadclient" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"localhost\"},{\"name\":\"port\",\"value\":8080},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_PASS\"},{\"name\":\"tvCategory\",\"value\":\"sonarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ qBittorrent added to Radarr and Sonarr."
echo "   qBittorrent password: $QB_PASS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
