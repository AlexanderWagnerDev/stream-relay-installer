# Migration from nginx / Migration von nginx

1. Back up the old nginx configuration and existing volumes before recreating containers.
2. Change the HTTP mapping from `8090:80` to `8090:8080`, retaining any custom host port. RTMP remains on container port 1935.
3. Persist the OpenRTMP server database at `/data/server.db`. Persist the panel database under `/data`, and retain its stable `SECRET_KEY`.
4. Create streams in RTMPPanel. Arbitrary nginx `/publish/{key}` streams are not imported automatically. Use the distinct publish/playback URLs and stats keys returned by the panel.
5. Verify `curl -f http://localhost:8090/api/v1/health` and publishing/playback before switching clients.

Vor dem Wechsel nginx-Konfiguration und Volumes sichern. HTTP-Mapping auf Container-Port 8080 ändern, den bisherigen Host-Port beibehalten. Streams im RTMPPanel neu anlegen; bisherige nginx-Keys werden nicht automatisch importiert. Server- und Panel-Datenbanken sowie den festen `SECRET_KEY` aufbewahren. Anschließend Healthcheck, Senden und Wiedergabe prüfen.

`docker compose down` retains named volumes; `docker compose down -v` deletes databases. The installer update preserves the published HTTP port and adds a persistent database volume for legacy nginx containers. Keeping volumes during installer uninstall also keeps the RTMP API token and panel secret.

Do not run the Compose deployment alongside an existing shell-installer deployment with identical names/ports. Stop the previous deployment and migrate data explicitly. For Compose-to-Compose updates, retain the project name and `.env`.
