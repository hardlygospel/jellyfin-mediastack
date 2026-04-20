#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │   🔧  JELLYFIN MEDIASTACK — FIX PROWLARR SYNC         │
# │                                                         │
# │  Run this if Radarr/Sonarr show 0 active indexers.    │
# │  Connects Prowlarr to both apps and forces a sync.     │
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

echo "  Prowlarr: $PROWLARR_KEY"
echo "  Radarr:   $RADARR_KEY"
echo "  Sonarr:   $SONARR_KEY"

echo ""
echo "🔗 Connecting Prowlarr → Radarr..."
curl -s -X POST "$PROWLARR/api/v1/applications" \
  -H "X-Api-Key: $PROWLARR_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Radarr\",\"syncLevel\":\"fullSync\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"$PROWLARR\"},{\"name\":\"baseUrl\",\"value\":\"$RADARR\"},{\"name\":\"apiKey\",\"value\":\"$RADARR_KEY\"},{\"name\":\"syncCategories\",\"value\":[2000,2010,2020,2030,2040,2045,2050,2060]}],\"implementationName\":\"Radarr\",\"implementation\":\"Radarr\",\"configContract\":\"RadarrSettings\",\"infoLink\":\"\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "🔗 Connecting Prowlarr → Sonarr..."
curl -s -X POST "$PROWLARR/api/v1/applications" \
  -H "X-Api-Key: $PROWLARR_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\":\"Sonarr\",\"syncLevel\":\"fullSync\",\"fields\":[{\"name\":\"prowlarrUrl\",\"value\":\"$PROWLARR\"},{\"name\":\"baseUrl\",\"value\":\"$SONARR\"},{\"name\":\"apiKey\",\"value\":\"$SONARR_KEY\"},{\"name\":\"syncCategories\",\"value\":[2000,2010,2020,2030,2040,2045,2050,2060]}],\"implementationName\":\"Sonarr\",\"implementation\":\"Sonarr\",\"configContract\":\"SonarrSettings\",\"infoLink\":\"\"}" > /dev/null
echo "  ✅ Done"

echo ""
echo "⏳ Forcing Prowlarr sync..."
curl -s -X POST "$PROWLARR/api/v1/applications/sync" \
  -H "X-Api-Key: $PROWLARR_KEY" > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Prowlarr synced to Radarr and Sonarr."
echo "   Check Radarr → Settings → Indexers to confirm."
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
