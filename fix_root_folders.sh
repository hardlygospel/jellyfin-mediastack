#!/bin/bash

# ┌─────────────────────────────────────────────────────────┐
# │     🔧  JELLYFIN MEDIASTACK — FIX ROOT FOLDERS        │
# │                                                         │
# │  Run this if Radarr/Sonarr show a "root folder does    │
# │  not exist" error. Clears wrong paths and sets the     │
# │  correct container paths (/movies and /tv).            │
# └─────────────────────────────────────────────────────────┘

RADARR="http://localhost:7878"
SONARR="http://localhost:8989"

echo "🔑 Grabbing API keys..."
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
SONARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/sonarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

if [ -z "$RADARR_KEY" ] || [ -z "$SONARR_KEY" ]; then
  echo "❌ Could not read API keys. Are the containers running?"
  exit 1
fi

echo ""
echo "🗑️  Clearing existing Radarr root folders..."
curl -s "$RADARR/api/v3/rootfolder" -H "X-Api-Key: $RADARR_KEY" \
  | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+' | while read id; do
    curl -s -X DELETE "$RADARR/api/v3/rootfolder/$id" -H "X-Api-Key: $RADARR_KEY" > /dev/null
    echo "  🗑️  Removed folder ID $id"
done

echo "📁 Setting Radarr root folder → /movies"
curl -s -X POST "$RADARR/api/v3/rootfolder" \
  -H "X-Api-Key: $RADARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"path":"/movies"}' > /dev/null
echo "  ✅ Done"

echo ""
echo "🗑️  Clearing existing Sonarr root folders..."
curl -s "$SONARR/api/v3/rootfolder" -H "X-Api-Key: $SONARR_KEY" \
  | grep -oE '"id":[0-9]+' | grep -oE '[0-9]+' | while read id; do
    curl -s -X DELETE "$SONARR/api/v3/rootfolder/$id" -H "X-Api-Key: $SONARR_KEY" > /dev/null
    echo "  🗑️  Removed folder ID $id"
done

echo "📁 Setting Sonarr root folder → /tv"
curl -s -X POST "$SONARR/api/v3/rootfolder" \
  -H "X-Api-Key: $SONARR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"path":"/tv"}' > /dev/null
echo "  ✅ Done"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Root folders fixed."
echo "   Radarr → /movies"
echo "   Sonarr → /tv"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
