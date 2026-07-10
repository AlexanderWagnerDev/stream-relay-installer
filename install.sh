#!/bin/bash

set -e

RED="\033[0;31m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
NC="\033[0m"
HEADER="${YELLOW}"
SUCCESS="${GREEN}"
ERROR="${RED}"
INFO="${YELLOW}"

function print_ascii_art_de() {
  cat <<"EOF"
  ____  _                              ____      _               ___           _        _ _
 / ___|| |_ _ __ ___  __ _ _ __ ___   |  _ \  ___| | __ _ _   _  |_ _|_ __  ___| |_ __ _| | | ___ _ __
 \___ \| __| '__/ _ \/ _` | '_ ` _ \  | |_) / _ \ |/ _` | | | |  | || '_ \/ __| __/ _` | | |/ _ \ '__|
  ___) | |_| | |  __/ (_| | | | | | | |  _ <  __/ | (_| | |_| |  | || | | \__ \ || (_| | | |  __/ |
 |____/ \__|_|  \___|\__,_|_| |_| |_| |_| \_\___|_|\__,_|\__, | |___|_| |_|___/\__\__,_|_|_|\___|_|
                                                         |___/
           von AlexanderWagnerDev
EOF
}

function print_ascii_art_en() {
  cat <<"EOF"
  ____  _                              ____      _               ___           _        _ _
 / ___|| |_ _ __ ___  __ _ _ __ ___   |  _ \  ___| | __ _ _   _  |_ _|_ __  ___| |_ __ _| | | ___ _ __
 \___ \| __| '__/ _ \/ _` | '_ ` _ \  | |_) / _ \ |/ _` | | | |  | || '_ \/ __| __/ _` | | |/ _ \ '__|
  ___) | |_| | |  __/ (_| | | | | | | |  _ <  __/ | (_| | |_| |  | || | | \__ \ || (_| | | |  __/ |
 |____/ \__|_|  \___|\__,_|_| |_| |_| |_| \_\___|_|\__,_|\__, | |___|_| |_|___/\__\__,_|_|_|\___|_|
                                                         |___/
           by AlexanderWagnerDev
EOF
}

function system_update_prompt() {
  export DEBIAN_FRONTEND=noninteractive
  export APT_LISTCHANGES_FRONTEND=none
  export LC_ALL=C
  if [[ "$lang" == "de" ]]; then
    read -rp $'\033[1;33mSoll das System jetzt aktualisiert werden? (j/n): \033[0m' sys_update
    if [[ "$sys_update" =~ ^[JjYy] ]]; then
      echo -e "${INFO}System wird aktualisiert...${NC}"
      sudo apt-get update
      sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
      echo -e "${SUCCESS}Systemaktualisierung abgeschlossen.${NC}"
      echo -e "${YELLOW}Ein Neustart wird empfohlen, um Kernel-Updates zu aktivieren.${NC}"
      sleep 3
    else
      echo -e "${INFO}Systemaktualisierung übersprungen.${NC}"
    fi
  else
    read -rp $'\033[1;33mDo you want to update the system now? (y/n): \033[0m' sys_update
    if [[ "$sys_update" =~ ^[Yy] ]]; then
      echo -e "${INFO}Updating system...${NC}"
      sudo apt-get update
      sudo apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade
      echo -e "${SUCCESS}System update complete.${NC}"
      echo -e "${YELLOW}A system reboot is recommended to activate kernel updates.${NC}"
      sleep 3
    else
      echo -e "${INFO}System update skipped.${NC}"
    fi
  fi
}

function install_docker_debian_ubuntu() {
  if [[ "$lang" == "de" ]]; then
    echo -e "${INFO}Installation von Docker über das offizielle get.docker.com Script...${NC}"
  else
    echo -e "${INFO}Installing Docker via official get.docker.com script...${NC}"
  fi

  curl -fsSL https://get.docker.com | sh

  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$USER"

  if [[ "$lang" == "de" ]]; then
    echo -e "${SUCCESS}Docker wurde erfolgreich installiert und gestartet.${NC}"
  else
    echo -e "${SUCCESS}Docker has been successfully installed and started.${NC}"
  fi
}

function read_port () {
  local prompt="$1"
  local default_port="$2"
  local response
  echo -n "$prompt [$default_port]: "
  read -r response
  if [[ -z "$response" ]]; then
    response=$default_port
  fi
  echo "$response"
}

function get_public_ip() {
  if [[ -n "$MANUAL_IP" ]]; then
    echo "$MANUAL_IP"
    return
  fi
  local ip=""
  ip=$(curl -fs4 https://ipinfo.io/ip 2>/dev/null || echo "")
  if [[ -z "$ip" ]]; then
    ip=$(curl -fs4 https://api.ipify.org 2>/dev/null || echo "")
  fi
  if [[ -z "$ip" ]]; then
    ip=$(curl -fs4 https://ifconfig.me/ip 2>/dev/null || echo "")
  fi
  if [[ -z "$ip" ]]; then
    ip="127.0.0.1"
  fi
  echo "$ip"
}

function docker_pull_fallback() {
  local image="$1"
  local fallback_image="$2"
  if ! docker pull "$image" 2>/dev/null; then
    if [[ "$lang" == "de" ]]; then
      echo -e "${YELLOW}Warnung: Image '$image' nicht von Docker Hub gefunden, versuche Fallback GHCR...${NC}"
    else
      echo -e "${YELLOW}Warning: Image '$image' not found on Docker Hub, trying fallback GHCR...${NC}"
    fi
    if ! docker pull "$fallback_image" 2>/dev/null; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${RED}Fehler: Image konnte weder von Docker Hub noch GHCR gezogen werden: $image / $fallback_image${NC}"
        echo -e "${RED}Das Script wird abgebrochen. Bitte Internetverbindung und Image-Namen prüfen.${NC}"
      else
        echo -e "${RED}Error: Image could not be pulled from Docker Hub nor GHCR: $image / $fallback_image${NC}"
        echo -e "${RED}Aborting script. Please check your internet connection and image names.${NC}"
      fi
      exit 1
    fi
  fi
}

function extract_api_key() {
  local apikey=""
  apikey=$(docker logs srtla-server 2>/dev/null | grep "Generated default admin API key:" | sed 's/.*Generated default admin API key: \([A-Za-z0-9]*\).*/\1/' | tail -1)
  echo "$apikey"
}

function extract_api_key_with_retry() {
  local max_attempts=5
  local wait_seconds=5
  local attempt=1
  local apikey=""

  while [[ $attempt -le $max_attempts ]]; do
    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}Versuche API-Key zu extrahieren (Versuch $attempt/$max_attempts)...${NC}" >&2
    else
      echo -e "${INFO}Trying to extract API key (attempt $attempt/$max_attempts)...${NC}" >&2
    fi
    apikey=$(extract_api_key)
    if [[ -n "$apikey" ]]; then
      echo "$apikey"
      return 0
    fi
    if [[ $attempt -lt $max_attempts ]]; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${INFO}API-Key noch nicht verfügbar, warte ${wait_seconds}s...${NC}" >&2
      else
        echo -e "${INFO}API key not yet available, waiting ${wait_seconds}s...${NC}" >&2
      fi
      sleep "$wait_seconds"
    fi
    attempt=$((attempt + 1))
  done

  echo ""
  return 1
}

function extract_rtmp_api_token() {
  local token=""
  token=$(docker logs rtmp-server 2>/dev/null | grep -A1 "Generated API token" | tail -1 | tr -d '[:space:]')
  echo "$token"
}

function extract_rtmp_api_token_with_retry() {
  local max_attempts=5
  local wait_seconds=5
  local attempt=1
  local token=""

  while [[ $attempt -le $max_attempts ]]; do
    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}Versuche RTMP API-Token zu extrahieren (Versuch $attempt/$max_attempts)...${NC}" >&2
    else
      echo -e "${INFO}Trying to extract RTMP API token (attempt $attempt/$max_attempts)...${NC}" >&2
    fi
    token=$(extract_rtmp_api_token)
    if [[ -n "$token" ]]; then
      echo "$token"
      return 0
    fi
    if [[ $attempt -lt $max_attempts ]]; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${INFO}RTMP API-Token noch nicht verfügbar, warte ${wait_seconds}s...${NC}" >&2
      else
        echo -e "${INFO}RTMP API token not yet available, waiting ${wait_seconds}s...${NC}" >&2
      fi
      sleep "$wait_seconds"
    fi
    attempt=$((attempt + 1))
  done

  echo ""
  return 1
}

function get_or_create_rtmppanel_secret() {
  if [ -f ".rtmppanel_secret" ]; then
    cat .rtmppanel_secret
    return
  fi
  local secret=""
  secret=$(openssl rand -hex 32 2>/dev/null || python3 -c 'import secrets; print(secrets.token_hex(32))' 2>/dev/null)
  echo "$secret" > .rtmppanel_secret
  chmod 600 .rtmppanel_secret
  echo "$secret"
}

function print_available_services() {
  local app_url="$1"
  local management_port="$2"
  local apikey="$3"
  local p_public_ip="$4"
  local p_srtla_port="$5"
  local p_srt_sender_port="$6"
  local p_srt_player_port="$7"
  local p_sls_stats_port="$8"
  local p_rtmp_stats_port="$9"
  local p_rtmp_port="${10}"
  local p_rtmppanel_port="${11}"
  if [[ "$lang" == "de" ]]; then
    echo -e "${HEADER}Verfügbare Dienste:${NC}"
    echo -e "${SUCCESS}SLSPanel UI: http://${p_public_ip}:${management_port}${NC}"
    echo -e "${SUCCESS}API Key: ${apikey}${NC}"
    echo -e "${SUCCESS}Backend API: ${app_url}${NC}"
    echo -e "${SUCCESS}SRTLA Sender URL ZUM SENDEN (Beispiel): srtla://${p_public_ip}:${p_srtla_port}?streamid=livekey${NC}"
    echo -e "${SUCCESS}SRT Sender URL ZUM SENDEN (Beispiel): srt://${p_public_ip}:${p_srt_sender_port}?streamid=livekey${NC}"
    echo -e "${SUCCESS}SRT Player URL ZUM EMPFANGEN (Beispiel): srt://${p_public_ip}:${p_srt_player_port}?streamid=playkey${NC}"
    echo -e "${SUCCESS}SRT/SRTLA Statistiken URL (Beispiel): http://${p_public_ip}:${p_sls_stats_port}/stats/playkey${NC}"
    echo -e "${SUCCESS}RTMP Statistiken/API URL: http://${p_public_ip}:${p_rtmp_stats_port}/api/v1/health${NC}"
    echo -e "${SUCCESS}RTMP URL ZUM SENDEN UND EMPFANGEN (Beispiel): rtmp://${p_public_ip}:${p_rtmp_port}/live/DEIN_PUBLISH_KEY${NC}"
    if [[ -n "$p_rtmppanel_port" ]]; then
      echo -e "${SUCCESS}RTMPPanel UI: http://${p_public_ip}:${p_rtmppanel_port}${NC}"
    fi
  else
    echo -e "${HEADER}Available services:${NC}"
    echo -e "${SUCCESS}SLSPanel UI: http://${p_public_ip}:${management_port}${NC}"
    echo -e "${SUCCESS}API Key: ${apikey}${NC}"
    echo -e "${SUCCESS}Backend API: ${app_url}${NC}"
    echo -e "${SUCCESS}SRTLA Sender URL TO SEND (Example): srtla://${p_public_ip}:${p_srtla_port}?streamid=livekey${NC}"
    echo -e "${SUCCESS}SRT Sender URL TO SEND (Example): srt://${p_public_ip}:${p_srt_sender_port}?streamid=livekey${NC}"
    echo -e "${SUCCESS}SRT Player URL TO RECEIVE (Example): srt://${p_public_ip}:${p_srt_player_port}?streamid=playkey${NC}"
    echo -e "${SUCCESS}SRT/SRTLA Statistics URL (Example): http://${p_public_ip}:${p_sls_stats_port}/stats/playkey${NC}"
    echo -e "${SUCCESS}RTMP Stats/API URL: http://${p_public_ip}:${p_rtmp_stats_port}/api/v1/health${NC}"
    echo -e "${SUCCESS}RTMP URL FOR SENDING AND RECEIVING (Example): rtmp://${p_public_ip}:${p_rtmp_port}/live/YOUR_PUBLISH_KEY${NC}"
    if [[ -n "$p_rtmppanel_port" ]]; then
      echo -e "${SUCCESS}RTMPPanel UI: http://${p_public_ip}:${p_rtmppanel_port}${NC}"
    fi
  fi
}

function print_help() {
  if [[ "$lang" == "de" ]]; then
    echo -e "${HEADER}Hilfe:${NC}
  Mit diesem Script kannst du die Installation, das Starten, Stoppen, Aktualisieren oder das Entfernen der Stream-Services ausführen.
  ${GREEN}Funktionen:${NC}
  [installieren]    Installation durchführen
  [starten]         Container starten
  [stoppen]         Container stoppen
  [aktualisieren]   Container und Images aktualisieren
  [deinstallieren]  Container/Images/optional Volumes entfernen
  [hilfe]           Diese Hilfe anzeigen"
  else
    echo -e "${HEADER}Help:${NC}
  This script lets you install, start, stop, update or uninstall the stream services interactively.
  ${GREEN}Functions:${NC}
  [install]     Run installation
  [start]       Start containers
  [stop]        Stop containers
  [update]      Update containers and images
  [uninstall]   Remove containers/images/optional volumes
  [help]        Show this help"
  fi
}

function health_check() {
  local cname="$1"
  local running
  running=$(docker inspect -f '{{.State.Running}}' "$cname" 2>/dev/null || echo "false")
  if [[ "$running" == "true" ]]; then
    local health
    health=$(docker inspect --format='{{.State.Health.Status}}' "$cname" 2>/dev/null || echo "")
    if [[ "$health" == "healthy" ]]; then
      [[ "$lang" == "de" ]] && echo -e "${SUCCESS}Container $cname ist gesund.${NC}" || echo -e "${SUCCESS}Container $cname is healthy.${NC}"
    elif [[ -z "$health" ]]; then
      [[ "$lang" == "de" ]] && echo -e "${SUCCESS}Container $cname läuft (kein Healthcheck definiert).${NC}" || echo -e "${SUCCESS}Container $cname is running (no healthcheck defined).${NC}"
    else
      [[ "$lang" == "de" ]] && echo -e "${ERROR}Container $cname ist nicht gesund! Status: $health${NC}" || echo -e "${ERROR}Container $cname is not healthy! Status: $health${NC}"
    fi
  else
    [[ "$lang" == "de" ]] && echo -e "${ERROR}Container $cname läuft NICHT!${NC}" || echo -e "${ERROR}Container $cname is NOT running!${NC}"
  fi
}

function stop_services() {
  for cname in rtmp-server srtla-server slspanel rtmppanel wud; do
    if docker ps --format '{{.Names}}' | grep -q "^$cname$"; then
      docker stop "$cname" || true
      [[ "$lang" == "de" ]] && echo -e "${INFO}Container $cname gestoppt.${NC}" || echo -e "${INFO}Stopped container $cname.${NC}"
    fi
  done
}

function start_services() {
  for cname in rtmp-server srtla-server slspanel rtmppanel wud; do
    docker start "$cname" 2>/dev/null || true
    health_check "$cname"
  done
}

function recreate_container() {
  local cname="$1"
  local image="$2"
  local fallback_image="$3"

  if ! docker ps -a --format '{{.Names}}' | grep -q "^$cname$"; then
    [[ "$lang" == "de" ]] && echo -e "${INFO}Container $cname existiert nicht, überspringe...${NC}" || echo -e "${INFO}Container $cname does not exist, skipping...${NC}"
    return 0
  fi

  [[ "$lang" == "de" ]] && echo -e "${INFO}Aktualisiere Container: $cname${NC}" || echo -e "${INFO}Updating container: $cname${NC}"

  local restart_policy
  restart_policy=$(docker inspect "$cname" --format '{{.HostConfig.RestartPolicy.Name}}' 2>/dev/null || echo "")

  local -a run_args=()

  while IFS= read -r port_entry; do
    [[ -n "$port_entry" ]] && run_args+=(-p "$port_entry")
  done < <(docker inspect "$cname" --format \
    '{{range $p, $confs := .HostConfig.PortBindings}}{{range $confs}}{{.HostPort}}:{{$p}} {{end}}{{end}}' \
    2>/dev/null | tr ' ' '\n' | grep -v '^$')

  while IFS= read -r env_entry; do
    if [[ -n "$env_entry" && "$env_entry" != PATH=* && "$env_entry" != HOME=* ]]; then
      run_args+=(-e "$env_entry")
    fi
  done < <(docker inspect "$cname" --format \
    '{{range .Config.Env}}{{println .}}{{end}}' 2>/dev/null)

  if [[ "$cname" == "srtla-server" ]]; then
    local volume_data_path="/var/lib/docker/volumes/srtla-server/_data"
    sudo chown -R 3001:3001 "$volume_data_path" 2>/dev/null || true
    sudo chmod -R 755 "$volume_data_path" 2>/dev/null || true
    run_args+=(-v "${volume_data_path}:/var/lib/sls")
  else
    while IFS= read -r vol_entry; do
      [[ -n "$vol_entry" ]] && run_args+=(-v "$vol_entry")
    done < <(docker inspect "$cname" --format \
      '{{range .Mounts}}{{.Source}}:{{.Destination}} {{end}}' \
      2>/dev/null | tr ' ' '\n' | grep -v '^$')
  fi

  while IFS= read -r label_entry; do
    if [[ -n "$label_entry" && "$label_entry" == wud.* ]]; then
      run_args+=(--label "$label_entry")
    fi
  done < <(docker inspect "$cname" --format \
    '{{range $k, $v := .Config.Labels}}{{$k}}={{$v}} {{end}}' \
    2>/dev/null | tr ' ' '\n' | grep -v '^$')

  docker stop "$cname" 2>/dev/null || true
  docker rm "$cname" 2>/dev/null || true

  [[ "$lang" == "de" ]] && echo -e "${INFO}Entferne alte Images...${NC}" || echo -e "${INFO}Removing old images...${NC}"
  docker rmi -f "$image" 2>/dev/null || true
  docker rmi -f "$fallback_image" 2>/dev/null || true
  local image_base
  image_base=$(echo "$image" | cut -d':' -f1)
  docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${image_base}:" | xargs -r docker rmi -f 2>/dev/null || true
  local fallback_base
  fallback_base=$(echo "$fallback_image" | cut -d':' -f1)
  docker images --format "{{.Repository}}:{{.Tag}}" | grep "^${fallback_base}:" | xargs -r docker rmi -f 2>/dev/null || true

  docker_pull_fallback "$image" "$fallback_image"

  local restart_flag=""
  if [[ "$restart_policy" == "unless-stopped" ]]; then
    restart_flag="--restart unless-stopped"
  elif [[ "$restart_policy" == "always" ]]; then
    restart_flag="--restart always"
  fi

  # shellcheck disable=SC2086
  if ! docker run -d --name "$cname" $restart_flag "${run_args[@]}" "$image"; then
    [[ "$lang" == "de" ]] && echo -e "${ERROR}Container $cname konnte nicht gestartet werden.${NC}" || echo -e "${ERROR}Failed to start container $cname.${NC}"
    return 1
  fi

  [[ "$lang" == "de" ]] && echo -e "${SUCCESS}Container $cname wurde neu erstellt.${NC}" || echo -e "${SUCCESS}Container $cname has been recreated.${NC}"

  sleep 3
  if [[ "$cname" != "wud" ]]; then
    health_check "$cname"
  else
    local running
    running=$(docker inspect -f '{{.State.Running}}' "$cname" 2>/dev/null || echo "false")
    if [[ "$running" == "true" ]]; then
      [[ "$lang" == "de" ]] && echo -e "${SUCCESS}Container $cname läuft.${NC}" || echo -e "${SUCCESS}Container $cname is running.${NC}"
    else
      [[ "$lang" == "de" ]] && echo -e "${ERROR}Container $cname läuft NICHT!${NC}" || echo -e "${ERROR}Container $cname is NOT running!${NC}"
    fi
  fi
}

function update_services() {
  [[ "$lang" == "de" ]] && echo -e "${HEADER}=== Container-Update wird gestartet ===${NC}" || echo -e "${HEADER}=== Starting container update ===${NC}"

  local containers=("rtmp-server" "srtla-server" "slspanel" "rtmppanel" "wud")
  local images=("alexanderwagnerdev/rtmp-server:beta" "alexanderwagnerdev/srtla-server:beta" "alexanderwagnerdev/slspanel:beta" "alexanderwagnerdev/rtmppanel:beta" "getwud/wud:latest")
  local fallback_images=("ghcr.io/alexanderwagnerdev/rtmp-server:beta" "ghcr.io/alexanderwagnerdev/srtla-server:beta" "ghcr.io/alexanderwagnerdev/slspanel:beta" "ghcr.io/alexanderwagnerdev/rtmppanel:beta" "ghcr.io/getwud/wud:latest")

  for i in "${!containers[@]}"; do
    recreate_container "${containers[$i]}" "${images[$i]}" "${fallback_images[$i]}"
  done

  [[ "$lang" == "de" ]] && echo -e "${SUCCESS}=== Container-Update abgeschlossen ===${NC}" || echo -e "${SUCCESS}=== Container update completed ===${NC}"

  if docker ps -a --format '{{.Names}}' | grep -q "^srtla-server$"; then
    local apikey
    apikey=$(cat .apikey 2>/dev/null || echo "")
    if [[ -z "$apikey" ]]; then
      [[ "$lang" == "de" ]] && echo -e "${INFO}Versuche API-Key neu zu extrahieren...${NC}" || echo -e "${INFO}Trying to re-extract API key...${NC}"
      apikey=$(extract_api_key_with_retry)
      if [[ -n "$apikey" ]]; then
        echo "$apikey" > .apikey
        [[ "$lang" == "de" ]] && echo -e "${SUCCESS}API-Key erfolgreich extrahiert.${NC}" || echo -e "${SUCCESS}API key successfully extracted.${NC}"
      fi
    fi
  fi

  if docker ps -a --format '{{.Names}}' | grep -q "^rtmp-server$"; then
    local rtmp_token
    rtmp_token=$(cat .rtmp_api_token 2>/dev/null || echo "")
    if [[ -z "$rtmp_token" ]]; then
      [[ "$lang" == "de" ]] && echo -e "${INFO}Versuche RTMP API-Token neu zu extrahieren...${NC}" || echo -e "${INFO}Trying to re-extract RTMP API token...${NC}"
      rtmp_token=$(extract_rtmp_api_token_with_retry)
      if [[ -n "$rtmp_token" ]]; then
        echo "$rtmp_token" > .rtmp_api_token
        [[ "$lang" == "de" ]] && echo -e "${SUCCESS}RTMP API-Token erfolgreich extrahiert.${NC}" || echo -e "${SUCCESS}RTMP API token successfully extracted.${NC}"
      fi
    fi
  fi
}

function uninstall_services() {
  for cname in rtmp-server srtla-server slspanel rtmppanel wud; do
    if docker ps -a --format '{{.Names}}' | grep -q "^$cname$"; then
      docker rm -f "$cname" || true
      [[ "$lang" == "de" ]] && echo -e "${INFO}Container $cname entfernt.${NC}" || echo -e "${INFO}Removed container $cname.${NC}"
    fi
  done
  for img in alexanderwagnerdev/rtmp-server alexanderwagnerdev/srtla-server alexanderwagnerdev/slspanel alexanderwagnerdev/rtmppanel getwud/wud; do
    docker rmi -f "$img" 2>/dev/null || true
    docker rmi -f "ghcr.io/$img" 2>/dev/null || true
  done

  if [ -f ".apikey" ]; then
    rm -f ".apikey"
    if [[ "$lang" == "de" ]]; then
      echo -e "${SUCCESS}API-Key Datei (.apikey) gelöscht.${NC}"
    else
      echo -e "${SUCCESS}API key file (.apikey) deleted.${NC}"
    fi
  fi

  if [ -f ".rtmp_api_token" ]; then
    rm -f ".rtmp_api_token"
    if [[ "$lang" == "de" ]]; then
      echo -e "${SUCCESS}RTMP API-Token Datei (.rtmp_api_token) gelöscht.${NC}"
    else
      echo -e "${SUCCESS}RTMP API token file (.rtmp_api_token) deleted.${NC}"
    fi
  fi

  if [[ "$lang" == "de" ]]; then
    read -rp $'\033[1;33mSollen auch Volumes gelöscht werden? (j/n):\033[0m ' rmvol
    if [[ "$rmvol" =~ ^[Jj] ]]; then
      docker volume rm srtla-server 2>/dev/null || true
      docker volume rm rtmp-server-data 2>/dev/null || true
      docker volume rm rtmppanel-data 2>/dev/null || true
      rm -f ".rtmppanel_secret"
      echo -e "${SUCCESS}Docker-Volumes (srtla-server, rtmp-server-data, rtmppanel-data) entfernt.${NC}"
    else
      echo -e "${INFO}Volumes bleiben erhalten.${NC}"
    fi
    echo -e "${SUCCESS}Alle Container und Images entfernt.${NC}"
  else
    read -rp $'\033[1;33mShould volumes be deleted as well? (y/n):\033[0m ' rmvol
    if [[ "$rmvol" =~ ^[Yy] ]]; then
      docker volume rm srtla-server 2>/dev/null || true
      docker volume rm rtmp-server-data 2>/dev/null || true
      docker volume rm rtmppanel-data 2>/dev/null || true
      rm -f ".rtmppanel_secret"
      echo -e "${SUCCESS}Docker volumes (srtla-server, rtmp-server-data, rtmppanel-data) removed.${NC}"
    else
      echo -e "${INFO}Volumes are kept.${NC}"
    fi
    echo -e "${SUCCESS}All containers and images removed.${NC}"
  fi
}

echo "Wähle Sprache / Choose language:"
echo "[1] Deutsch"
echo "[2] English"
read -rp "Auswahl / Choice [1]: " lang_choice
lang_choice=${lang_choice:-1}
if [[ "$lang_choice" == "1" ]]; then
  lang="de"
  print_ascii_art_de
elif [[ "$lang_choice" == "2" ]]; then
  lang="en"
  print_ascii_art_en
else
  lang="de"
  print_ascii_art_de
fi

if [[ "$lang" == "de" ]]; then
  docker_prompt="Docker installieren? (j/n):"
  rtmp_prompt="RTMP-Server Docker Container installieren und starten? (j/n):"
  srtla_prompt="SRTLA-Server Docker Container installieren und starten? (j/n):"
  wud_prompt="WUD Container (automatische Updates) installieren und starten? (j/n):"
  wud_labels_prompt="Sollen die Container (RTMP, SRTLA, SLSPanel, RTMPPanel) von WUD überwacht werden? (j/n):"
  ipv6_prompt="Docker IPv6 Unterstützung aktivieren? (j/n):"
  use_default_ports_prompt="Standardports verwenden? (j/n):"
  manual_ip_prompt="Möchtest du eine Domain oder IP manuell eingeben? (j/n):"
  enter_ip_prompt="Bitte Domain oder IP eingeben:"
  slspanel_install_prompt="SLSPanel installieren und starten? (j/n): "
  slspanel_login_prompt="Login für SLSPanel aktivieren? (j/n): "
  slspanel_username_prompt="Benutzername für SLSPanel Admin: "
  slspanel_password_prompt="Passwort für SLSPanel Admin: "
  rtmppanel_install_prompt="RTMPPanel installieren und starten? (j/n): "
  rtmppanel_login_prompt="Login für RTMPPanel aktivieren? (j/n): "
  rtmppanel_username_prompt="Benutzername für RTMPPanel Admin: "
  rtmppanel_password_prompt="Passwort für RTMPPanel Admin: "
  done_msg="Setup abgeschlossen."
  docker_install_msg="Docker Installation wird gestartet..."
  docker_skip_msg="Docker wird nicht installiert."
  rtmp_install_msg="Starte RTMP-Server Docker-Container..."
  rtmp_skip_msg="RTMP-Server wird nicht installiert."
  srtla_install_msg="Starte SRTLA-Server Docker-Container..."
  srtla_skip_msg="SRTLA-Server wird nicht installiert."
  wud_install_msg="Starte WUD Docker-Container..."
  wud_skip_msg="WUD wird nicht installiert."
  rtmppanel_install_msg="Starte RTMPPanel Docker-Container..."
  rtmppanel_skip_msg="RTMPPanel wird nicht installiert."
  ipv6_enable_msg="Docker IPv6 Unterstützung wird aktiviert..."
  ipv6_skip_msg="Docker IPv6 Unterstützung wird nicht aktiviert."
  restart_msg="${YELLOW}Bitte beachten: Nach Docker-Installation ist evtl. ein Neustart oder eine neue Anmeldung nötig, damit Docker-Gruppenrechte aktiv werden.${NC}"
  port_prompts=(
    "Port für SRT-Player (Standard: 4000)"
    "Port für SRT-Sender (Standard: 4001)"
    "Port für SRTLA (Standard: 5000)"
    "Port für SLS Stats (Standard: 8789)"
    "Port für RTMP-Server Stats/API (Standard: 8090)"
    "Port für RTMP (Standard: 1935)"
    "Port für SLSPanel WebUI (Standard: 8000)"
    "Port für RTMPPanel WebUI (Standard: 8001)"
  )
else
  docker_prompt="Install Docker? (y/n):"
  rtmp_prompt="Install and start RTMP Server Docker container? (y/n):"
  srtla_prompt="Install and start SRTLA Server Docker container? (y/n):"
  wud_prompt="Install and start WUD container (automatic updates)? (y/n):"
  wud_labels_prompt="Should the containers (RTMP, SRTLA, SLSPanel, RTMPPanel) be monitored by WUD? (y/n):"
  ipv6_prompt="Enable Docker IPv6 support? (y/n):"
  use_default_ports_prompt="Use default ports? (y/n):"
  manual_ip_prompt="Do you want to enter a domain or IP manually? (y/n):"
  enter_ip_prompt="Please enter the domain or IP:"
  slspanel_install_prompt="Install and start SLSPanel? (y/n): "
  slspanel_login_prompt="Enable login for SLSPanel? (y/n): "
  slspanel_username_prompt="Username for SLSPanel admin: "
  slspanel_password_prompt="Password for SLSPanel admin: "
  rtmppanel_install_prompt="Install and start RTMPPanel? (y/n): "
  rtmppanel_login_prompt="Enable login for RTMPPanel? (y/n): "
  rtmppanel_username_prompt="Username for RTMPPanel admin: "
  rtmppanel_password_prompt="Password for RTMPPanel admin: "
  done_msg="Setup completed."
  docker_install_msg="Starting Docker installation..."
  docker_skip_msg="Skipping Docker installation."
  rtmp_install_msg="Starting RTMP Server Docker container..."
  rtmp_skip_msg="Skipping RTMP Server installation."
  srtla_install_msg="Starting SRTLA Server Docker container..."
  srtla_skip_msg="Skipping SRTLA Server installation."
  wud_install_msg="Starting WUD Docker container..."
  wud_skip_msg="Skipping WUD installation."
  rtmppanel_install_msg="Starting RTMPPanel Docker container..."
  rtmppanel_skip_msg="Skipping RTMPPanel installation."
  ipv6_enable_msg="Enabling Docker IPv6 support..."
  ipv6_skip_msg="Not enabling Docker IPv6 support."
  restart_msg="${YELLOW}Please note: After Docker installation a reboot or re-login might be necessary to activate Docker group permissions.${NC}"
  port_prompts=(
    "Port for SRT Player (default: 4000)"
    "Port for SRT Sender (default: 4001)"
    "Port for SRTLA (default: 5000)"
    "Port for SLS Stats (default: 8789)"
    "Port for RTMP Server Stats/API (default: 8090)"
    "Port for RTMP (default: 1935)"
    "Port for SLSPanel WebUI (default: 8000)"
    "Port for RTMPPanel WebUI (default: 8001)"
  )
fi

if [[ "$lang" == "de" ]]; then
  echo -e "${YELLOW}Was möchtest du tun?${NC}"
  echo " [1] Installieren"
  echo " [2] Starten"
  echo " [3] Stoppen"
  echo " [4] Aktualisieren"
  echo " [5] Deinstallieren"
  echo " [6] Hilfe"
  read -rp "Auswahl [1]: " mainaction
else
  echo -e "${YELLOW}What do you want to do?${NC}"
  echo " [1] Install"
  echo " [2] Start"
  echo " [3] Stop"
  echo " [4] Update"
  echo " [5] Uninstall"
  echo " [6] Help"
  read -rp "Choice [1]: " mainaction
fi
mainaction=${mainaction:-1}

if [[ "$mainaction" == "6" ]]; then
  print_help
  exit 0
elif [[ "$mainaction" == "2" ]]; then
  start_services
  exit 0
elif [[ "$mainaction" == "3" ]]; then
  stop_services
  exit 0
elif [[ "$mainaction" == "4" ]]; then
  update_services
  exit 0
elif [[ "$mainaction" == "5" ]]; then
  uninstall_services
  exit 0
fi

if [[ "$mainaction" == "1" ]]; then

  system_update_prompt

  read -rp "$docker_prompt " install_docker
  install_docker=${install_docker:-n}
  if [[ "$install_docker" =~ ^[JjYy] ]]; then
    echo -e "$docker_install_msg"
    install_docker_debian_ubuntu
  else
    echo -e "$docker_skip_msg"
  fi

  read -rp "$ipv6_prompt " enable_ipv6
  enable_ipv6=${enable_ipv6:-n}
  if [[ "$enable_ipv6" =~ ^[JjYy] ]]; then
    echo -e "$ipv6_enable_msg"
    if [[ -f /etc/docker/daemon.json ]]; then
      sudo cp /etc/docker/daemon.json "/etc/docker/daemon.json.bak_$(date +%s)"
      if grep -q '"ipv6"' /etc/docker/daemon.json; then
        sudo sed -i 's/"ipv6"\s*:\s*false/"ipv6": true/g' /etc/docker/daemon.json
      else
        sudo sed -i 's/}[[:space:]]*$/,\n  "ipv6": true\n}/' /etc/docker/daemon.json
      fi
    else
      echo '{ "ipv6": true }' | sudo tee /etc/docker/daemon.json > /dev/null
    fi
    sudo systemctl restart docker
  else
    echo -e "$ipv6_skip_msg"
  fi

  read -rp "$use_default_ports_prompt " use_default_ports
  use_default_ports=${use_default_ports:-y}
  if [[ "$use_default_ports" =~ ^[JjYy] ]]; then
    srt_player_port=4000
    srt_sender_port=4001
    srtla_port=5000
    sls_stats_port=8789
    rtmp_stats_port=8090
    rtmp_port=1935
    slspanel_port=8000
    rtmppanel_port=8001
  else
    srt_player_port=$(read_port "${port_prompts[0]}" 4000)
    srt_sender_port=$(read_port "${port_prompts[1]}" 4001)
    srtla_port=$(read_port "${port_prompts[2]}" 5000)
    sls_stats_port=$(read_port "${port_prompts[3]}" 8789)
    rtmp_stats_port=$(read_port "${port_prompts[4]}" 8090)
    rtmp_port=$(read_port "${port_prompts[5]}" 1935)
    slspanel_port=$(read_port "${port_prompts[6]}" 8000)
    rtmppanel_port=$(read_port "${port_prompts[7]}" 8001)
  fi

  MANUAL_IP=""
  public_ip=$(get_public_ip)

  read -rp "$manual_ip_prompt " manual_ip_choice
  manual_ip_choice=${manual_ip_choice:-n}

  if [[ "$manual_ip_choice" =~ ^[JjYy] ]]; then
    read -rp "$enter_ip_prompt " custom_ip
    MANUAL_IP="$custom_ip"
    public_ip="$custom_ip"
  fi

  if [[ "$public_ip" == "127.0.0.1" ]]; then
    if [[ "$lang" == "de" ]]; then
      echo -e "${YELLOW}Warnung: Öffentliche IP konnte nicht ermittelt werden, localhost wird als APP_URL benutzt.${NC}"
    else
      echo -e "${YELLOW}Warning: Public IP could not be determined, localhost will be used as APP_URL.${NC}"
    fi
  fi

  app_url="http://${public_ip}:${sls_stats_port}"

  read -rp "$wud_prompt " install_wud
  install_wud=${install_wud:-n}

  use_wud_labels="n"
  if [[ "$install_wud" =~ ^[JjYy] ]]; then
    read -rp "$wud_labels_prompt " use_wud_labels
    use_wud_labels=${use_wud_labels:-n}
  fi

  read -rp "$rtmp_prompt " install_rtmp
  install_rtmp=${install_rtmp:-n}
  if [[ "$install_rtmp" =~ ^[JjYy] ]]; then
    echo -e "$rtmp_install_msg"
    docker_pull_fallback "alexanderwagnerdev/rtmp-server:beta" "ghcr.io/alexanderwagnerdev/rtmp-server:beta"

    if [[ "$use_wud_labels" =~ ^[JjYy] ]]; then
      docker run -d --name rtmp-server --restart unless-stopped \
        --label "wud.watch=true" \
        --label "wud.watch.digest=true" \
        --label "wud.tag.include=^beta$" \
        -v rtmp-server-data:/data \
        -p "${rtmp_stats_port}":8080/tcp -p "${rtmp_port}":1935/tcp \
        alexanderwagnerdev/rtmp-server:beta
    else
      docker run -d --name rtmp-server --restart unless-stopped \
        -v rtmp-server-data:/data \
        -p "${rtmp_stats_port}":8080/tcp -p "${rtmp_port}":1935/tcp \
        alexanderwagnerdev/rtmp-server:beta
    fi

    health_check rtmp-server

    if [ ! -f ".rtmp_api_token" ]; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${INFO}Warte auf vollständiges Initialisieren des Containers...${NC}"
      else
        echo -e "${INFO}Waiting for the container to fully initialize...${NC}"
      fi
      rtmp_token=$(extract_rtmp_api_token_with_retry)
      if [[ -n "$rtmp_token" ]]; then
        echo "$rtmp_token" > .rtmp_api_token
        if [[ "$lang" == "de" ]]; then
          echo -e "${SUCCESS}RTMP API-Token erfolgreich extrahiert und gespeichert.${NC}"
        else
          echo -e "${SUCCESS}RTMP API token successfully extracted and saved.${NC}"
        fi
      else
        if [[ "$lang" == "de" ]]; then
          echo -e "${ERROR}RTMP API-Token konnte nicht extrahiert werden.${NC}"
        else
          echo -e "${ERROR}RTMP API token could not be extracted.${NC}"
        fi
      fi
    else
      if [[ "$lang" == "de" ]]; then
        echo -e "${SUCCESS}RTMP API-Token bereits vorhanden in .rtmp_api_token${NC}"
      else
        echo -e "${SUCCESS}RTMP API token already present in .rtmp_api_token${NC}"
      fi
    fi
  else
    echo -e "$rtmp_skip_msg"
  fi

  read -rp "$srtla_prompt " install_srtla
  install_srtla=${install_srtla:-n}
  if [[ "$install_srtla" =~ ^[JjYy] ]]; then
    echo -e "$srtla_install_msg"
    if ! docker volume inspect srtla-server >/dev/null 2>&1; then
      docker volume create srtla-server
    fi
    volume_data_path="/var/lib/docker/volumes/srtla-server/_data"
    sudo chown -R 3001:3001 "$volume_data_path"
    sudo chmod -R 755 "$volume_data_path"
    docker_pull_fallback "alexanderwagnerdev/srtla-server:beta" "ghcr.io/alexanderwagnerdev/srtla-server:beta"

    if [[ "$use_wud_labels" =~ ^[JjYy] ]]; then
      docker run -d --name srtla-server --restart unless-stopped \
        --label "wud.watch=true" \
        --label "wud.watch.digest=true" \
        --label "wud.tag.include=^beta$" \
        -v /var/lib/docker/volumes/srtla-server/_data:/var/lib/sls \
        -p "${srt_player_port}":4000/udp -p "${srt_sender_port}":4001/udp -p "${srtla_port}":5000/udp -p "${sls_stats_port}":8080/tcp \
        alexanderwagnerdev/srtla-server:beta
    else
      docker run -d --name srtla-server --restart unless-stopped \
        -v /var/lib/docker/volumes/srtla-server/_data:/var/lib/sls \
        -p "${srt_player_port}":4000/udp -p "${srt_sender_port}":4001/udp -p "${srtla_port}":5000/udp -p "${sls_stats_port}":8080/tcp \
        alexanderwagnerdev/srtla-server:beta
    fi

    health_check srtla-server

    if [ ! -f ".apikey" ]; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${INFO}Warte auf vollständiges Initialisieren des Containers...${NC}"
      else
        echo -e "${INFO}Waiting for the container to fully initialize...${NC}"
      fi
      apikey=$(extract_api_key_with_retry)
      if [[ -n "$apikey" ]]; then
        echo "$apikey" > .apikey
        if [[ "$lang" == "de" ]]; then
          echo -e "${SUCCESS}API-Key erfolgreich extrahiert und gespeichert.${NC}"
        else
          echo -e "${SUCCESS}API key successfully extracted and saved.${NC}"
        fi
      else
        if [[ "$lang" == "de" ]]; then
          echo -e "${ERROR}API-Key konnte nicht extrahiert werden.${NC}"
        else
          echo -e "${ERROR}API key could not be extracted.${NC}"
        fi
      fi
    else
      if [[ "$lang" == "de" ]]; then
        echo -e "${SUCCESS}API-Key bereits vorhanden in .apikey${NC}"
      else
        echo -e "${SUCCESS}API key already present in .apikey${NC}"
      fi
    fi
  else
    echo -e "$srtla_skip_msg"
  fi

  if [[ "$install_wud" =~ ^[JjYy] ]]; then
    echo -e "$wud_install_msg"
    docker_pull_fallback "getwud/wud:latest" "ghcr.io/getwud/wud:latest"
    docker run -d --name wud --restart always -v "/var/run/docker.sock:/var/run/docker.sock" -e WUD_TRIGGER_DOCKER_LOCAL_PRUNE=true getwud/wud:latest
  else
    echo -e "$wud_skip_msg"
  fi

  read -rp "$slspanel_install_prompt" install_slspanel
  install_slspanel=${install_slspanel:-n}
  if [[ "$install_slspanel" =~ ^[JjYy] ]]; then

    read -rp "$slspanel_login_prompt" enable_login
    enable_login=${enable_login:-n}

    if [[ "$enable_login" =~ ^[JjYy] ]]; then
      read -rp "$slspanel_username_prompt" slspanel_username
      slspanel_username=${slspanel_username:-admin}
      read -rsp "$slspanel_password_prompt" slspanel_password
      echo ""
    else
      slspanel_username=""
      slspanel_password=""
    fi

    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}Starte SLSPanel Docker-Container...${NC}"
    else
      echo -e "${INFO}Starting SLSPanel Docker container...${NC}"
    fi

    slspanel_api_url="http://${public_ip}:${sls_stats_port}"
    apikey=$(cat .apikey 2>/dev/null || echo "")
    if [[ -z "$apikey" ]]; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${YELLOW}Warnung: Kein API-Key gefunden (.apikey). SLSPanel wird ohne gültigen API-Key gestartet.${NC}"
      else
        echo -e "${YELLOW}Warning: No API key found (.apikey). SLSPanel will start without a valid API key.${NC}"
      fi
    fi
    TZ=$(grep -v '^$' /etc/timezone 2>/dev/null || timedatectl show --property=Timezone --value 2>/dev/null || echo UTC)

    docker_pull_fallback "alexanderwagnerdev/slspanel:beta" "ghcr.io/alexanderwagnerdev/slspanel:beta"

    if [[ "$enable_login" =~ ^[JjYy] ]]; then
      if [[ "$use_wud_labels" =~ ^[JjYy] ]]; then
        docker run -d --name slspanel --restart unless-stopped \
          --label "wud.watch=true" \
          --label "wud.watch.digest=true" \
          --label "wud.tag.include=^beta$" \
          -e REQUIRE_LOGIN=True \
          -e WEB_USERNAME="${slspanel_username}" \
          -e WEB_PASSWORD="${slspanel_password}" \
          -e SLS_API_URL="${slspanel_api_url}" \
          -e SLS_API_KEY="${apikey}" \
          -e SLS_DOMAIN_IP="${public_ip}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -e SRT_PUBLISH_PORT=${srt_sender_port} \
          -e SRT_PLAYER_PORT=${srt_player_port} \
          -e SRTLA_PUBLISH_PORT=${srtla_port} \
          -e SLS_STATS_PORT=${sls_stats_port} \
          -p ${slspanel_port}:8000/tcp alexanderwagnerdev/slspanel:beta
      else
        docker run -d --name slspanel --restart unless-stopped \
          -e REQUIRE_LOGIN=True \
          -e WEB_USERNAME="${slspanel_username}" \
          -e WEB_PASSWORD="${slspanel_password}" \
          -e SLS_API_URL="${slspanel_api_url}" \
          -e SLS_API_KEY="${apikey}" \
          -e SLS_DOMAIN_IP="${public_ip}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -e SRT_PUBLISH_PORT=${srt_sender_port} \
          -e SRT_PLAYER_PORT=${srt_player_port} \
          -e SRTLA_PUBLISH_PORT=${srtla_port} \
          -e SLS_STATS_PORT=${sls_stats_port} \
          -p ${slspanel_port}:8000/tcp alexanderwagnerdev/slspanel:beta
      fi
    else
      if [[ "$use_wud_labels" =~ ^[JjYy] ]]; then
        docker run -d --name slspanel --restart unless-stopped \
          --label "wud.watch=true" \
          --label "wud.watch.digest=true" \
          --label "wud.tag.include=^beta$" \
          -e REQUIRE_LOGIN=False \
          -e SLS_API_URL="${slspanel_api_url}" \
          -e SLS_API_KEY="${apikey}" \
          -e SLS_DOMAIN_IP="${public_ip}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -e SRT_PUBLISH_PORT=${srt_sender_port} \
          -e SRT_PLAYER_PORT=${srt_player_port} \
          -e SRTLA_PUBLISH_PORT=${srtla_port} \
          -e SLS_STATS_PORT=${sls_stats_port} \
          -p ${slspanel_port}:8000/tcp alexanderwagnerdev/slspanel:beta
      else
        docker run -d --name slspanel --restart unless-stopped \
          -e REQUIRE_LOGIN=False \
          -e SLS_API_URL="${slspanel_api_url}" \
          -e SLS_API_KEY="${apikey}" \
          -e SLS_DOMAIN_IP="${public_ip}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -e SRT_PUBLISH_PORT=${srt_sender_port} \
          -e SRT_PLAYER_PORT=${srt_player_port} \
          -e SRTLA_PUBLISH_PORT=${srtla_port} \
          -e SLS_STATS_PORT=${sls_stats_port} \
          -p ${slspanel_port}:8000/tcp alexanderwagnerdev/slspanel:beta
      fi
    fi

    health_check slspanel
  else
    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}SLSPanel wird nicht installiert.${NC}"
    else
      echo -e "${INFO}Skipping SLSPanel installation.${NC}"
    fi
  fi

  read -rp "$rtmppanel_install_prompt" install_rtmppanel
  install_rtmppanel=${install_rtmppanel:-n}
  if [[ "$install_rtmppanel" =~ ^[JjYy] ]]; then

    read -rp "$rtmppanel_login_prompt" rtmppanel_enable_login
    rtmppanel_enable_login=${rtmppanel_enable_login:-n}

    if [[ "$rtmppanel_enable_login" =~ ^[JjYy] ]]; then
      read -rp "$rtmppanel_username_prompt" rtmppanel_username
      rtmppanel_username=${rtmppanel_username:-admin}
      read -rsp "$rtmppanel_password_prompt" rtmppanel_password
      echo ""
    else
      rtmppanel_username=""
      rtmppanel_password=""
    fi

    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}Starte RTMPPanel Docker-Container...${NC}"
    else
      echo -e "${INFO}Starting RTMPPanel Docker container...${NC}"
    fi

    rtmp_api_url="http://${public_ip}:${rtmp_stats_port}"
    rtmp_token=$(cat .rtmp_api_token 2>/dev/null || echo "")
    if [[ -z "$rtmp_token" ]]; then
      if [[ "$lang" == "de" ]]; then
        echo -e "${YELLOW}Warnung: Kein RTMP API-Token gefunden (.rtmp_api_token). Stelle sicher, dass der RTMP-Server installiert wurde. RTMPPanel wird ohne gültigen Token gestartet.${NC}"
      else
        echo -e "${YELLOW}Warning: No RTMP API token found (.rtmp_api_token). Make sure the RTMP server was installed. RTMPPanel will start without a valid token.${NC}"
      fi
    fi
    rtmppanel_secret=$(get_or_create_rtmppanel_secret)
    TZ=$(grep -v '^$' /etc/timezone 2>/dev/null || timedatectl show --property=Timezone --value 2>/dev/null || echo UTC)

    docker_pull_fallback "alexanderwagnerdev/rtmppanel:beta" "ghcr.io/alexanderwagnerdev/rtmppanel:beta"

    if [[ "$rtmppanel_enable_login" =~ ^[JjYy] ]]; then
      if [[ "$use_wud_labels" =~ ^[JjYy] ]]; then
        docker run -d --name rtmppanel --restart unless-stopped \
          --label "wud.watch=true" \
          --label "wud.watch.digest=true" \
          --label "wud.tag.include=^beta$" \
          -e REQUIRE_LOGIN=True \
          -e USERNAME="${rtmppanel_username}" \
          -e PASSWORD="${rtmppanel_password}" \
          -e SECRET_KEY="${rtmppanel_secret}" \
          -e LRTMP2_API_URL="${rtmp_api_url}" \
          -e LRTMP2_API_TOKEN="${rtmp_token}" \
          -e LRTMP2_DOMAIN="${public_ip}" \
          -e LRTMP2_RTMP_PORT="${rtmp_port}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -v rtmppanel-data:/data \
          -p ${rtmppanel_port}:8000/tcp alexanderwagnerdev/rtmppanel:beta
      else
        docker run -d --name rtmppanel --restart unless-stopped \
          -e REQUIRE_LOGIN=True \
          -e USERNAME="${rtmppanel_username}" \
          -e PASSWORD="${rtmppanel_password}" \
          -e SECRET_KEY="${rtmppanel_secret}" \
          -e LRTMP2_API_URL="${rtmp_api_url}" \
          -e LRTMP2_API_TOKEN="${rtmp_token}" \
          -e LRTMP2_DOMAIN="${public_ip}" \
          -e LRTMP2_RTMP_PORT="${rtmp_port}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -v rtmppanel-data:/data \
          -p ${rtmppanel_port}:8000/tcp alexanderwagnerdev/rtmppanel:beta
      fi
    else
      if [[ "$use_wud_labels" =~ ^[JjYy] ]]; then
        docker run -d --name rtmppanel --restart unless-stopped \
          --label "wud.watch=true" \
          --label "wud.watch.digest=true" \
          --label "wud.tag.include=^beta$" \
          -e REQUIRE_LOGIN=False \
          -e SECRET_KEY="${rtmppanel_secret}" \
          -e LRTMP2_API_URL="${rtmp_api_url}" \
          -e LRTMP2_API_TOKEN="${rtmp_token}" \
          -e LRTMP2_DOMAIN="${public_ip}" \
          -e LRTMP2_RTMP_PORT="${rtmp_port}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -v rtmppanel-data:/data \
          -p ${rtmppanel_port}:8000/tcp alexanderwagnerdev/rtmppanel:beta
      else
        docker run -d --name rtmppanel --restart unless-stopped \
          -e REQUIRE_LOGIN=False \
          -e SECRET_KEY="${rtmppanel_secret}" \
          -e LRTMP2_API_URL="${rtmp_api_url}" \
          -e LRTMP2_API_TOKEN="${rtmp_token}" \
          -e LRTMP2_DOMAIN="${public_ip}" \
          -e LRTMP2_RTMP_PORT="${rtmp_port}" \
          -e LANG="${lang}" \
          -e TZ="${TZ}" \
          -v rtmppanel-data:/data \
          -p ${rtmppanel_port}:8000/tcp alexanderwagnerdev/rtmppanel:beta
      fi
    fi

    health_check rtmppanel
  else
    echo -e "$rtmppanel_skip_msg"
  fi

  print_available_services \
    "$app_url" \
    "$slspanel_port" \
    "$(cat .apikey 2>/dev/null || echo 'N/A')" \
    "$public_ip" \
    "$srtla_port" \
    "$srt_sender_port" \
    "$srt_player_port" \
    "$sls_stats_port" \
    "$rtmp_stats_port" \
    "$rtmp_port" \
    "$rtmppanel_port"

  echo -e "$done_msg"
  echo -e "$restart_msg"
fi
