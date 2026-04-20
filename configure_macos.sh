#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │        🍎  JELLYFIN MEDIASTACK — macOS SETUP           │
# │                                                         │
# │  Run this after: docker compose up -d                   │
# │  Wires together Prowlarr, Radarr, Sonarr, qBittorrent  │
# └─────────────────────────────────────────────────────────┘

set -e

PROWLARR="http://localhost:9696"
RADARR="http://localhost:7878"
SONARR="http://localhost:8989"
QB="http://localhost:8080"

echo "⏳ Waiting for services to be ready..."
for service in "$PROWLARR" "$RADARR" "$SONARR" "$QB"; do
  for i in {1..30}; do
    if curl -s "$service" > /dev/null 2>&1; then
      echo "✅ $service is up"
      break
    fi
    sleep 2
  done
done

open http://localhost:7878
open http://localhost:8989
open http://localhost:9696
open http://localhost:8080
sleep 10

echo ""
echo "🔑 Grabbing API keys..."

get_api_key() {
  local config_path="$1"
  for i in {1..15}; do
    if [ -f "$config_path" ]; then
      local key
      key=$(grep -oE '<ApiKey>[^<]+' "$config_path" 2>/dev/null | sed 's/<ApiKey>//' | head -1)
      if [ -n "$key" ]; then
        echo "$key"
        return
      fi
    fi
    sleep 2
  done
  echo ""
}

PROWLARR_KEY=$(get_api_key "$HOME/docker/prowlarr/config/config.xml")
RADARR_KEY=$(get_api_key "$HOME/docker/radarr/config/config.xml")
SONARR_KEY=$(get_api_key "$HOME/docker/sonarr/config/config.xml")

echo "Prowlarr: $PROWLARR_KEY"
echo "Radarr:   $RADARR_KEY"
echo "Sonarr:   $SONARR_KEY"

echo ""
echo "⚙️  Configuring qBittorrent..."

QB_USER="admin"
QB_PASS="adminadmin"
QB_NEW_PASS="mediastack123"

QB_TEMP_PASS=$(docker logs qbittorrent 2>&1 | grep -i "temporary password" | grep -oE '[A-Za-z0-9]{8,}' | tail -1)
if [ -n "$QB_TEMP_PASS" ]; then
  echo "  🔑 Detected temp password: $QB_TEMP_PASS"
  QB_PASS="$QB_TEMP_PASS"
fi

curl -s -c /tmp/qb_cookies.txt -b /tmp/qb_cookies.txt -X POST "$QB/api/v2/auth/login" \
  -d "username=$QB_USER&password=$QB_PASS" > /dev/null 2>&1 || true

if grep -q "SID" /tmp/qb_cookies.txt 2>/dev/null; then
  curl -s -b /tmp/qb_cookies.txt "$QB/api/v2/app/setPreferences" \
    -d "json={\"save_path\":\"/downloads\",\"web_ui_password\":\"$QB_NEW_PASS\"}" > /dev/null
  echo "✅ qBittorrent configured (password set to: $QB_NEW_PASS)"
else
  echo ""
  echo "⚠️  Could not log into qBittorrent automatically."
  echo "   👉 Go to http://localhost:8080 and log in manually."
  echo "   👉 Then go to Tools → Options → Web UI and set the password to: $QB_NEW_PASS"
  echo "   👉 Once done, re-run this script so Radarr/Sonarr get the right password."
  echo ""
  QB_NEW_PASS="adminadmin"
fi

echo ""
echo "📁 Setting root folders..."

RADARR_FOLDERS=$(curl -s "$RADARR/api/v3/rootfolder" -H "X-Api-Key: $RADARR_KEY")
for id in $(echo "$RADARR_FOLDERS" | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$RADARR/api/v3/rootfolder/$id" -H "X-Api-Key: $RADARR_KEY" > /dev/null
done
curl -s -X POST "$RADARR/api/v3/rootfolder" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d '{"path":"/movies"}' > /dev/null
echo "  ✅ Radarr root folder → /movies"

SONARR_FOLDERS=$(curl -s "$SONARR/api/v3/rootfolder" -H "X-Api-Key: $SONARR_KEY")
for id in $(echo "$SONARR_FOLDERS" | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$SONARR/api/v3/rootfolder/$id" -H "X-Api-Key: $SONARR_KEY" > /dev/null
done
curl -s -X POST "$SONARR/api/v3/rootfolder" \
  -H "X-Api-Key: $SONARR_KEY" -H "Content-Type: application/json" \
  -d '{"path":"/tv"}' > /dev/null
echo "  ✅ Sonarr root folder → /tv"

echo ""
echo "📡 Adding indexers to Prowlarr..."

APP_PROFILE_ID=$(curl -s "$PROWLARR/api/v1/appprofile" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['id'])" 2>/dev/null)
APP_PROFILE_ID=${APP_PROFILE_ID:-1}

# Clear existing indexers first
for id in $(curl -s "$PROWLARR/api/v1/indexer" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "import sys,json; [print(x['id']) for x in json.load(sys.stdin)]" 2>/dev/null); do
  curl -s -X DELETE "$PROWLARR/api/v1/indexer/$id" -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
done

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
  if [ -z "$schema" ]; then echo "  ⚠️  $name — not found"; return; fi
  local result
  result=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$PROWLARR/api/v1/indexer" \
    -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" -d "$schema")
  [ "$result" = "201" ] || [ "$result" = "200" ] && echo "  ✅ $name" || echo "  ⚠️  $name — HTTP $result"
}

add_indexer "yts"             "YTS"
add_indexer "nyaasi"          "Nyaa"
add_indexer "thepiratebay"    "The Pirate Bay"
add_indexer "limetorrents"    "LimeTorrents"
add_indexer "torrentdownload" "TorrentDownload"

echo ""
echo "🔗 Connecting Prowlarr to Radarr and Sonarr..."

add_prowlarr_app() {
  local name="$1"
  local url="$2"
  local apikey="$3"
  local apptype="$4"
  curl -s -X POST "$PROWLARR/api/v1/applications" \
    -H "X-Api-Key: $PROWLARR_KEY" -H "Content-Type: application/json" \
    -d "{\"name\":\"$name\",\"syncLevel\":\"fullSync\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"$PROWLARR\"},{\"name\":\"baseUrl\",\"value\":\"$url\"},{\"name\":\"apiKey\",\"value\":\"$apikey\"},{\"name\":\"syncCategories\",\"value\":[2000,2010,2020,2030,2040,2045,2050,2060]}],\"implementationName\":\"$apptype\",\"implementation\":\"$apptype\",\"configContract\":\"${apptype}Settings\",\"infoLink\":\"\"}" > /dev/null
  echo "  ✅ $name"
}

add_prowlarr_app "Radarr" "$RADARR" "$RADARR_KEY" "Radarr"
add_prowlarr_app "Sonarr" "$SONARR" "$SONARR_KEY" "Sonarr"

echo ""
echo "⏳ Forcing Prowlarr sync..."
curl -s -X POST "$PROWLARR/api/v1/applications/sync" -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
echo "  ✅ Done"

echo ""
echo "⚙️  Adding qBittorrent to Radarr..."
curl -s -X POST "$RADARR/api/v3/downloadclient" \
  -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"localhost\"},{\"name\":\"port\",\"value\":8080},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_NEW_PASS\"},{\"name\":\"movieCategory\",\"value\":\"radarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "⚙️  Adding qBittorrent to Sonarr..."
curl -s -X POST "$SONARR/api/v3/downloadclient" \
  -H "X-Api-Key: $SONARR_KEY" -H "Content-Type: application/json" \
  -d "{\"name\":\"qBittorrent\",\"enable\":true,\"protocol\":\"torrent\",\"priority\":1,\"fields\":[{\"name\":\"host\",\"value\":\"localhost\"},{\"name\":\"port\",\"value\":8080},{\"name\":\"username\",\"value\":\"admin\"},{\"name\":\"password\",\"value\":\"$QB_NEW_PASS\"},{\"name\":\"tvCategory\",\"value\":\"sonarr\"}],\"implementationName\":\"qBittorrent\",\"implementation\":\"QBittorrent\",\"configContract\":\"QBittorrentSettings\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ All done."
echo ""
echo "  qBittorrent password: $QB_NEW_PASS"
echo "  Prowlarr API key:     $PROWLARR_KEY"
echo "  Radarr API key:       $RADARR_KEY"
echo "  Sonarr API key:       $SONARR_KEY"
echo ""
echo "  Radarr:      http://localhost:7878"
echo "  Sonarr:      http://localhost:8989"
echo "  Prowlarr:    http://localhost:9696"
echo "  qBittorrent: http://localhost:8080"
echo "  Jellyseerr:  http://localhost:5055"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
