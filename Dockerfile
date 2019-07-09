FROM debian:stable-slim

RUN apt-get update \
    && apt-get upgrade -qy \
    && apt-get install -qy redsocks iptables procps psmisc jq\
    && rm -rf /var/lib/apt/lists/*

# Add yq to process config.yml to json file
ADD https://github.com/wakeful/yaml2json/releases/download/0.3.2/yaml2json-linux-amd64 /app/y2j
RUN chmod 555 /app/y2j

COPY assets/entry_point.sh /app/entry_point.sh

ENTRYPOINT ["bash", "/app/entry_point.sh"]
