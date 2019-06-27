#!/usr/bin/env bash

if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [[ ! -e "${HOME}/.byebyeproxy.conf" ]]
then
cat > "${HOME}/.byebyeproxy.conf" <<EOL
#!/usr/bin/env bash
# Configuration file for byebyeproxy

# HTTP proxy full url
# PROXY_URL_HTTP=http://corporate_proxy.com:3128
PROXY_URL_HTTP=

# HTTPS proxy full URL
# PROXY_URL_HTTPS=http://corporate_proxy.com:3128
PROXY_URL_HTTPS=

# No PROXY
NO_PROXY_URLS=0.0.0.0/8,10.0.0.0/8,127.0.0.0/8,169.254.0.0/16,172.16.0.0/12,192.168.0.0/16,224.0.0.0/4,240.0.0.0/4

# SOCKS
PROXY_SOCKS=
SOCKS_LOGIN=
SOCKS_PASSWORD=

# DNS IP only (format xxx.xxx.xxx.xxx)
# Port 53 is used. Do not specify it
# DNS_IP=corporate_dns_ip
DNS_IP=

EOL
  chown ${SUDO_USER}:${SUDO_USER} "${HOME}/.byebyeproxy.conf"
  chmod 600 "${HOME}/.byebyeproxy.conf"
  echo "Your proxy/DNS settings must be set in the file ${HOME}/.byebyeproxy.conf"
  echo "Please fill the file before continuing"  
  echo "Press ENTER to continue. Ctrl+C to stop"
  read
fi

source "${HOME}/.byebyeproxy.conf"
test -z "$PROXY_URL_HTTP" && echo "PROXY_URL_HTTP not filled in ${HOME}/.byebyeproxy.conf" && exit 1
test -z "$PROXY_URL_HTTPS" && echo "PROXY_URL_HTTPS not filled in ${HOME}/.byebyeproxy.conf" && exit 1
test -z "$DNS_IP" && echo "DNS_IP not filled in ${HOME}/.byebyeproxy.conf" && exit 1

RESTART_NEEDED=1
if [[ ! -e /etc/docker/daemon.json ]]
then
cat > /etc/docker/daemon.json <<EOL
{
  "dns": ["${DNS_IP}","8.8.8.8","8.8.4.4"],
  "storage-driver": "overlay2"
}
EOL
else

  if test "$(jq -c .dns /etc/docker/daemon.json | grep -c "${DNS_IP}")" -eq 0
  then
    echo "Check that /etc/docker/daemon.json contains the correct DNS entry or fix it manually. Content between '----' marks:"
    echo "----"
    cat /etc/docker/daemon.json
    echo "----"

    bkp=$(mktemp)
    cp /etc/docker/daemon.json "$bkp"


    echo "Press ENTER to continue. Ctrl+C to stop"
    read
    diff -q /etc/docker/daemon.json "$bkp" > /dev/null && RESTART_NEEDED=0
  else
    echo "DNS entry found in /etc/docker/daemon.json"
    RESTART_NEEDED=0
  fi
fi

if test $RESTART_NEEDED -eq 1
then
  nb_containers=$(docker ps -q| wc -l)
  if test "$nb_containers" -gt 0
  then
    echo "Docker must be restarted but $nb_containers containers are still running"
    docker ps
  fi

  echo "Press ENTER to restart docker. Ctrl+C to stop"
  read
  echo "Restarting docker"
  systemctl daemon-reload
  systemctl restart docker
  echo "Docker restarted"
else
  echo "Docker doesn't need to be restarted"
fi

# echo "Install pxon/pxoff shortcut"
# ln -fs ${DIR}/on.sh /usr/local/bin/pxon
# ln -fs ${DIR}/off.sh /usr/local/bin/pxoff
