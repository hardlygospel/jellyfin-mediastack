#!/bin/bash
PROWLARR_KEY=$(grep -oE '<ApiKey>[^<]+' ~/docker/prowlarr/config/config.xml 2>/dev/null | sed 's/<ApiKey>//' | head -1)
curl -s "http://localhost:9696/api/v1/indexer/schema" -H "X-Api-Key: $PROWLARR_KEY" \
  | python3 -c "import sys,json; [print(x['definitionName']) for x in json.load(sys.stdin)]" | sort
