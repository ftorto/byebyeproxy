#!/usr/bin/env bash

# Setup ports
HTTP_RELAY_PORT=22345
HTTP_CONNECT_PORT=22346
SOCKS5_PORT=22347

iptables_rules() {

    MODE=$1

    # Ignore LANs and some other reserved addresses.
    for no_proxy_url in $(cat /app/noproxy.txt | grep -v '#')
    do
        iptables -t nat -${MODE} PREROUTING -d ${no_proxy_url} -j RETURN 2>/dev/null
    done
    
    iptables -t nat -${MODE} PREROUTING -p tcp --dport 80   -j REDIRECT --to ${HTTP_RELAY_PORT} 2>/dev/null
    iptables -t nat -${MODE} PREROUTING -p tcp -j REDIRECT --to ${HTTP_CONNECT_PORT} 

    iptables -t nat -${MODE} OUTPUT -p tcp -d $(parse_ip $https_proxy) --dport $(parse_port $https_proxy)  -j RETURN
    iptables -t nat -${MODE} OUTPUT -p tcp --dport 80  -j REDIRECT --to-ports 22345
    iptables -t nat -${MODE} OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 22346
}

append_redsocks_conf() {
  local type=$1
  local ip=$2
  local port=$3
  local local_port=$4
  if [ -z "$type" -o -z "$ip" -o -z "$port" -o -z "$local_port" ] ; then
    echo missing required parameter >&2
    exit 1
  fi
  (cat <<EOF
redsocks {
  type = $type;
  ip = $ip;
  port = $port;
  local_ip = 0.0.0.0;
  local_port = $local_port;
}
EOF
) >> /app/redsocks.conf
}

parse_ip() {
  echo $1 | sed -nE "s/^(http(s)?:\/\/)?(.+):([0-9]+)\/?$/\3/p"
}

parse_port() {
  echo $1 | sed -nE "s/^(http(s)?:\/\/)?(.+):([0-9]+)\/?$/\4/p"
}

stop() {
    echo "Cleaning iptables"
    iptables_rules D
    pkill -9 redsocks
}

interrupted () {
    echo 'Interrupted, cleaning up...'
    trap - INT
    stop
    kill -INT $$
}

run() {
    trap interrupted INT
    trap terminated TERM

    if [ -z "$http_proxy" ]; then
        echo "No http_proxy set. Exiting"
        exit 1
    fi

    ip=$(parse_ip $http_proxy)
    port=$(parse_port $http_proxy)
    append_redsocks_conf "http-relay" $ip $port "${HTTP_RELAY_PORT}"

    if [ -z "$https_proxy" ]; then
        https_proxy="$http_proxy"
    fi

    ip=$(parse_ip $https_proxy)
    port=$(parse_port $https_proxy)
    append_redsocks_conf "http-connect" $ip $port "${HTTP_CONNECT_PORT}"
    append_redsocks_conf "socks5" $ip $port "${SOCKS5_PORT}"

    iptables_rules A

    echo "Ports setup :"
    echo "HTTP_RELAY_PORT=${HTTP_RELAY_PORT}"
    echo "HTTP_CONNECT_PORT=${HTTP_CONNECT_PORT}"
    echo "SOCKS5_PORT=${SOCKS5_PORT}"
    
    redsocks -c /app/redsocks.conf
}


terminated () {
    echo 'Terminated, cleaning up...'
    trap - TERM
    stop
    kill -TERM $$
}

case "$1" in
    stop )  stop ;;
    * )     run ;;
esac
