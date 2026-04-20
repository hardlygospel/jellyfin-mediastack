# mediastack

A self-hosted media automation stack running in Docker on macOS. Drop a movie or show into Radarr/Sonarr (or let Jellyseerr request it), and it gets found, downloaded, and ready to watch — automatically.

---

## What's included

| Service | Purpose | URL |
|---|---|---|
| **Radarr** | Monitors and downloads movies | http://localhost:7878 |
| **Sonarr** | Monitors and downloads TV shows | http://localhost:8989 |
| **Prowlarr** | Manages torrent indexers, feeds them to Radarr/Sonarr | http://localhost:9696 |
| **qBittorrent** | Handles the actual torrent downloads | http://localhost:8080 |
| **Jellyseerr** | Request interface — browse and request movies/shows | http://localhost:5055 |

### How they connect

```
Jellyseerr → Radarr / Sonarr → Prowlarr → qBittorrent
                                              ↓
                                         ~/Downloads
```

Jellyseerr is optional — you can add content directly in Radarr/Sonarr if you prefer.

---

## Requirements

- macOS
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/hardlygospel/mediastack.git
cd mediastack
```

### 2. Check your volume paths

Open `docker-compose.yml` and confirm these paths match where you actually store things:

```yaml
~/Movies      # Radarr puts finished movies here
~/TV          # Sonarr puts finished shows here
~/Downloads   # qBittorrent downloads to here first
```

Change them if needed before continuing.

### 3. Start the stack

```bash
docker compose up -d
```

### 4. Configure everything

```bash
chmod +x configure_media_stack.sh && ./configure_media_stack.sh
```

This script will:
- Wait for all services to be ready
- Open each service in your browser to trigger first-time initialisation
- Pull API keys from each app automatically
- Add 6 free public indexers to Prowlarr (YTS, 1337x, EZTV, Nyaa, The Pirate Bay, Kickass Torrents)
- Connect Prowlarr to both Radarr and Sonarr
- Add qBittorrent as the download client in both Radarr and Sonarr

> **Note on qBittorrent:** New installs generate a temporary password printed in the container logs. The script detects this automatically. If it can't log in, it'll tell you exactly what to do.

---

## Restarting the stack

```bash
docker compose restart
```

Or to bring it fully down and back up:

```bash
docker compose down && docker compose up -d
```

---

## Letterboxd integration

You can feed a Letterboxd watchlist or list directly into Radarr so it automatically adds and searches for movies.

1. Get your Letterboxd RSS feed URL:
   - Watchlist: `https://letterboxd.com/<username>/watchlist/rss/`
   - Any list: `https://letterboxd.com/<username>/list/<list-name>/rss/`

2. In Radarr: **Settings → Lists → + → RSS List**
3. Paste the URL, set your quality profile, enable **Monitor** and **Search on Add**

Radarr will check the feed every 24 hours and grab anything new.

> **Note:** Letterboxd RSS only includes the 50 most recent items. Older entries won't sync automatically.

---

## Scripts

| Script | What it does |
|---|---|
| `docker-compose.yml` | Defines and starts all five containers |
| `configure_media_stack.sh` | Wires everything together after first boot |
