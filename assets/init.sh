#!/usr/bin/env bash

iptables_rules_docker() {

    # private ip ranges are not intercepted
    
    # Ignore LANs and some other reserved addresses.
    for no_proxy_url in $(cat /app/noproxy.txt | grep -v '#')
    do
        iptables -t nat -$1 PREROUTING -i docker0 -d ${no_proxy_url} -j RETURN 2>/dev/null
    done

    iptables -t nat -$1 PREROUTING -p tcp --dport 80   -i docker0 -j REDIRECT --to 12345 2>/dev/null
    iptables -t nat -$1 PREROUTING -p tcp --dport 8080 -i docker0 -j REDIRECT --to 12345 2>/dev/null
    iptables -t nat -$1 PREROUTING -p tcp --dport 443  -i docker0 -j REDIRECT --to 12346 2>/dev/null
}


iptables_rules_other() {

    MODE=$1

    # Ignore LANs and some other reserved addresses.
    for no_proxy_url in $(cat /app/noproxy.txt | grep -v '#')
    do
        iptables -t nat -${MODE} PREROUTING ! -i docker0 -d ${no_proxy_url} -j RETURN 2>/dev/null
        iptables -t nat -${MODE} OUTPUT -d ${no_proxy_url} -p tcp  -j RETURN 2>/dev/null
    done

    iptables -t nat -${MODE} PREROUTING -p tcp ! -i docker0 --dport 80   -j REDIRECT --to 12345 2>/dev/null
    iptables -t nat -${MODE} PREROUTING -p tcp ! -i docker0 --dport 8080 -j REDIRECT --to 12345 2>/dev/null
    iptables -t nat -${MODE} PREROUTING -p tcp ! -i docker0 --dport 443  -j REDIRECT --to 12346 2>/dev/null 

    iptables -t nat -${MODE} OUTPUT -d $(parse_ip $http_proxy) -p tcp  -j RETURN 2>/dev/null
    # HTTP and HTTPS
    iptables -t nat -${MODE} OUTPUT -p tcp --dport 80 -j REDIRECT --to-ports 12345 2>/dev/null
    iptables -t nat -${MODE} OUTPUT -p tcp --dport 443 -j REDIRECT --to-ports 12346 2>/dev/null
    # Any other port 
    iptables -t nat -${MODE} OUTPUT -p tcp --dport 22 -j REDIRECT --to-ports 12347 2>/dev/null
    iptables -t nat -${MODE} OUTPUT -p tcp -j REDIRECT --to-ports 12346 2>/dev/null

}

iptables_rules(){
    iptables_rules_docker $1
    iptables_rules_other $1
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
    append_redsocks_conf "http-relay" $ip $port "12345"

    if [ -z "$https_proxy" ]; then
        https_proxy="$http_proxy"
    fi

    ip=$(parse_ip $https_proxy)
    port=$(parse_port $https_proxy)
    append_redsocks_conf "http-connect" $ip $port "12346"
    append_redsocks_conf "socks5" $ip $port "12347"

    iptables_rules A
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
