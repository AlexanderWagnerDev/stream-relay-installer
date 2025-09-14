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

function ask() {
  local prompt="$1"
  local default="$2"
  local lang="$3"
  local response

  if [[ "$lang" == "de" ]]; then
    echo -n "$prompt "
  else
    echo -n "$prompt "
  fi
  read -r response
  if [[ -z "$response" ]]; then
    response="$default"
  fi
  echo "$response"
}

function install_docker_debian_ubuntu() {
  echo "$1" | grep -qi "ubuntu"
  local is_ubuntu=$?
  echo "$1" | grep -qi "debian"
  local is_debian=$?

  sudo apt-get update
  sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common

  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

  local codename
  codename=$(lsb_release -cs)
  if [[ $is_debian -eq 0 ]]; then
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list
  else
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $codename stable" | sudo tee /etc/apt/sources.list.d/docker.list
  fi

  sudo apt-get update
  sudo apt-get install -y docker-ce docker-ce-cli containerd.io
  sudo systemctl enable docker
  sudo systemctl start docker
  sudo usermod -aG docker "$USER"
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
  done_msg="Setup abgeschlossen."
  docker_install_msg="Docker Installation wird gestartet..."
  docker_skip_msg="Docker wird nicht installiert."
  rtmp_install_msg="RTMP-Server wird als Docker-Container gestartet..."
  rtmp_skip_msg="RTMP-Server wird nicht installiert."
  srtla_install_msg="SRTLA-Receiver wird als Docker-Container gestartet..."
  srtla_skip_msg="SRTLA-Receiver wird nicht installiert."
  watchtower_install_msg="Watchtower wird als Docker-Container gestartet..."
  watchtower_skip_msg="Watchtower wird nicht installiert."
  restart_msg="Bitte beachten, nach Docker-Installation ist evtl. ein Neustart oder neue Anmeldung notwendig, damit Docker-Gruppenrechte aktiv sind."
else
  docker_prompt="Install Docker? (y/n):"
  rtmp_prompt="Install and start RTMP Server Docker container? (y/n):"
  srtla_prompt="Install and start SRTLA Receiver Docker container? (y/n):"
  watchtower_prompt="Install and start Watchtower container (automatic updates)? (y/n):"
  done_msg="Setup completed."
  docker_install_msg="Starting Docker installation..."
  docker_skip_msg="Skipping Docker installation."
  rtmp_install_msg="Starting RTMP Server Docker container..."
  rtmp_skip_msg="Skipping RTMP Server installation."
  srtla_install_msg="Starting SRTLA Receiver Docker container..."
  srtla_skip_msg="Skipping SRTLA Receiver installation."
  watchtower_install_msg="Starting Watchtower Docker container..."
  watchtower_skip_msg="Skipping Watchtower installation."
  restart_msg="Please note: After Docker installation a reboot or re-login might be necessary to activate Docker group permissions."
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

read -rp "$rtmp_prompt " install_rtmp
install_rtmp=${install_rtmp:-n}
if [[ "$install_rtmp" =~ ^[JjYy] ]]; then
  echo "$rtmp_install_msg"
  docker pull alexanderwagnerdev/rtmp-server:latest
  docker rm -f rtmp-server 2>/dev/null || true
  docker run -d --name rtmp-server --restart unless-stopped -p 8090:80 -p 1935:1935 alexanderwagnerdev/rtmp-server:latest
else
  echo "$rtmp_skip_msg"
fi

read -rp "$srtla_prompt " install_srtla
install_srtla=${install_srtla:-n}
if [[ "$install_srtla" =~ ^[JjYy] ]]; then
  echo "$srtla_install_msg"
  docker pull alexanderwagnerdev/srtla-server:latest 
  docker rm -f srtla-receiver 2>/dev/null || true
  docker run -d --name srtla-receiver --restart unless-stopped -p 5000:5000/udp -p 4000:4000/udp -p 4001:4001/udp -p 8080:8080 alexanderwagnerdev/srtla-server:latest
else
  echo "$srtla_skip_msg"
fi

read -rp "$watchtower_prompt " install_watchtower
install_watchtower=${install_watchtower:-n}
if [[ "$install_watchtower" =~ ^[JjYy] ]]; then
  echo "$watchtower_install_msg"
  docker pull containrrr/watchtower:latest
  docker rm -f watchtower 2>/dev/null || true
  docker run -d --name watchtower --restart unless-stopped -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower:latest --cleanup
else
  echo "$watchtower_skip_msg"
fi

echo "$done_msg"
echo "$restart_msg"
