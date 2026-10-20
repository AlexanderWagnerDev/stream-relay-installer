# Stream Relay Installer

[![Docker Hub](https://img.shields.io/docker/pulls/alexanderwagnerdev/rtmp-server?style=flat-square)](https://hub.docker.com/r/alexanderwagnerdev/rtmp-server)
[![License](https://img.shields.io/github/license/AlexanderWagnerDev/stream-relay-installer?style=flat-square)](LICENSE)

Interactive Debian/Ubuntu installer for OpenRTMP, RTMPPanel, SRTLA and SLSPanel.

Branch: **beta** · Server image: `alexanderwagnerdev/rtmp-server:beta` · Panel image: `alexanderwagnerdev/rtmppanel:beta`.

## ✨ Features

- OpenRTMP HTTP API, stream management and live statistics
- RTMPPanel with configurable authentication
- Persistent SQLite data and a stable panel encryption secret
- Docker Hub/GHCR images and Docker Compose deployment

## 🚀 Quick Start

The [stream-relay-installer](https://github.com/AlexanderWagnerDev/stream-relay-installer/tree/beta) offers guided setup and service management. Docker Engine 20.10+ and Docker Compose v2 are required for the examples. The Compose file starts the RTMP server and its management panel together.

The OpenRTMP-based `alexanderwagnerdev/rtmp-server:beta` image must be published and available in the registry before using the installer or Docker Compose.

### Interactive installer

```bash
curl -fL --proto '=https' --tlsv1.2 -o install.sh https://raw.githubusercontent.com/AlexanderWagnerDev/stream-relay-installer/beta/install.sh
bash install.sh
```

Choose German/English, installation or lifecycle action, services, ports and panel login. The script uses `beta` images for RTMP, RTMPPanel, SRTLA and SLSPanel; WUD retains its own latest tag. Start/stop/update/uninstall include RTMPPanel. Credentials are stored in `.rtmp_api_token` and `.rtmppanel_secret` with mode 600. Keep the secret with the panel database.

### Docker Compose

```bash
git clone --branch beta https://github.com/AlexanderWagnerDev/stream-relay-installer.git
cd stream-relay-installer
cp .env.example .env
# Edit .env: API token, stable SECRET_KEY, password and public domain.
# Generate API token and SECRET_KEY separately: openssl rand -hex 32
docker compose config --quiet
docker compose up -d
```

Panel: `http://localhost:8001`. Backend health: `http://localhost:8090/api/v1/health`.

## 📖 Usage

Create streams in RTMPPanel and copy the provided publish, playback and statistics URLs. Publishing and playback keys may differ. The default application is `live`; freely chosen nginx `/publish/key` URLs do not create streams.

```bash
docker compose ps
docker compose logs -f rtmp-server
```

## 🔌 Ports

| Service | Host | Container | Protocol |
| --- | --- | --- | --- |
| RTMP | 1935 | 1935 | TCP |
| RTMP API | 8090 | 8080 | TCP |
| RTMPPanel | 8001 | 8000 | TCP |

The panel reaches the API over the shared Compose network.

## ⚙️ Configuration and storage

See [configuration](docs/configuration.md) for all environment settings, networking, storage and troubleshooting, and [migration](docs/migration.md) for the nginx transition. Copy `.env.example`, generate credentials, and keep `.env` and volume backups private. The panel `SECRET_KEY` must stay unchanged across updates.

## 🔄 Updates

```bash
docker compose pull
docker compose up -d
```

Retain the same Compose project name, `.env` and named volumes. Do not combine a Compose deployment with a shell-installer deployment using the same names/ports. `docker compose down -v` deletes stored data.

## 📦 Built With / Related Projects

- [OpenRTMP/librtmp2-server](https://github.com/OpenRTMP/librtmp2-server)
- [OpenRTMP/librtmp2-server-panel](https://github.com/OpenRTMP/librtmp2-server-panel)
- [RTMP server Docker](https://github.com/AlexanderWagnerDev/rtmp-server-docker)
- [RTMPPanel Docker](https://github.com/AlexanderWagnerDev/rtmppanel-docker)
- [SRTLA server Docker](https://github.com/AlexanderWagnerDev/srtla-server-docker)
- [SLSPanel Docker](https://github.com/AlexanderWagnerDev/slspanel-docker)

## 📄 License

See [LICENSE](LICENSE). Upstream components retain their respective licenses.

---

# Stream Relay Installer (Deutsch)

Branch **beta**: OpenRTMP-Server mit RTMPPanel, persistenten Daten und konfigurierbarer Anmeldung. Die Struktur folgt SRTLA-Server und SLSPanel: Compose-Datei, Umgebungsbeispiel, Konfiguration, Fehlerbehebung und Projektlinks.

## 🚀 Schnellstart

Das OpenRTMP-basierte Image `alexanderwagnerdev/rtmp-server:beta` muss veröffentlicht und in der Registry verfügbar sein, bevor der Installer oder Docker Compose verwendet wird.

Den oben gezeigten Branch klonen, `.env.example` nach `.env` kopieren und API-Token, festen `SECRET_KEY`, Passwort und öffentliche Domain eintragen. API-Token und Secret mit jeweils einem eigenen Aufruf von `openssl rand -hex 32` erzeugen. Danach `docker compose config --quiet` und `docker compose up -d` ausführen.

Die Compose-Datei startet Server und Panel gemeinsam; das Panel erreicht den Server intern über `rtmp-server:8080`.

## 📖 Verwendung und Konfiguration

Das Panel läuft standardmäßig auf Port **8001**, die RTMP-API auf **8090**, RTMP auf **1935**. Streams im Panel anlegen und die dort angezeigten Sende-, Wiedergabe- und Statistik-URLs verwenden. Sende- und Wiedergabe-Keys können verschieden sein.

[Konfiguration und Fehlerbehebung](docs/configuration.md) · [Migration von nginx](docs/migration.md)

Bei Updates `.env`, denselben Compose-Projektnamen, Datenvolumes und den festen `SECRET_KEY` behalten. `docker compose down -v` löscht Daten. Den interaktiven Installer und Compose als getrennte Installationswege behandeln; beim Wechsel Daten ausdrücklich migrieren.

## 📄 Lizenz

Details siehe [LICENSE](LICENSE).
