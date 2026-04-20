# 🔧 Mediastack — Issues Found & Fixed

A record of every bug discovered and fixed during initial setup.

---

## 1. 🗂️ Wrong root folder paths

**Problem:** Radarr and Sonarr were configured with `~/Movies` and `~/TV` — the host machine paths. Inside Docker containers, those paths don't exist.

**Fix:** Root folders must use the container-mapped paths:
- Radarr → `/movies`
- Sonarr → `/tv`

**Script:** `fix_root_folders.sh`

---

## 2. 📡 Indexers not syncing to Radarr/Sonarr

**Problem:** Prowlarr had indexers added but Radarr showed "0 active indexers". The Prowlarr→Radarr/Sonarr app connection was using `localhost` URLs, which containers can't resolve — they need to use each other's container names.

**Fix:** Prowlarr app connections must use Docker container names, not `localhost`:
- `prowlarrUrl` → `http://prowlarr:9696`
- Radarr `baseUrl` → `http://radarr:7878`
- Sonarr `baseUrl` → `http://sonarr:8989`

**Script:** `fix_prowlarr_sync.sh`, `full_reset.sh`

---

## 3. 📦 Indexer API calls missing required fields

**Problem:** Adding indexers to Prowlarr via the API returned HTTP 400. The API requires `implementation`, `configContract`, `appProfileId`, and `priority` — all of which must be fetched from Prowlarr's schema endpoint first.

**Fix:** Fetch each indexer's full schema from `GET /api/v1/indexer/schema`, populate the required fields, then POST.

**Script:** `fix_indexers.sh`

---

## 4. 🚫 Cloudflare-blocked indexers

**Problem:** 1337x, EZTV, and Kickass Torrents all returned HTTP 400 with "blocked by Cloudflare Protection" — Prowlarr can't reach them from inside Docker.

**Fix:** Replaced with indexers that work without Cloudflare bypass:
- ✅ YTS
- ✅ Nyaa
- ✅ The Pirate Bay
- ✅ LimeTorrents
- ✅ TorrentDownload

**Script:** `fix_indexers.sh`

---

## 5. ⬇️ qBittorrent not receiving downloads

**Problem:** Radarr was configured with `localhost:8080` as the qBittorrent host. From inside the Radarr container, `localhost` refers to itself — not the host machine or the qBittorrent container.

**Fix:** Use the Docker container name as the host:
- `host` → `qbittorrent`
- `port` → `8080`

**Script:** `fix_download_client.sh`

---

## 6. 🔌 Download client not configured at all

**Problem:** The original configure script set up the download client connection but it wasn't persisting, leaving Radarr with no download client configured.

**Fix:** `fix_download_client.sh` clears any existing clients and re-adds qBittorrent cleanly.

---

## ✅ Final working configuration

| Connection | Value |
|---|---|
| Radarr root folder | `/movies` |
| Sonarr root folder | `/tv` |
| qBittorrent host (from Radarr/Sonarr) | `qbittorrent` |
| Prowlarr URL (from Prowlarr config) | `http://prowlarr:9696` |
| Radarr URL (from Prowlarr config) | `http://radarr:7878` |
| Sonarr URL (from Prowlarr config) | `http://sonarr:8989` |

---

## 🔄 If it breaks again

Run this — it wipes and reconfigures everything from scratch:

```bash
git pull && bash full_reset.sh
```
