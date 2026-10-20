# Configuration / Konfiguration

Copy `.env.example` to `.env`, fill in the empty credentials, then run `docker compose config --quiet`.

| Variable | Meaning / Bedeutung | Default |
| --- | --- | --- |
| `LRTMP2_API_TOKEN` | Shared server and panel API token; 32–256 ASCII letters/digits, `-` or `_` | required |
| `SECRET_KEY` | Stable panel encryption/session secret; keep with panel database | required |
| `PANEL_PASSWORD` | Panel admin password / Admin-Passwort | required |
| `PANEL_USERNAME` | Panel admin username / Benutzername | admin |
| `REQUIRE_LOGIN` | Panel authentication / Anmeldung | True |
| `LRTMP2_DOMAIN` | Public domain/IP used in stream URLs / Öffentliche Domain/IP | localhost |
| `RTMP_PORT` | Published RTMP port / Host-Port RTMP | 1935 |
| `RTMP_API_PORT` | Published API port; internal API stays on 8080 / Host-Port API | 8090 |
| `RTMPPANEL_PORT` | Published panel port; internal panel stays on 8000 / Host-Port Panel | 8001 |
| `PANEL_LANG` | Interface language / Sprache | en |
| `TZ` | Container timezone / Zeitzone | UTC |
| `SESSION_COOKIE_SECURE` | Set True behind HTTPS / Bei HTTPS aktivieren | False |

Generate the API token and encryption secret separately using `openssl rand -hex 32`. Choose a strong panel password. `.env` is local configuration and must not be committed. `LRTMP2_API_TOKEN` seeds a **new** server database; an existing database keeps its stored token. Use that token for the panel instead of generating another one. Keep `SECRET_KEY` unchanged when reusing the panel database, or stored stream keys cannot be decrypted.

API-Token und Secret getrennt mit `openssl rand -hex 32` erzeugen. Ein starkes Passwort wählen. `.env` bleibt lokal. Eine bestehende Server-Datenbank behält ihren Token; diesen auch im Panel verwenden. Den `SECRET_KEY` bei bestehender Panel-Datenbank unverändert lassen, damit gespeicherte Stream-Keys entschlüsselt werden können.

## Storage and networking / Daten und Netzwerk

Compose uses project-prefixed named volumes for `/data`. Keep the project name stable (`docker compose -p NAME ...`) when updating. The shell installer uses volumes named `rtmp-server-data` and `rtmppanel-data` directly. Compose and the shell installer are separate deployment methods; do not run them over the same container names or switch without a data migration.

The server stack connects panel and backend through Docker DNS (`http://rtmp-server:8080`). The standalone panel uses `LRTMP2_API_URL` (default `http://host.docker.internal:8090`, Docker Engine 20.10+). For another host, set its reachable API URL. `localhost` inside the panel container refers to the panel itself.

Compose verwendet projektbezogene Volumes. Den Projektnamen bei Updates beibehalten. Shell-Installer und Compose sind getrennte Installationswege und verwenden unterschiedliche Volume-Namen; beim Wechsel Daten ausdrücklich migrieren. Im gemeinsamen Stack erreicht das Panel den Server über `rtmp-server:8080`; beim einzelnen Panel die vom Container erreichbare `LRTMP2_API_URL` setzen.

## Troubleshooting / Fehlerbehebung

- API errors: check `docker compose logs rtmp-server`, the API URL and shared token. Existing databases ignore a different token supplied through the environment.
- Panel refuses startup: configure a nonempty `SECRET_KEY`; verify `/data` is writable by the image's non-root user.
- Login: check `REQUIRE_LOGIN`, `PANEL_USERNAME`, `PANEL_PASSWORD` and HTTPS cookie settings.
- Existing host volume: back up first and make it writable for the image's `openrtmp` user. Do not make the database world-writable.
- Bei API-Fehlern URL, Token und Server-Logs prüfen; bei Login-Problemen Zugangsdaten und HTTPS-Cookies prüfen. Datenvolumes müssen für den Container-Benutzer schreibbar sein.

## Optional SRTLA / SLSPanel stack

The default Compose deployment starts RTMP and RTMPPanel. Add SRTLA using:

```bash
docker compose --profile srtla up -d srtla-server
docker compose logs srtla-server
# Copy the generated admin API key into SLS_API_KEY in .env.
docker compose --profile srtla up -d
```

SLSPanel uses host port 8000, SRTLA stats 8789, SRT publishing 4001/UDP, playback 4000/UDP and SRTLA 5000/UDP. Both panels use PANEL_USERNAME/PANEL_PASSWORD. WUD is available through the interactive installer; it is not part of this Compose stack.

Mit `--profile srtla` den SRTLA-Server zuerst starten, den generierten Admin-API-Key aus dessen Logs nach `SLS_API_KEY` übernehmen und danach den gesamten Stack starten. SLSPanel läuft auf Port 8000. WUD ist optional im interaktiven Installer enthalten. Die Compose-Volumes sind projektbezogen und unterscheiden sich von denen des Shell-Installers.

## Installer networking / Installer-Netzwerk

The shell installer creates the user-defined `openrtmp` network and connects RTMP server and panel to it. Panel API requests use `http://rtmp-server:8080`, independently of the public address and published host port. Browser stats links continue to use the public address. Container updates preserve all network memberships. RTMP services on host/none networks require explicit migration to the user-defined network before updating.

Der Installer verbindet RTMP-Server und Panel über das Docker-Netz `openrtmp`; API-Aufrufe bleiben bei `rtmp-server:8080`. Öffentliche Adresse und eigene Ports gelten weiterhin für Browser-Statistiklinks. Netzmitgliedschaften bleiben bei Updates erhalten. Host-/None-Netze vor dem Update ausdrücklich auf das gemeinsame Netz umstellen.

## Browser stats and worker settings / Browser-Statistiken und Worker

The panel's API URL stays internal (`http://rtmp-server:8080`). Set `LRTMP2_STATS_URL` to a browser-reachable backend URL, including a custom port. When left blank, the example uses localhost and `RTMP_API_PORT`; replace it with a public domain for remote viewers. API requests and browser stats URLs are independent.

The default `GUNICORN_WORKERS=1` works with `RATELIMIT_STORAGE_URI=memory://`. Multiple workers require a separately deployed shared session/rate-limit backend, for example Redis. To intentionally disable login, set both `REQUIRE_LOGIN=False` and `ALLOW_INSECURE_NO_LOGIN=1`; the default acknowledgement is 0.

Die API bleibt im Docker-Netz. `LRTMP2_STATS_URL` erhält die im Browser erreichbare Backend-Adresse einschließlich eines eigenen Ports. Leer verwendet das Beispiel localhost und `RTMP_API_PORT`; für entfernte Zuschauer eine öffentliche Domain eintragen. Ein Worker funktioniert mit `memory://`; mehrere Worker benötigen einen gemeinsamen Session-/Rate-Limit-Backend. Zum bewussten Abschalten der Anmeldung zusätzlich `ALLOW_INSECURE_NO_LOGIN=1` setzen.
