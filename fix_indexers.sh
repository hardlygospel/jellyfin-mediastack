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
echo "🔍 Fetching app profile ID..."
APP_PROFILE_ID=$(curl -s "$PROWLARR/api/v1/appprofile" -H "X-Api-Key: $PROWLARR_KEY" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+' | head -1)
if [ -z "$APP_PROFILE_ID" ]; then
  APP_PROFILE_ID=1
fi
echo "  Using profile ID: $APP_PROFILE_ID"

echo ""
echo "📡 Adding indexers to Prowlarr..."

add_indexer() {
  local defname="$1"
  local name="$2"

  # Fetch the schema for this indexer
  local schema
  schema=$(curl -s "$PROWLARR/api/v1/indexer/schema" -H "X-Api-Key: $PROWLARR_KEY" \
    | python3 -c "
import sys, json
data = json.load(sys.stdin)
match = next((x for x in data if x.get('definitionName','').lower() == '$defname'.lower()), None)
if match:
    match['name'] = '$name'
    match['enableRss'] = True
    match['enableAutomaticSearch'] = True
    match['enableInteractiveSearch'] = True
    match['appProfileId'] = $APP_PROFILE_ID
    match['priority'] = 25
    print(json.dumps(match))
" 2>/dev/null)

  if [ -z "$schema" ]; then
    echo "  ⚠️  $name — schema not found, skipping"
    return
  fi

  local result
  result=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PROWLARR/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_KEY" \
    -H "Content-Type: application/json" \
    -d "$schema")

  if [ "$result" = "201" ] || [ "$result" = "200" ]; then
    echo "  ✅ $name"
  else
    echo "  ⚠️  $name — HTTP $result"
  fi
}

add_indexer "YTS"            "YTS"
add_indexer "1337x"          "1337x"
add_indexer "EZTV"           "EZTV"
add_indexer "Nyaa"           "Nyaa"
add_indexer "ThePirateBay"   "The Pirate Bay"
add_indexer "KickassTorrents" "Kickass Torrents"

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
