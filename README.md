# Stream Relay Installer  
### WIP (Work in Progress)

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
- **SLS Management UI** - [AlexanderWagnerDev/slsmu-docker](https://github.com/AlexanderWagnerDev/slsmu-docker)

SRTLA and SLSMU is based on [OpenIRL](https://github.com/OpenIRL)

---

## Requirements

- Debian or Ubuntu system  
- Root or sudo access  
- Internet connection for downloading required packages  

---

## Installation

Run the following command to start the installation:
```bash
sudo curl -sSL https://install.stream-relay-installer.de | sh
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
- **SLS Management UI** - [AlexanderWagnerDev/slsmu-docker](https://github.com/AlexanderWagnerDev/slsmu-docker)

SRTLA und SLSMU basierend auf [OpenIRL](https://github.com/OpenIRL)

---

## Voraussetzungen

- Debian- oder Ubuntu-System  
- Root- oder sudo-Zugriff  
- Internetverbindung zum Herunterladen der erforderlichen Pakete  

---

## Installation

Führe den folgenden Befehl aus, um die Installation zu starten:
```bash
sudo curl -sSL https://install.stream-relay-installer.de | sh
```

Nach Abschluss des Skripts den Server neu starten, damit die Änderungen übernommen werden.

---

## Nutzung

Nach dem Neustart ist dein Stream-Relay-Server mit den Standardkonfigurationen einsatzbereit.

---

## License

MIT
