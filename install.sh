#!/bin/bash

set -e

function print_ascii_art_de() {
cat <<"EOF"
  ____  _                              ____      _               ___           _        _ _           
 / ___|| |_ _ __ ___  __ _ _ __ ___   |  _ \ ___| | __ _ _   _  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
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
 / ___|| |_ _ __ ___  __ _ _ __ ___   |  _ \ ___| | __ _ _   _  |_ _|_ __  ___| |_ __ _| | | ___ _ __ 
 \___ \| __| '__/ _ \/ _` | '_ ` _ \  | |_) / _ \ |/ _` | | | |  | || '_ \/ __| __/ _` | | |/ _ \ '__|
  ___) | |_| | |  __/ (_| | | | | | | |  _ <  __/ | (_| | |_| |  | || | | \__ \ || (_| | | |  __/ |   
 |____/ \__|_|  \___|\__,_|_| |_| |_| |_| \_\___|_|\__,_|\__, | |___|_| |_|___/\__\__,_|_|_|\___|_|   
                                                         |___/                                                                                   
           by AlexanderWagnerDev
EOF
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
  local repo_entry="deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg]"
  local codename
  codename=$(lsb_release -cs)

  if [[ "$distro_name" == "ubuntu" ]]; then
    if dpkg --compare-versions "$distro_version" ge "24.04"; then
      repo_file="docker.source"
      repo_entry="deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable"
    else
      repo_entry="deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable"
    fi
  elif [[ "$distro_name" == "debian" ]]; then
    if dpkg --compare-versions "$distro_version" ge "13"; then
      repo_file="docker.source"
      repo_entry="deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $codename stable"
    else
      repo_entry="deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $codename stable"
    fi
  else
    repo_entry="deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable"
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
    echo "Warnung: Image '$image' nicht von Docker Hub gefunden, versuche Fallback GHCR..."
    if docker pull "$fallback_image"; then
      return 0
    else
      echo "Fehler: Image konnte weder von Docker Hub noch GHCR gezogen werden: $image / $fallback_image"
      return 1
    fi
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
  srtla_prompt="SRTLA-Receiver Docker Container installieren und starten? (j/n):"
  watchtower_prompt="Watchtower Container (automatische Updates) installieren und starten? (j/n):"
  ipv6_prompt="Docker IPv6 Unterstützung aktivieren? (j/n):"
  use_default_ports_prompt="Standardports verwenden? (j/n):"
  done_msg="Setup abgeschlossen."
  docker_install_msg="Docker Installation wird gestartet..."
  docker_skip_msg="Docker wird nicht installiert."
  rtmp_install_msg="Starte RTMP-Server Docker-Container..."
  rtmp_skip_msg="RTMP-Server wird nicht installiert."
  srtla_install_msg="Starte SRTLA-Receiver Docker-Container..."
  srtla_skip_msg="SRTLA-Receiver wird nicht installiert."
  watchtower_install_msg="Starte Watchtower Docker-Container..."
  watchtower_skip_msg="Watchtower wird nicht installiert."
  ipv6_enable_msg="Docker IPv6 Unterstützung wird aktiviert..."
  ipv6_skip_msg="Docker IPv6 Unterstützung wird nicht aktiviert."
  restart_msg="Bitte beachten: Nach Docker-Installation ist evtl. ein Neustart oder eine neue Anmeldung nötig, damit Docker-Gruppenrechte aktiv werden."
  port_prompts=(
    "Port für SRT-Player (Standard: 4000)"
    "Port für SRT-Sender (Standard: 4001)"
    "Port für SRTLA (Standard: 5000)"
    "Port für SLS Stats (Standard: 8080)"
    "Port für RTMP-Server Stats/Web (Standard: 8090)"
    "Port für RTMP (Standard: 1935)"
    "Port für SLSMU (Standard: 3000)"
  )
else
  docker_prompt="Install Docker? (y/n):"
  rtmp_prompt="Install and start RTMP Server Docker container? (y/n):"
  srtla_prompt="Install and start SRTLA Receiver Docker container? (y/n):"
  watchtower_prompt="Install and start Watchtower container (automatic updates)? (y/n):"
  ipv6_prompt="Enable Docker IPv6 support? (y/n):"
  use_default_ports_prompt="Use default ports? (y/n):"
  done_msg="Setup completed."
  docker_install_msg="Starting Docker installation..."
  docker_skip_msg="Skipping Docker installation."
  rtmp_install_msg="Starting RTMP Server Docker container..."
  rtmp_skip_msg="Skipping RTMP Server installation."
  srtla_install_msg="Starting SRTLA Receiver Docker container..."
  srtla_skip_msg="Skipping SRTLA Receiver installation."
  watchtower_install_msg="Starting Watchtower Docker container..."
  watchtower_skip_msg="Skipping Watchtower installation."
  ipv6_enable_msg="Enabling Docker IPv6 support..."
  ipv6_skip_msg="Not enabling Docker IPv6 support."
  restart_msg="Please note: After Docker installation a reboot or re-login might be necessary to activate Docker group permissions."
  port_prompts=(
    "Port for SRT Player (default: 4000)"
    "Port for SRT Sender (default: 4001)"
    "Port for SRTLA (default: 5000)"
    "Port for SLS Stats (default: 8080)"
    "Port for RTMP Server Stats/Web (default: 8090)"
    "Port for RTMP (default: 1935)"
    "Port for SLSMU (default: 3000)"
  )
fi

read -rp "$docker_prompt " install_docker
install_docker=${install_docker:-n}
if [[ "$install_docker" =~ ^[JjYy] ]]; then
  echo "$docker_install_msg"
  distro_info=$(lsb_release -a 2>/dev/null || cat /etc/os-release)
  install_docker_debian_ubuntu "$distro_info"
else
  echo "$docker_skip_msg"
fi

read -rp "$ipv6_prompt " enable_ipv6
enable_ipv6=${enable_ipv6:-n}
if [[ "$enable_ipv6" =~ ^[JjYy] ]]; then
  echo "$ipv6_enable_msg"
  if [ -f /etc/docker/daemon.json ]; then
    sudo cp /etc/docker/daemon.json /etc/docker/daemon.json.bak_$(date +%s)
  fi
  echo '{ "ipv6": true }' | sudo tee /etc/docker/daemon.json > /dev/null
  sudo systemctl restart docker
else
  echo "$ipv6_skip_msg"
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
  echo "$rtmp_install_msg"
  docker_pull_fallback "alexanderwagnerdev/rtmp-server:latest" "ghcr.io/alexanderwagnerdev/rtmp-server:latest"
  docker rm -f rtmp-server 2>/dev/null || true
  docker run -d --name rtmp-server --restart unless-stopped -p ${rtmp_stats_port}:80 -p ${rtmp_port}:1935 alexanderwagnerdev/rtmp-server:latest
else
  echo "$rtmp_skip_msg"
fi

read -rp "$srtla_prompt " install_srtla
install_srtla=${install_srtla:-n}
if [[ "$install_srtla" =~ ^[JjYy] ]]; then
  echo "$srtla_install_msg"
  if ! docker volume inspect srtla-server >/dev/null 2>&1; then
    docker volume create srtla-server
  fi
  volume_data_path="/var/lib/docker/volumes/srtla-server/_data"
  sudo chown 3001:3001 "$volume_data_path"
  sudo chmod 755 "$volume_data_path"
  docker_pull_fallback "alexanderwagnerdev/srtla-server:latest" "ghcr.io/alexanderwagnerdev/srtla-server:latest"
  docker rm -f srtla-receiver 2>/dev/null || true
  docker run -d --name srtla-receiver --restart unless-stopped -v srtla-server:/var/lib/sls \
    -p ${srt_player_port}:4000/udp -p ${srt_sender_port}:4001/udp -p ${srtla_port}:5000/udp -p ${sls_stats_port}:8080 \
    alexanderwagnerdev/srtla-server:latest

  public_ip=$(get_public_ip)
  if [[ "$public_ip" == "127.0.0.1" ]]; then
    echo "Warnung: Öffentliche IP konnte nicht ermittelt werden, localhost wird als APP_URL benutzt."
  fi
  app_url="http://${public_ip}:${sls_stats_port}"

  docker_pull_fallback "alexanderwagnerdev/slsmu:latest" "ghcr.io/alexanderwagnerdev/slsmu:latest"
  docker rm -f slsmu 2>/dev/null || true
  docker run -d --name slsmu --restart unless-stopped \
    -p ${slsmu_port}:3000 \
    -e REACT_APP_BASE_URL="${app_url}" \
    -e REACT_APP_SRT_PLAYER_PORT="${sls_player_port}" \
    -e REACT_APP_SRT_SENDER_PORT="${sls_publisher_port}" \
    -e REACT_APP_SLS_STATS_PORT="${sls_stats_port}" \
    -e REACT_APP_SRTLA_PORT="${srtla_port}" \
    alexanderwagnerdev/slsmu:latest
else
  echo "$srtla_skip_msg"
fi

read -rp "$watchtower_prompt " install_watchtower
install_watchtower=${install_watchtower:-n}
if [[ "$install_watchtower" =~ ^[JjYy] ]]; then
  echo "$watchtower_install_msg"
  docker_pull_fallback "containrrr/watchtower:latest" "ghcr.io/containrrr/watchtower:latest"
  docker rm -f watchtower 2>/dev/null || true
  docker run -d --name watchtower --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:latest --cleanup
else
  echo "$watchtower_skip_msg"
fi

echo "$done_msg"
echo "$restart_msg"
