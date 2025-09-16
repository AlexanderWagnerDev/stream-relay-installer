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
 / ___|| |_ _ __ ___  __ _ _ __ ___   |  _ \ ___| | __ _ _   _  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 \___ \| __| '__/ _ \/ _` | '_ ` _ \  | |_) / _ \ |/ _` | | | |  | || '_ \/ __| __/ _` | | |/ _ \ '__|
  ___) | |_| | |  __/ (_| | | | | | | |  _ <  __/ | (_| | |_| |  | || | | __ \ || (_| | | |  __/ |   
 |____/ \__|_|  \___|\__,_|_| |_| |_| |_| \_\___|_|\__,_|\__, | |___|_| |_|___/\__\__,_|_|_|\___|_|   
                                                         |___/                                                                                                
           von AlexanderWagnerDev
EOF
}

function print_ascii_art_en() {
  cat <<"EOF"
  ____  _                              ____      _               ___           _        _ _           
 / ___|| |_ _ __ ___  __ _ _ __ ___   |  _ \ ___| | __ _ _   _  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 \___ \| __| '__/ _ \/ _` | '_ ` _ \  | |_) / _ \ |/ _` | | | |  | || '_ \/ __| __/ _` | | |/ _ \ '__|
  ___) | |_| | |  __/ (_| | | | | | | |  _ <  __/ | (_| | |_| |  | || | | __ \ || (_| | | |  __/ |   
 |____/ \__|_|  \___|\__,_|_| |_| |_| |_| \_\___|_|\__,_|\__, | |___|_| |_|___/\__\__,_|_|_|\___|_|   
                                                         |___/                                                                                                                            
           by AlexanderWagnerDev
EOF
}

function system_update_prompt() {
  export DEBIAN_FRONTEND=noninteractive
  if [[ "$lang" == "de" ]]; then
    read -rp $'\033[1;33mSoll das System jetzt aktualisiert werden? (j/n):\033[0m ' sys_update
    if [[ "$sys_update" =~ ^[JjYy] ]]; then
      echo -e "${INFO}System wird aktualisiert...${NC}"
      sudo apt-get update && sudo apt-get dist-upgrade -y
      echo -e "${SUCCESS}Systemaktualisierung abgeschlossen.${NC}"
    else
      echo -e "${INFO}Systemaktualisierung übersprungen.${NC}"
    fi
  else
    read -rp $'\033[1;33mDo you want to update the system now? (y/n):\033[0m ' sys_update
    if [[ "$sys_update" =~ ^[Yy] ]]; then
      echo -e "${INFO}Updating system...${NC}"
      sudo apt-get update && sudo apt-get dist-upgrade -y
      echo -e "${SUCCESS}System update complete.${NC}"
    else
      echo -e "${INFO}System update skipped.${NC}"
    fi
  fi
}

function install_docker_debian_ubuntu() {
  local distro_name
  local distro_version
  distro_name=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
  distro_version=$(lsb_release -rs)
  sudo apt-get update
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
    
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  
  local repo_file="docker.list"
  local repo_entry="deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]"
  
  local codename
  codename=$(lsb_release -cs)
  
  if [[ "$distro_name" == "ubuntu" ]]; then
    repo_entry="deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable"
  elif [[ "$distro_name" == "debian" ]]; then
    repo_entry="deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $codename stable"
  else
    repo_entry="deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable"
  fi

  echo "$repo_entry" | sudo tee /etc/apt/sources.list.d/$repo_file
  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$USER"
}

function read_port () {
  local prompt="$1"
  local default_port="$2"
  local lang="$3"
  local response
  if [[ "$lang" == "de" ]]; then
    echo -n "$prompt [$default_port]: "
  else
    echo -n "$prompt [$default_port]: "
  fi
  read -r response
  if [[ -z "$response" ]]; then
    response=$default_port
  fi
  echo "$response"
}

function get_public_ip() {
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
  if docker pull "$image"; then
    return 0
  else
    if [[ "$lang" == "de" ]]; then
      echo -e "${YELLOW}Warnung: Image '$image' nicht von Docker Hub gefunden, versuche Fallback GHCR...${NC}"
    else
      echo -e "${YELLOW}Warning: Image '$image' not found on Docker Hub, trying fallback GHCR...${NC}"
    fi
    if docker pull "$fallback_image"; then
      return 0
    else
      if [[ "$lang" == "de" ]]; then
        echo -e "${RED}Fehler: Image konnte weder von Docker Hub noch GHCR gezogen werden: $image / $fallback_image${NC}"
      else
        echo -e "${RED}Error: Image could not be pulled from Docker Hub nor GHCR: $image / $fallback_image${NC}"
      fi
      return 1
    fi
  fi
}

function extract_api_key() {
  local apikey=""
  apikey=$(docker logs srtla-server 2>/dev/null | grep "Generated default admin API key:" | sed 's/.*Generated default admin API key: \([A-Za-z0-9]*\).*/\1/' | tail -1)
  echo "$apikey"
}

function print_available_services() {
  local app_url="$1"
  local management_port="$2"
  if [[ "$lang" == "de" ]]; then
    echo -e "${HEADER}Verfügbare Dienste:${NC}"
    echo -e "${SUCCESS}Management UI: http://${public_ip}:${management_port}${NC}"
    echo -e "${SUCCESS}Backend API: ${app_url}${NC}"
    echo -e "${SUCCESS}SRTla Port: ${srtla_port}/udp${NC}"
    echo -e "${SUCCESS}SRT Sender Port: ${srt_sender_port}/udp${NC}"
    echo -e "${SUCCESS}SRT Player Port: ${srt_player_port}/udp${NC}"
    echo -e "${SUCCESS}Statistics Port: ${sls_stats_port}/tcp${NC}"
    echo -e "${SUCCESS}RTMP Stats/Web Port: ${rtmp_stats_port}/tcp${NC}"
    echo -e "${SUCCESS}RTMP Port: ${rtmp_port}/tcp${NC}"
  else
    echo -e "${HEADER}Available services:${NC}"
    echo -e "${SUCCESS}Management UI: http://${public_ip}:${management_port}${NC}"
    echo -e "${SUCCESS}Backend API: ${app_url}${NC}"
    echo -e "${SUCCESS}SRTla Port: ${srtla_port}/udp${NC}"
    echo -e "${SUCCESS}SRT Sender Port: ${srt_sender_port}/udp${NC}"
    echo -e "${SUCCESS}SRT Player Port: ${srt_player_port}/udp${NC}"
    echo -e "${SUCCESS}Statistics Port: ${sls_stats_port}/tcp${NC}"
    echo -e "${SUCCESS}RTMP Stats/Web Port: ${rtmp_stats_port}/tcp${NC}"
    echo -e "${SUCCESS}RTMP Port: ${rtmp_port}/tcp${NC}"
  fi
}

function print_help() {
  if [[ "$lang" == "de" ]]; then
    echo -e "${HEADER}Hilfe:${NC}
  Mit diesem Script kannst du die Installation, das Starten, Stoppen oder das Entfernen der Stream-Services ausführen.
  ${GREEN}Funktionen:${NC}
  [installieren] Installation durchführen
  [starten]     Container starten
  [stoppen]     Container stoppen
  [deinstallieren] Container/Images/optional Volumes entfernen
  [hilfe]       Diese Hilfe anzeigen"
  else
    echo -e "${HEADER}Help:${NC}
  This script lets you install, start, stop or uninstall the stream services interactively.
  ${GREEN}Functions:${NC}
  [install]     Run installation
  [start]       Start containers
  [stop]        Stop containers
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
    health=$(docker inspect --format='{{.State.Health.Status}}' "$cname" 2>/dev/null)
    if [[ "$health" == "healthy" ]]; then
      [[ "$lang" == "de" ]] && echo -e "${SUCCESS}Container $cname ist gesund.${NC}" || echo -e "${SUCCESS}Container $cname is healthy.${NC}"
    else
      [[ "$lang" == "de" ]] && echo -e "${INFO}Container $cname läuft. (Kein Healthcheck definiert)${NC}" || echo -e "${INFO}Container $cname is running. (No healthcheck defined)${NC}"
    fi
  else
    [[ "$lang" == "de" ]] && echo -e "${ERROR}Container $cname läuft NICHT!${NC}" || echo -e "${ERROR}Container $cname is NOT running!${NC}"
  fi
}

function stop_services() {
  for cname in rtmp-server srtla-server slsmu watchtower; do
    if docker ps --format '{{.Names}}' | grep -q "^$cname$"; then
      docker stop "$cname"
      [[ "$lang" == "de" ]] && echo -e "${INFO}Container $cname gestoppt.${NC}" || echo -e "${INFO}Stopped container $cname.${NC}"
    fi
  done
}

function start_services() {
  for cname in rtmp-server srtla-server slsmu watchtower; do
    docker start "$cname" 2>/dev/null
    health_check "$cname"
  done
}

function uninstall_services() {
  for cname in rtmp-server srtla-server slsmu watchtower; do
    if docker ps -a --format '{{.Names}}' | grep -q "^$cname$"; then
      docker rm -f "$cname"
      [[ "$lang" == "de" ]] && echo -e "${INFO}Container $cname entfernt.${NC}" || echo -e "${INFO}Removed container $cname.${NC}"
    fi
  done
  for img in alexanderwagnerdev/rtmp-server alexanderwagnerdev/srtla-server alexanderwagnerdev/slsmu containrrr/watchtower; do
    docker rmi -f "$img" 2>/dev/null
    docker rmi -f "ghcr.io/${img}" 2>/dev/null
  done
  if [[ "$lang" == "de" ]]; then
    read -rp "${YELLOW}Sollen auch Volumes gelöscht werden? (j/n):${NC} " rmvol
    if [[ "$rmvol" =~ ^[Jj] ]]; then
      docker volume rm srtla-server 2>/dev/null
      echo -e "${SUCCESS}Docker-Volume srtla-server entfernt.${NC}"
    else
      echo -e "${INFO}Volumes bleiben erhalten.${NC}"
    fi
    echo -e "${SUCCESS}Alle Container und Images entfernt.${NC}"
  else
    read -rp "${YELLOW}Should volumes be deleted as well? (y/n):${NC} " rmvol
    if [[ "$rmvol" =~ ^[Yy] ]]; then
      docker volume rm srtla-server 2>/dev/null
      echo -e "${SUCCESS}Docker volume srtla-server removed.${NC}"
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
  echo -e "${YELLOW}Was möchtest du tun?${NC}"
  echo " [1] Installieren"
  echo " [2] Starten"
  echo " [3] Stoppen"
  echo " [4] Deinstallieren"
  echo " [5] Hilfe"
  read -rp "Auswahl [1]: " mainaction
else
  echo -e "${YELLOW}What do you want to do?${NC}"
  echo " [1] Install"
  echo " [2] Start"
  echo " [3] Stop"
  echo " [4] Uninstall"
  echo " [5] Help"
  read -rp "Choice [1]: " mainaction
fi
mainaction=${mainaction:-1}

if [[ "$mainaction" == "5" ]]; then
  print_help
  exit 0
elif [[ "$mainaction" == "2" ]]; then
  start_services
  exit 0
elif [[ "$mainaction" == "3" ]]; then
  stop_services
  exit 0
elif [[ "$mainaction" == "4" ]]; then
  uninstall_services
  exit 0
fi

system_update_prompt

read -rp "$docker_prompt " install_docker
install_docker=${install_docker:-n}
if [[ "$install_docker" =~ ^[JjYy] ]]; then
  echo -e "$docker_install_msg"
  distro_info=$(lsb_release -a 2>/dev/null || cat /etc/os-release)
  install_docker_debian_ubuntu "$distro_info"
else
  echo -e "$docker_skip_msg"
fi

read -rp "$ipv6_prompt " enable_ipv6
enable_ipv6=${enable_ipv6:-n}
if [[ "$enable_ipv6" =~ ^[JjYy] ]]; then
  echo -e "$ipv6_enable_msg"
  if [[ -f /etc/docker/daemon.json ]]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak_$(date +%s)
  fi
  echo '{ "ipv6": true }' | sudo tee /etc/docker/daemon.json > /dev/null
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
  sls_stats_port=8080
  rtmp_stats_port=8090
  rtmp_port=1935
  slsmu_port=3000
else
  srt_player_port=$(read_port "${port_prompts[0]}" 4000 "$lang")
  srt_sender_port=$(read_port "${port_prompts[1]}" 4001 "$lang")
  srtla_port=$(read_port "${port_prompts[2]}" 5000 "$lang")
  sls_stats_port=$(read_port "${port_prompts[3]}" 8080 "$lang")
  rtmp_stats_port=$(read_port "${port_prompts[4]}" 8090 "$lang")
  rtmp_port=$(read_port "${port_prompts[5]}" 1935 "$lang")
  slsmu_port=$(read_port "${port_prompts[6]}" 3000 "$lang")
fi

read -rp "$rtmp_prompt " install_rtmp
install_rtmp=${install_rtmp:-n}
if [[ "$install_rtmp" =~ ^[JjYy] ]]; then
  echo -e "$rtmp_install_msg"
  docker_pull_fallback "alexanderwagnerdev/rtmp-server:latest" "ghcr.io/alexanderwagnerdev/rtmp-server:latest"
  docker rm -f rtmp-server 2>/dev/null || true
  docker run -d --name rtmp-server --restart unless-stopped -p ${rtmp_stats_port}:80 -p ${rtmp_port}:1935 alexanderwagnerdev/rtmp-server:latest
  health_check rtmp-server
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
  sudo chown 3001:3001 "$volume_data_path"
  sudo chmod 755 "$volume_data_path"
  docker_pull_fallback "alexanderwagnerdev/srtla-server:latest" "ghcr.io/alexanderwagnerdev/srtla-server:latest"
  docker rm -f srtla-server 2>/dev/null || true
  docker run -d --name srtla-server --restart unless-stopped -v srtla-server:/var/lib/sls \
    -p ${srt_player_port}:4000/udp -p ${srt_sender_port}:4001/udp -p ${srtla_port}:5000/udp -p ${sls_stats_port}:8080 \
    alexanderwagnerdev/srtla-server:latest
  health_check srtla-server
  if [ ! -f ".apikey" ]; then
    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}Warte auf vollständiges Initialisieren des Containers...${NC}"
    else
      echo -e "${INFO}Waiting for the container to fully initialize...${NC}"
    fi
    sleep 5
    if [[ "$lang" == "de" ]]; then
      echo -e "${INFO}Versuche API-Key zu extrahieren...${NC}"
    else
      echo -e "${INFO}Trying to extract API key...${NC}"
    fi
    apikey=$(extract_api_key)
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
  public_ip=$(get_public_ip)
  if [[ "$public_ip" == "127.0.0.1" ]]; then
    if [[ "$lang" == "de" ]]; then
      echo -e "${YELLOW}Warnung: Öffentliche IP konnte nicht ermittelt werden, localhost wird als APP_URL benutzt.${NC}"
    else
      echo -e "${YELLOW}Warning: Public IP could not be determined, localhost will be used as APP_URL.${NC}"
    fi
  fi
  app_url="http://${public_ip}:${sls_stats_port}"
  docker_pull_fallback "alexanderwagnerdev/slsmu:latest" "ghcr.io/alexanderwagnerdev/slsmu:latest"
  docker rm -f slsmu 2>/dev/null || true
  docker run -d --name slsmu --restart unless-stopped \
    -p ${slsmu_port}:3000 \
    -e REACT_APP_BASE_URL="${app_url}" \
    -e REACT_APP_SRT_PLAYER_PORT="${srt_player_port}" \
    -e REACT_APP_SRT_SENDER_PORT="${srt_sender_port}" \
    -e REACT_APP_SLS_STATS_PORT="${sls_stats_port}" \
    -e REACT_APP_SRTLA_PORT="${srtla_port}" \
    alexanderwagnerdev/slsmu:latest
  health_check slsmu
  print_available_services "$app_url" "$slsmu_port"
else
  echo -e "$srtla_skip_msg"
fi

read -rp "$watchtower_prompt " install_watchtower
install_watchtower=${install_watchtower:-n}
if [[ "$install_watchtower" =~ ^[JjYy] ]]; then
  echo -e "$watchtower_install_msg"
  docker_pull_fallback "containrrr/watchtower:latest" "ghcr.io/containrrr/watchtower:latest"
  docker rm -f watchtower 2>/dev/null || true
  docker run -d --name watchtower --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:latest --cleanup
  health_check watchtower
else
  echo -e "$watchtower_skip_msg"
fi

echo -e "$done_msg"
echo -e "$restart_msg"
