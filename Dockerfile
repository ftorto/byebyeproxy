FROM debian:wheezy-slim

RUN apt-get update \
    && apt-get install -y redsocks iptables procps psmisc \
    && rm -rf /var/lib/apt/lists/*

COPY assets/* /app/

ENTRYPOINT ["bash", "/app/entry_point.sh"]

