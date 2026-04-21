# 🎬 Jellyfin Mediastack

[![Stars](https://img.shields.io/github/stars/hardlygospel/jellyfin-mediastack?style=for-the-badge&color=yellow)](https://github.com/hardlygospel/jellyfin-mediastack/stargazers) [![Forks](https://img.shields.io/github/forks/hardlygospel/jellyfin-mediastack?style=for-the-badge&color=blue)](https://github.com/hardlygospel/jellyfin-mediastack/network/members) [![Issues](https://img.shields.io/github/issues/hardlygospel/jellyfin-mediastack?style=for-the-badge&color=red)](https://github.com/hardlygospel/jellyfin-mediastack/issues) [![Last ComGPL-3.0 — see [LICENSE](LICENSE) for details.) [![macOS](https://img.shields.io/badge/macOS-supported-brightgreen?style=for-the-badge&logo=apple)](https://github.com/hardlygospel/jellyfin-mediastack) [![Linux](https://img.shields.io/badge/Linux-supported-brightgreen?style=for-the-badge&logo=linux)](https://github.com/hardlygospel/jellyfin-mediastack) [![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=for-the-badge&logo=gnubash)](https://github.com/hardlygospel/jellyfin-mediastack) [![Docker](https://img.shields.io/badge/Docker-ready-2496ED?style=for-the-badge&logo=docker)](https://github.com/hardlygospel/jellyfin-mediastack) [![Maintained](https://img.shields.io/badge/Maintained-yes-brightgreen?style=for-the-badge)](https://github.com/hardlygospel/jellyfin-mediastack) [![GitHub repo size](https://img.shields.io/github/repo-size/hardlygospel/jellyfin-mediastack?style=for-the-badge)](https://github.com/hardlygospel/jellyfin-mediastack) [![Code size](https://img.shields.io/github/languages/code-size/hardlygospel/jellyfin-mediastack?style=for-the-badge)](https://github.com/hardlygospel/jellyfin-mediastack)
> A self-hosted media automation stack running in Docker. Drop a movie or show into Radarr/Sonarr (or let Jellyseerr request it), and it gets found, downloaded, and ready to watch — automatically. 🍿

---

## 🧩 What's Included

| Service | Purpose | URL |
|---|---|---|
| 🎥 **Radarr** | Monitors and downloads movies | http://localhost:7878 |
| 📺 **Sonarr** | Monitors and downloads TV shows | http://localhost:8989 |
| 🔍 **Prowlarr** | Manages torrent indexers | http://localhost:9696 |
| ⬇️ **qBittorrent** | Handles the actual torrent downloads | http://localhost:8080 |
| 🎞️ **Jellyfin** | Media server — watch your movies and shows | http://localhost:8096 |
| 🌐 **Jellyseerr** | Request interface — browse and request movies/shows | http://localhost:5055 |

### 🔗 How They Connect

```
Jellyseerr → Radarr / Sonarr → Prowlarr → qBittorrent
                                              ↓
                                         ~/Downloads
                                              ↓
                                          Jellyfin
```

> 💡 Jellyseerr is optional — you can add content directly in Radarr/Sonarr if you prefer.

---

## ✅ Requirements

- 🍎 **macOS** or 🐧 **Linux**
- 🐳 [Docker Desktop](https://www.docker.com/products/docker-desktop/) (macOS) or [Docker Engine](https://docs.docker.com/engine/install/) (Linux)

---

## 🚀 Setup

### 1️⃣ Clone the Repo

```bash
git clone https://github.com/hardlygospel/jellyfin-mediastack.git
cd jellyfin-mediastack
```

### 2️⃣ Check Your Volume Paths

Open `docker-compose.yml` and confirm the host-side paths match where you want to store things:

```yaml
~/Movies      # your Mac/Linux folder → mapped to /movies inside Radarr's container
~/TV          # your Mac/Linux folder → mapped to /tv inside Sonarr's container
~/Downloads   # your Mac/Linux folder → mapped to /downloads inside qBittorrent's container
```

> ✏️ Change the left-hand paths if needed. The right-hand container paths (`/movies`, `/tv`, `/downloads`) must stay as-is — the configure script sets Radarr and Sonarr up to use those automatically.

### 3️⃣ Start the Stack

```bash
docker compose up -d
```

### 4️⃣ Configure Everything

Pick the script for your OS:

```bash
# 🍎 macOS
bash configure_macos.sh

# 🐧 Linux
bash configure_linux.sh
```

This script will automatically:

- ⏳ Wait for all services to be ready
- 🌐 Open each service in your browser to trigger first-time initialisation
- 🔑 Pull API keys from each app automatically
- 📁 Set Radarr's root folder to `/movies` and Sonarr's to `/tv`
- 🔗 Connect Prowlarr to Radarr & Sonarr using container networking
- 🔄 Force-sync indexers to Radarr & Sonarr
- 📦 Add 5 free public indexers to Prowlarr (YTS, Nyaa, The Pirate Bay, LimeTorrents, TorrentDownload)
- ⬇️ Add qBittorrent as the download client in both Radarr and Sonarr

> ⚠️ **Note on qBittorrent:** New installs generate a temporary password printed in the container logs. The script detects this automatically. If it can't log in, it'll tell you exactly what to do.

### 5️⃣ Set Up Jellyfin

Open http://localhost:8096 and complete the setup wizard:

- Create your admin account
- Add a **Movies** library → folder: `/data/movies`
- Add a **TV Shows** library → folder: `/data/tv`

### 6️⃣ Set Up Jellyseerr

```bash
bash configure_jellyseerr.sh
```

Then open http://localhost:5055 and sign in with your Jellyfin credentials.

---

## 🔄 Restarting the Stack

```bash
docker compose restart
```

Or to bring it fully down and back up:

```bash
docker compose down && docker compose up -d
```

---

## 🎞️ Letterboxd Integration

Feed a Letterboxd watchlist or list directly into Radarr so it automatically adds and searches for movies!

**1. Get your Letterboxd RSS feed URL:**
- 📋 Watchlist: `https://letterboxd.com/<username>/watchlist/rss/`
- 📁 Any list: `https://letterboxd.com/<username>/list/<list-name>/rss/`

**2.** In Radarr: **Settings → Lists → + → RSS List**

**3.** Paste the URL, set your quality profile, enable **Monitor** and **Search on Add**

Radarr will check the feed every 24 hours and grab anything new. 🤖

> 📌 **Note:** Letterboxd RSS only includes the 50 most recent items. Older entries won't sync automatically.

---

## 📁 Files

| File | What it does |
|---|---|
| `docker-compose.yml` | 🐳 Defines and starts all six containers |
| `configure_macos.sh` | 🍎 Wires everything together on macOS |
| `configure_linux.sh` | 🐧 Wires everything together on Linux |
| `configure_jellyseerr.sh` | 🌐 Connects Jellyseerr to Jellyfin, Radarr, and Sonarr |
| `health_check.sh` | 🏥 Checks all containers, indexers, and download clients |
| `full_reset.sh` | 🔄 Nuclear option — rebuilds all Prowlarr connections from scratch |
| `FIXES.md` | 📋 Documents all bugs found and fixed during build |
