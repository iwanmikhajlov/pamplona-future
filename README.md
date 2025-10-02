# Pamplona Future AIO

Fork with pretty menu and plug-and-play dockerization for easy server setup.

<img width="525" height="475" alt="Menu Preview" src="https://github.com/user-attachments/assets/f6a63f6e-e4ed-42ad-a0af-f7e7c1dd4ead" />

---

## Quick Start

### Prerequisites

1. **Download and Install Docker Desktop**
   https://www.docker.com/

   **Important:** Select WSL2 option during installation

   **Reboot** your PC after installation completes

### Installation

2. **Open PowerShell** and run:

   ```powershell
   irm https://iwanmikhajlov.github.io/pamplona-future-aio/server.ps1 | iex
   ```

3. **Follow the menu** to install and configure the server

4. **Launch the game** and enjoy!

---

## Manual Setup

If you want to tinker it for some reason:

### Build you own image

Clone repo and edit dockerfile, use docker-compose and .env from upstream branch, etc.

```bash
git clone https://github.com/iwanmikhajlov/pamplona-future-aio
cd pamplona-future-aio
git checkout aio
docker build -t pamplona-future .
```

### Run manually

Replace `C:\path\to\game` with your actual game path:

```powershell
docker network create pamplona-net

docker run -d --name pamplona-future-db `
  --network pamplona-net `
  -e POSTGRES_USER=dbuser `
  -e POSTGRES_PASSWORD=changeme `
  -e POSTGRES_DB=dbname `
  postgres:17

docker run -d --name pamplona-future `
  --network pamplona-net `
  -p 3000:3000 -p 25565:25565 -p 42230:42230 `
  -e GATEWAY_PORT=3000 `
  -e BLAZE_PORT=25565 `
  -e POSTGRES_USER=dbuser `
  -e POSTGRES_PASSWORD=changeme `
  -e POSTGRES_DB=dbname `
  -e POSTGRES_HOSTNAME=pamplona-future-db `
  -e POSTGRES_PORT=5432 `
  -e HOSTNAME=localhost `
  -e GAME_PATH=/mitm_volume `
  -e USER_ID=2407107883 `
  -e PERSONA_ID=1011786733 `
  -e PERSONA_USERNAME=Player `
  -v "C:\path\to\game:/mitm_volume" `
  pamplona-future
```

### Useful commands

**View logs:**
```powershell
docker logs -f pamplona-future
```

**Stop and remove:**
```powershell
docker stop pamplona-future pamplona-future-db
docker rm pamplona-future pamplona-future-db
docker network rm pamplona-net
```

### Or install everyting completely from scratch w/o Docker

Go to server developer repositories, described in Credits section, clone both repos, deploy all dependencies, such as Node.js, PostgreSQL, then compile the server, and copy mitm .dll & .ini files into your game folder. For more info check README.md in following repos

---

## Credits

Huge respect to ploxxxy and everyone who participated in server development

**pamplona-future sources:** https://github.com/ploxxxy/pamplona-future

**catalyst-mitm sources:** https://github.com/ploxxxy/catalyst-mitm
