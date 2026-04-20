#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │   🔧  JELLYFIN MEDIASTACK — FIX INDEXERS              │
# │                                                         │
# │  Adds indexers to Prowlarr then syncs to               │
# │  Radarr and Sonarr.                                    │
# └─────────────────────────────────────────────────────────┘

PROWLARR="http://localhost:9696"
RADARR="http://localhost:7878"
SONARR="http://localhost:8989"

echo "🔑 Grabbing API keys..."
PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/sonarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$PROWLARR_KEY" ] || [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
  echo "❌ Could not read API keys. Are the containers running?"
  exit 1
fi

echo ""
echo "📡 Adding indexers to Prowlarr..."

add_indexer() {
  local name="$1"
  local defname="$2"
  curl -s -X POST "$PROWLARR/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"enableRss\":true,\"enableAutomaticSearch\":true,\"enableInteractiveSearch\":true,\"supportsRss\":true,\"supportsSearch\":true,\"protocol\":\"torrent\",\"definitionName\":\"$defname\",\"fields\":[],\"tags\":[]}" > /dev/null
  echo "  ✅ $name"
}

add_indexer "YTS"              "YTS"
add_indexer "1337x"            "1337x"
add_indexer "EZTV"             "EZTV"
add_indexer "Nyaa"             "Nyaa"
add_indexer "The Pirate Bay"   "ThePirateBay"
add_indexer "Kickass Torrents" "KickassTorrents"

echo ""
echo "🔗 Syncing Prowlarr → Radarr and Sonarr..."
curl -s -X POST "$PROWLARR/api/v1/applications/sync" \
  -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Indexers added and synced."
echo "   Check Radarr → Settings → Indexers to confirm."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
