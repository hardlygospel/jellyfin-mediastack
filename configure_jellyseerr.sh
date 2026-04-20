#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │       🌐  JELLYFIN MEDIASTACK — JELLYSEERR SETUP       │
# │                                                         │
# │  Run this after the main configure script              │
# │  Connects Jellyseerr to Jellyfin, Radarr, and Sonarr   │
# └─────────────────────────────────────────────────────────┘

set -e

JELLYSEERR="http://localhost:5055"
JELLYFIN_URL="http://jellyfin:8096"
RADARR_INT="http://radarr:7878"
SONARR_INT="http://sonarr:8989"

RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' "$HOME/docker/radarr/config/config.xml" 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' "$HOME/docker/sonarr/config/config.xml" 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
  echo "❌ Could not read Radarr/Sonarr API keys. Is the stack running?"
  exit 1
fi

echo ""
read -p "  Jellyfin username: " JF_USER
read -s -p "  Jellyfin password: " JF_PASS
echo ""
echo ""

echo "⏳ Waiting for Jellyseerr..."
for i in {1..15}; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$JELLYSEERR")
  [ "$code" = "200" ] || [ "$code" = "302" ] || [ "$code" = "307" ] && break
  sleep 2
done

echo "🔑 Signing in to Jellyseerr via Jellyfin..."
AUTH=$(curl -s -c /tmp/js_cookies.txt -b /tmp/js_cookies.txt \
  -X POST "$JELLYSEERR/api/v1/auth/jellyfin" \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"$JF_USER\",\"password\":\"$JF_PASS\",\"hostname\":\"$JELLYFIN_URL\"}")

echo "$AUTH" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Signed in as: '+d.get('displayName',d.get('username','?')))" 2>/dev/null \
  || { echo "  ❌ Auth failed: $AUTH"; exit 1; }

echo ""
echo "⚙️  Adding Radarr..."
RADARR_RESULT=$(curl -s -b /tmp/js_cookies.txt \
  -X POST "$JELLYSEERR/api/v1/settings/radarr" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Radarr\",
    \"hostname\": \"radarr\",
    \"port\": 7878,
    \"apiKey\": \"$RADARR_KEY\",
    \"useSsl\": false,
    \"baseUrl\": \"\",
    \"activeProfileId\": 6,
    \"activeProfileName\": \"HD - 720p/1080p\",
    \"activeDirectory\": \"/movies\",
    \"is4k\": false,
    \"minimumAvailability\": \"released\",
    \"isDefault\": true,
    \"externalUrl\": \"http://localhost:7878\",
    \"syncEnabled\": false,
    \"preventSearch\": false
  }")
echo "$RADARR_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Radarr added (id: '+str(d.get('id','?'))+')')" 2>/dev/null \
  || echo "  ⚠️  Radarr: $RADARR_RESULT"

echo ""
echo "⚙️  Adding Sonarr..."
SONARR_RESULT=$(curl -s -b /tmp/js_cookies.txt \
  -X POST "$JELLYSEERR/api/v1/settings/sonarr" \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Sonarr\",
    \"hostname\": \"sonarr\",
    \"port\": 8989,
    \"apiKey\": \"$SONARR_KEY\",
    \"useSsl\": false,
    \"baseUrl\": \"\",
    \"activeProfileId\": 6,
    \"activeProfileName\": \"HD - 720p/1080p\",
    \"activeDirectory\": \"/tv\",
    \"is4k\": false,
    \"isDefault\": true,
    \"externalUrl\": \"http://localhost:8989\",
    \"syncEnabled\": false,
    \"preventSearch\": false,
    \"enableSeasonFolders\": true
  }")
echo "$SONARR_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Sonarr added (id: '+str(d.get('id','?'))+')')" 2>/dev/null \
  || echo "  ⚠️  Sonarr: $SONARR_RESULT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Jellyseerr configured."
echo ""
echo "  Open http://localhost:5055 and complete the setup wizard."
echo "  When it asks for Jellyfin URL use: http://jellyfin:8096"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
