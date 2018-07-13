FROM debian:wheezy-slim

RUN apt-get update \
    && apt-get install -y redsocks iptables procps psmisc \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir /app

COPY assets/* /app/

RUN chmod +x /app/entry_point.sh
ENTRYPOINT ["/app/entry_point.sh"]

