#!/usr/bin/env bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"


echo "Installing toggles directly in network events"
ln -fs $DIR/999-proxy /etc/network/if-up.d/999-proxy
ln -fs $DIR/999-proxy /etc/network/if-down.d/999-proxy

if [[ ! -e /etc/docker/daemon.json ]]
then
read -p "DNS IP: " DNS_IP
cat > /etc/docker/daemon.json <<EOL
{
  "dns": ["${DNS_IP}","8.8.8.8","8.8.4.4"],
  "storage-driver": "overlay2"
}
EOL
else
  echo "Check that /etc/docker/daemon.json contains the correct DNS entry or fix it manually"
  cat /etc/docker/daemon.json
  echo "Press ENTER to continue. Ctrl+C to stop"
  read
fi

nb_containers=$(docker ps -q| wc -l)
if test $nb_containers -gt 0
then
  echo "Docker must be restarted but $nb_containers containers are still running"
  docker ps
  echo "Press ENTER to restart docker. Ctrl+C to stop"
  read
fi

systemctl daemon-reload
systemctl restart docker