<img src="https://assets.stream-relay-installer.de/Logo.webp" alt="Logo" width="400" />

# Stream Relay Installer  

This script installs **Docker** along with an **RTMP** and **SRTLA relay server** on Debian and Ubuntu systems. It requires root access and sets up a complete stream relay environment.

---

## Features

- Installs Docker  
- Sets up RTMP and SRTLA relay server  
- Supports English and German languages  
- Designed for Debian and Ubuntu  
- Can run on a fresh system  
- Server fully operational after reboot  

---

## Included Software

- **RTMP Server** – [AlexanderWagnerDev/rtmp-server-docker](https://github.com/AlexanderWagnerDev/rtmp-server-docker) 
- **SRTLA Relay Server** – [AlexanderWagnerDev/srtla-server-docker](https://github.com/AlexanderWagnerDev/srtla-server-docker)
- **RTMPPanel** – [AlexanderWagnerDev/rtmppanel-docker](https://github.com/AlexanderWagnerDev/rtmppanel-docker)
- **SLSPanel** - [AlexanderWagnerDev/slspanel-docker](https://github.com/AlexanderWagnerDev/slspanel-docker)
- WUD - [getwud/wud](https://github.com/getwud/wud)

SRTLA Server is based on [OpenIRL](https://github.com/OpenIRL)

---

## Requirements

- Debian or Ubuntu system  
- Root or sudo access  
- Internet connection for downloading required packages  

---

## Installation

Run the following command to start the installation:
```bash
bash <(curl -fsSL https://install.stream-relay-installer.de)
```


After the script finishes, reboot your system for the changes to take effect.

---

## Usage

Once rebooted, your stream relay server will be ready to use with default configurations.

---

## Deutsch

Dieses Skript installiert **Docker** sowie einen **RTMP**- und **SRTLA-Relay-Server** auf Debian- und Ubuntu-Systemen. Es benötigt Root-Zugriff und richtet eine vollständige Stream-Relay-Umgebung ein.

---

## Funktionen

- Installation von Docker  
- Einrichtung von RTMP- und SRTLA-Relay-Server  
- Unterstützung von Deutsch und Englisch  
- Entwickelt für Debian und Ubuntu  
- Kann auf einem frischen System ausgeführt werden  
- Server nach Neustart einsatzbereit  

---

## Enthaltene Software

- **RTMP Server** – [AlexanderWagnerDev/rtmp-server-docker](https://github.com/AlexanderWagnerDev/rtmp-server-docker) 
- **SRTLA Relay Server** – [AlexanderWagnerDev/srtla-server-docker](https://github.com/AlexanderWagnerDev/srtla-server-docker)
- **RTMPPanel** – [AlexanderWagnerDev/rtmppanel-docker](https://github.com/AlexanderWagnerDev/rtmppanel-docker)
- **SLSPanel** - [AlexanderWagnerDev/slspanel-docker](https://github.com/AlexanderWagnerDev/slspanel-docker)
- WUD - [getwud/wud](https://github.com/getwud/wud)

SRTLA Server basierend auf [OpenIRL](https://github.com/OpenIRL)

---

## Voraussetzungen

- Debian- oder Ubuntu-System  
- Root- oder sudo-Zugriff  
- Internetverbindung zum Herunterladen der erforderlichen Pakete  

---

## Installation

Führe den folgenden Befehl aus, um die Installation zu starten:
```bash
bash <(curl -fsSL https://install.stream-relay-installer.de)
```

Nach Abschluss des Skripts den Server neu starten, damit die Änderungen übernommen werden.

---

## Nutzung

Nach dem Neustart ist dein Stream-Relay-Server mit den Standardkonfigurationen einsatzbereit.

---

## License

MIT

## OpenRTMP

RTMP now uses OpenRTMP/librtmp2-server with HTTP API on host port 8090 (container 8080). RTMPPanel is optional on port 8001; SLSPanel remains on 8000. The installer stores the API token in `.rtmp_api_token`, the stable encryption secret in `.rtmppanel_secret` (mode 600), and databases in `rtmp-server-data` and `rtmppanel-data`. Keep the secret together with the panel database.

Updates remap legacy nginx HTTP port 80 to 8080 while retaining the host port and add persistent server storage. Old arbitrary nginx stream keys must be recreated in RTMPPanel. Use the publish and playback URLs shown in the panel. Build/publish the new RTMP latest image before running the updated installer.

RTMP basiert jetzt auf OpenRTMP. RTMPPanel läuft optional auf Port 8001. API-Token, Verschlüsselungs-Secret und Datenbanken bleiben für Updates erhalten. Beim Wechsel von nginx werden HTTP-Port und Datenvolume angepasst; bisherige Streams im Panel neu anlegen und die dort angezeigten URLs verwenden. Das neue RTMP-latest-Image muss vor der Installation veröffentlicht sein.
