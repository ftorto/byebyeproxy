#!/usr/bin/env bash

configFile=/app/config/config.yml
appliedConfiguration=/app/config/appliedConfig.json

parse_ip() {
  echo "$1" | sed -nE "s/^(http(s)?:\/\/)?(.+):([0-9]+)\/?$/\3/p"
}

parse_port() {
  echo "$1" | sed -nE "s/^(http(s)?:\/\/)?(.+):([0-9]+)\/?$/\4/p"
}

iptables_rules() {

    MODE=${1:A}
    HTTP_RELAY_PORT=$2
    HTTP_CONNECT_PORT=$3
    SOCKS5_PORT=$4

    http_proxy=$(jq -r '.proxy.http' ${appliedConfiguration})
    https_proxy=$(jq -r '.proxy.https' ${appliedConfiguration})
    https_proxy="${https_proxy:-$http_proxy}"
    socks_proxy=$(jq -r '.proxy.socks.url' ${appliedConfiguration})

    # Ignore LANs and some other reserved addresses.
    for no_proxy_url in $(jq -r '.proxy.skip[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} PREROUTING -d "${no_proxy_url}" -j RETURN
    done
    
    for port in $(jq -r '.redirect.httpRelay[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} PREROUTING -p tcp --dport $port   -j REDIRECT --to ${HTTP_RELAY_PORT}
    done

    for port in $(jq -r '.redirect.httpConnect[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} PREROUTING -p tcp --dport $port  -j REDIRECT --to ${HTTP_CONNECT_PORT} 
    done

    for port in $(jq -r '.redirect.socks5[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} PREROUTING -p tcp --dport $port -j REDIRECT --to ${SOCKS5_PORT} 
    done

    iptables -t nat -${MODE} PREROUTING -p tcp -j REDIRECT --to $(jq -r '.redirect.default' ${appliedConfiguration})

    for no_proxy_url in $(jq -r '.proxy.skip[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} OUTPUT -d "${no_proxy_url}" -j RETURN
    done

    iptables -t nat -${MODE} OUTPUT -p tcp -d "$(parse_ip ${http_proxy})" --dport "$(parse_port ${http_proxy})"  -j RETURN
    iptables -t nat -${MODE} OUTPUT -p tcp -d "$(parse_ip ${https_proxy})" --dport "$(parse_port ${https_proxy})"  -j RETURN
    iptables -t nat -${MODE} OUTPUT -p tcp -d "$(parse_ip ${socks_proxy})" --dport "$(parse_port ${socks_proxy})"  -j RETURN


    for port in $(jq -r '.redirect.httpRelay[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} OUTPUT -p tcp --dport $port  -j REDIRECT --to-ports ${HTTP_RELAY_PORT}
    done
    

    for port in $(jq -r '.redirect.httpConnect[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} OUTPUT -p tcp --dport $port -j REDIRECT --to-ports ${HTTP_CONNECT_PORT}
    done

    for port in $(jq -r '.redirect.socks5[]' ${appliedConfiguration})
    do
        iptables -t nat -${MODE} OUTPUT -p tcp --dport $port -j REDIRECT --to-ports ${SOCKS5_PORT} 
    done

    iptables -t nat -${MODE} OUTPUT -p tcp -j REDIRECT --to-ports  $(jq -r '.redirect.default' ${appliedConfiguration})
}

create_redsocks_conf() {
    (cat <<EOF
base {
  log_debug = on;
  log_info = on;
  log = stderr;
  daemon = off;
  user = redsocks;
  group = redsocks;
  redirector = iptables;
} 
EOF
)> /app/redsocks.conf
}

append_redsocks_conf() {
  local type=$1
  local ip=$2
  local port=$3
  local local_port=$4

  if [ -z "${type}" ] || [ -z "${ip}" ] || [ -z "${port}" ] || [ -z "${local_port}" ] ; then
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
EOF
) >> /app/redsocks.conf

    if [[ $type == *"socks5"* ]]
    then 
        echo "  login = \"$(jq -r '.proxy.socks.login' ${appliedConfiguration})\";" >> /app/redsocks.conf
        echo "  password = \"$(jq -r '.proxy.socks.password' ${appliedConfiguration})\";" >> /app/redsocks.conf
    fi
    
    echo "}" >> /app/redsocks.conf
}

stop() {
    echo "Cleaning iptables"

    HTTP_RELAY_PORT=$(jq -r ".ports.httpRelay" ${appliedConfiguration})
    HTTP_CONNECT_PORT=$(jq -r ".ports.httpConnect" ${appliedConfiguration})
    SOCKS5_PORT=$(jq -r ".ports.socks5" ${appliedConfiguration})
    iptables_rules D "${HTTP_RELAY_PORT}" "${HTTP_CONNECT_PORT}" "${SOCKS5_PORT}"

    kill -9 $(cat /tmp/pid)
    pkill redsocks && sleep 1 && rm /tmp/pid
}

start() {
    test ! -e ${configFile} && echo "config file not found" && exit 1

    # Update checksum
    sha256sum ${configFile} > /tmp/config.sha256

    /app/y2j ${configFile} | jq . > ${appliedConfiguration}

    http_proxy=$(jq -r ".proxy.http" ${appliedConfiguration})
    https_proxy=$(jq -r ".proxy.https" ${appliedConfiguration})
    https_proxy="${https_proxy:-$http_proxy}"
    socks_proxy=$(jq -r ".proxy.socks.url" ${appliedConfiguration})

    HTTP_RELAY_PORT=$(jq -r ".ports.httpRelay" ${appliedConfiguration})
    HTTP_CONNECT_PORT=$(jq -r ".ports.httpConnect" ${appliedConfiguration})
    SOCKS5_PORT=$(jq -r ".ports.socks5" ${appliedConfiguration})

    if [ -z "${http_proxy}" ]; then
        echo "No http_proxy set. Exiting"
        exit 1
    fi

    create_redsocks_conf

    ip=$(parse_ip "${http_proxy}")
    port=$(parse_port "${http_proxy}")
    append_redsocks_conf "http-relay" "${ip}" "${port}" "${HTTP_RELAY_PORT}"

    ip=$(parse_ip "${https_proxy}")
    port=$(parse_port "${https_proxy}")
    append_redsocks_conf "http-connect" "${ip}" "${port}" "${HTTP_CONNECT_PORT}"

    socks_ip=$(parse_ip "${socks_proxy}")
    socks_port=$(parse_port "${socks_proxy}")
    append_redsocks_conf "socks5" "${socks_ip}" "${socks_port}" "${SOCKS5_PORT}"

    iptables_rules A "${HTTP_RELAY_PORT}" "${HTTP_CONNECT_PORT}" "${SOCKS5_PORT}"

    showConfig
    iptables-save > /app/config/iptables-save
    cp /app/redsocks.conf /app/config/appliedRedsocksConfiguration.conf

    redsocks -c /app/redsocks.conf -p /tmp/pid &
}

showConfig(){

    echo "---"
    cat /app/redsocks.conf
    echo "---"
    cat ${appliedConfiguration} | jq .
    echo
    echo "---"
}

main_loop(){
    while true
    do
        # Check config changes
        if ! sha256sum -c /tmp/config.sha256 > /dev/null 2>&1
        then
            echo "RELOADING. Configuration changed !"
            # Checksum has changed, reload
            stop
            start
        fi
        sleep "$(jq -r '.checkInterval' ${appliedConfiguration})"
    done
}

main(){
    main_loop & 
    sleep infinity
}

case "$1" in
    stop )  stop ;;
    start ) main;;
    debug ) showConfig;;
    sh ) /bin/bash;;
    * )     main;;
esac
