#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │       🌐  JELLYFIN MEDIASTACK — JELLYSEERR SETUP       │
# │                                                         │
# │  Run this after the main configure script              │
# │  Connects Jellyseerr to Jellyfin, Radarr, and Sonarr   │
# └─────────────────────────────────────────────────────────┘

set -e

JELLYSEERR="http://localhost:5055"
SETTINGS="$HOME/docker/jellyseerr/config/settings.json"

RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' "$HOME/docker/radarr/config/config.xml" 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' "$HOME/docker/sonarr/config/config.xml" 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
  echo "❌ Could not read Radarr/Sonarr API keys. Is the stack running?"
  exit 1
fi

echo "⏳ Waiting for Jellyseerr..."
for i in {1..15}; do
  code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$JELLYSEERR")
  case "$code" in 200|302|307) break ;; esac
  sleep 2
done

# Get Jellyseerr API key from its config file
JS_KEY=$(python3 -c "import json; print(json.load(open('$SETTINGS'))['main']['apiKey'])" 2>/dev/null)
if [ -z "$JS_KEY" ]; then
  echo "❌ Could not read Jellyseerr API key from $SETTINGS"
  exit 1
fi

echo "⚙️  Adding Radarr..."
RADARR_RESULT=$(curl -s -X POST "$JELLYSEERR/api/v1/settings/radarr" \
  -H "X-Api-Key: $JS_KEY" \
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
echo "$RADARR_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Radarr (id: '+str(d.get('id','?'))+')')" 2>/dev/null \
  || echo "  ⚠️  Radarr: $RADARR_RESULT"

echo ""
echo "⚙️  Adding Sonarr..."
SONARR_RESULT=$(curl -s -X POST "$JELLYSEERR/api/v1/settings/sonarr" \
  -H "X-Api-Key: $JS_KEY" \
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
echo "$SONARR_RESULT" | python3 -c "import sys,json; d=json.load(sys.stdin); print('  ✅ Sonarr (id: '+str(d.get('id','?'))+')')" 2>/dev/null \
  || echo "  ⚠️  Sonarr: $SONARR_RESULT"

echo ""
echo "⏳ Finalising setup..."
curl -s -X POST "$JELLYSEERR/api/v1/settings/initialize" \
  -H "X-Api-Key: $JS_KEY" -H "Content-Type: application/json" > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Jellyseerr configured."
echo ""
echo "  Open http://localhost:5055"
echo "  Sign in with your Jellyfin credentials"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
