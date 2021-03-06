#!/bin/bash

# Stop byebyeproxy

confPath=${HOME}/.byebyeproxy

echo "disabling byebyeproxy"

docker stop "$(docker ps --filter='ancestor=ftorto/byebyeproxy' -q)" >/dev/null 2>&1
docker stop byebyeproxy > /dev/null 2>&1
docker rm byebyeproxy
docker run -it --net=host --privileged -d \
  -v ${confPath}:/app/config \
  "ftorto/byebyeproxy:${1:-latest}" stop > /dev/null 2>&1 && echo "byebyeproxy disabled"
  
if [ "$(id -u)" == "0" ]; then
   iptables-save | wc -l
fi

