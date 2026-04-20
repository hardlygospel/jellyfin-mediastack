#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │   🔧  JELLYFIN MEDIASTACK — FIX INDEXERS              │
# │                                                         │
# │  Adds indexers to Prowlarr then syncs to               │
# │  Radarr and Sonarr.                                    │
# └─────────────────────────────────────────────────────────┘

PROWLARR="http://localhost:9696"

echo "🔑 Grabbing API keys..."
PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$PROWLARR_KEY" ]; then
  echo "❌ Could not read Prowlarr API key. Is the container running?"
  exit 1
fi

echo ""
echo "🔍 Fetching app profile ID..."
APP_PROFILE_ID=$(curl -s "$PROWLARR/api/v1/appprofile" -H "X-Api-Key: $PROWLARR_KEY" | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+' | head -1)
APP_PROFILE_ID=${APP_PROFILE_ID:-1}
echo "  Using profile ID: $APP_PROFILE_ID"

echo ""
echo "📡 Adding indexers to Prowlarr..."

add_indexer() {
  local defname="$1"
  local name="$2"

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
    echo "  ⚠️  $name — schema not found"
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

add_indexer "yts"                  "YTS"
add_indexer "1337x"                "1337x"
add_indexer "eztv"                 "EZTV"
add_indexer "nyaasi"               "Nyaa"
add_indexer "thepiratebay"         "The Pirate Bay"
add_indexer "kickasstorrents-to"   "Kickass Torrents"

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
