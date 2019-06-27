FROM debian:stable-slim

RUN apt-get update \
    && apt-get upgrade -qy \
    && apt-get install -qy redsocks iptables procps psmisc \
    && rm -rf /var/lib/apt/lists/*

COPY assets/* /app/

ENTRYPOINT ["bash", "/app/entry_point.sh"]

