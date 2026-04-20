#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │   🔧  JELLYFIN MEDIASTACK — FULL RESET & CONFIGURE    │
# │                                                         │
# │  Wipes and reconfigures everything from scratch.       │
# └─────────────────────────────────────────────────────────┘

PROWLARR="http://localhost:9696"
RADARR="http://localhost:7878"
SONARR="http://localhost:8989"
QB_HOST="qbittorrent"
QB_PORT=8080
QB_PASS="mediastack123"

echo "🔑 Grabbing API keys..."
PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/sonarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$PROWLARR_KEY" ] || [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
  echo "❌ Could not read API keys. Are all containers running?"
  exit 1
fi

echo "  Prowlarr: $PROWLARR_KEY"
echo "  Radarr:   $RADARR_KEY"
echo "  Sonarr:   $SONARR_KEY"

# ── Prowlarr: clear apps ──────────────────────────────────
echo ""
echo "🗑️  Clearing Prowlarr apps..."
for id in $(curl -s "$PROWLARR/api/v1/applications" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$PROWLARR/api/v1/applications/$id" -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
  echo "  🗑️  Removed app ID $id"
done

# ── Prowlarr: clear indexers ─────────────────────────────
echo ""
echo "🗑️  Clearing Prowlarr indexers..."
for id in $(curl -s "$PROWLARR/api/v1/indexer" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$PROWLARR/api/v1/indexer/$id" -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
  echo "  🗑️  Removed indexer ID $id"
done

# ── Prowlarr: add apps ───────────────────────────────────
echo ""
echo "🔗 Connecting Prowlarr → Radarr..."
curl -s -X POST "$PROWLARR/api/v1/applications" \
  -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"Radarr\",\"syncLevel\":\"fullSync\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"$PROWLARR\"},{\"name\":\"baseUrl\",\"value\":\"$RADARR\"},{\"name\":\"apiKey\",\"value\":\"$RADARR_KEY\"},{\"name\":\"syncCategories\",\"value\":[2000,2010,2020,2030,2040,2045,2050,2060]}],\"implementationName\":\"Radarr\",\"implementation\":\"Radarr\",\"configContract\":\"RadarrSettings\",\"infoLink\":\"\"}" > /dev/null
echo "  ✅ Radarr"

echo "🔗 Connecting Prowlarr → Sonarr..."
curl -s -X POST "$PROWLARR/api/v1/applications" \
  -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"Sonarr\",\"syncLevel\":\"fullSync\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"$PROWLARR\"},{\"name\":\"baseUrl\",\"value\":\"$SONARR\"},{\"name\":\"apiKey\",\"value\":\"$SONARR_KEY\"},{\"name\":\"syncCategories\",\"value\":[2000,2010,2020,2030,2040,2045,2050,2060]}],\"implementationName\":\"Sonarr\",\"implementation\":\"Sonarr\",\"configContract\":\"SonarrSettings\",\"infoLink\":\"\"}" > /dev/null
echo "  ✅ Sonarr"

# ── Prowlarr: add indexers ───────────────────────────────
echo ""
echo "📡 Adding indexers..."

APP_PROFILE_ID=$(curl -s "$PROWLARR/api/v1/appprofile" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['id'])" 2>/dev/null)
APP_PROFILE_ID=${APP_PROFILE_ID:-1}

add_indexer() {
  local defname="$1" name="$2"
  local schema
  schema=$(curl -s "$PROWLARR/api/v1/indexer/schema" -H "X-Api-Key: $PROWLARR_KEY" \
    | python3 -c "
import sys,json
data=json.load(sys.stdin)
m=next((x for x in data if x.get('definitionName','').lower()=='$defname'.lower()),None)
if m:
    m['name']='$name'; m['enableRss']=True; m['enableAutomaticSearch']=True
    m['enableInteractiveSearch']=True; m['appProfileId']=$APP_PROFILE_ID; m['priority']=25
    print(json.dumps(m))
" 2>/dev/null)
  [ -z "$schema" ] && echo "  ⚠️  $name — not found" && return
  result=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PROWLARR/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" -d "$schema")
  [ "$result" = "201" ] || [ "$result" = "200" ] && echo "  ✅ $name" || echo "  ⚠️  $name — HTTP $result"
}

add_indexer "yts"             "YTS"
add_indexer "nyaasi"          "Nyaa"
add_indexer "thepiratebay"    "The Pirate Bay"
add_indexer "limetorrents"    "LimeTorrents"
add_indexer "torrentdownload" "TorrentDownload"

# ── Force sync ───────────────────────────────────────────
echo ""
echo "⏳ Forcing Prowlarr sync to Radarr/Sonarr..."
curl -s -X POST "$PROWLARR/api/v1/applications/sync" -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
sleep 5

echo ""
echo "🔍 Checking Radarr indexers after sync..."
COUNT=$(curl -s "$RADARR/api/v3/indexer" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d))" 2>/dev/null)
echo "  Radarr has $COUNT indexer(s)"

# ── Download clients ─────────────────────────────────────
echo ""
echo "🗑️  Clearing download clients..."
for id in $(curl -s "$RADARR/api/v3/downloadclient" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$RADARR/api/v3/downloadclient/$id" -H "X-Api-Key: $RADARR_KEY" > /dev/null
done
for id in $(curl -s "$SONARR/api/v3/downloadclient" -H "X-Api-Key: $SONARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$SONARR/api/v3/downloadclient/$id" -H "X-Api-Key: $SONARR_KEY" > /dev/null
done

echo ""
echo "⚙️  Adding qBittorrent to Radarr..."
curl -s -X POST "$RADARR/api/v3/downloadclient" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"$QB_HOST\"},{\"name\":\"port\",\"value\":$QB_PORT},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_PASS\"},{\"name\":\"movieCategory\",\"value\":\"radarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Radarr"

echo ""
echo "⚙️  Adding qBittorrent to Sonarr..."
curl -s -X POST "$SONARR/api/v3/downloadclient" \
  -H "X-Api-Key: $SONARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"$QB_HOST\"},{\"name\":\"port\",\"value\":$QB_PORT},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_PASS\"},{\"name\":\"tvCategory\",\"value\":\"sonarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Sonarr"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Full reset complete."
echo "   Radarr indexer count: $COUNT"
echo "   Now search for a movie in Radarr to test."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
