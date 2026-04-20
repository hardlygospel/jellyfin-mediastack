#!/bin/bash
RADARR="http://localhost:7878"
RADARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/radarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)

echo "📋 Active indexers in Radarr:"
curl -s "$RADARR/api/v3/indexer" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "
import sys,json
indexers = json.load(sys.stdin)
if not indexers:
    print('  ❌ None')
else:
    for i in indexers: print(f'  ✅ {i[\"name\"]} (enable: {i[\"enable\"]})')
"

echo ""
echo "🎬 Movies in Radarr:"
curl -s "$RADARR/api/v3/movie" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "
import sys,json
movies = json.load(sys.stdin)
for m in movies[:5]:
    print(f'  [{m[\"id\"]}] {m[\"title\"]} — monitored: {m[\"monitored\"]} hasFile: {m[\"hasFile\"]}')
"

echo ""
echo "📥 Radarr queue (active downloads):"
curl -s "$RADARR/api/v3/queue" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "
import sys,json
q = json.load(sys.stdin)
records = q.get('records', [])
if not records:
    print('  Nothing in queue')
else:
    for r in records: print(f'  {r[\"title\"]} — {r[\"status\"]}')
"

echo ""
echo "🔍 Triggering search for first monitored movie..."
MOVIE_ID=$(curl -s "$RADARR/api/v3/movie" -H "X-Api-Key: $RADARR_KEY" \
  | python3 -c "import sys,json; movies=[m for m in json.load(sys.stdin) if m['monitored'] and not m['hasFile']]; print(movies[0]['id']) if movies else print('')" 2>/dev/null)

if [ -n "$MOVIE_ID" ]; then
  curl -s -X POST "$RADARR/api/v3/command" \
    -H "X-Api-Key: $RADARR_KEY" -H "Content-Type: application/json" \
    -d "{\"name\":\"MoviesSearch\",\"movieIds\":[$MOVIE_ID]}" > /dev/null
  echo "  Search triggered for movie ID $MOVIE_ID — check Radarr logs in 10 seconds"
  sleep 10
  docker logs radarr 2>&1 | grep -i "search\|indexer\|download\|result" | tail -10
else
  echo "  No undownloaded monitored movies found"
fi
