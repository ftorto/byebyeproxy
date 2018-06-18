FROM debian:wheezy-slim

RUN apt-get update \
    && apt-get install -y redsocks iptables procps psmisc \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir /app

ADD assets/noproxy.txt /app/noproxy.txt
ADD assets/redsocks.conf /app/redsocks.conf
ADD assets/init.sh /app/init.sh

RUN chmod +x /app/init.sh
CMD sh /app/init.sh

