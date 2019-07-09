#!/bin/bash
# Start byebyeproxy

confPath=${HOME}/.byebyeproxy

if test ! -e ${confPath}/config.yml
then
  echo "You shall fill the file ${HOME}/.byebyeproxy/config.yml first"
  echo "Have a look at config.template.yml"
  mkdir -p ${confPath}
  exit 1
fi

if [ -z "$(docker ps --filter="ancestor=ftorto/byebyeproxy" -q)" ]
then
  docker run -it -d --net=host --privileged \
    --name byebyeproxy \
    -v ${confPath}:/app/config \
    "ftorto/byebyeproxy:${1:-latest}" start #> /dev/null 2>&1 && echo "byebyeproxy enabled"
else
  echo "byebyeproxy already enabled"
fi
