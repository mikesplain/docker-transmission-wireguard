FROM --platform=$TARGETPLATFORM alpine:3.17.1 as base

LABEL maintainer "Mike Splain <mike.splain@gmail.com>"
LABEL org.label-schema.url=https://github.com/mikesplain/docker-transmission-wireguard
LABEL org.label-schema.name=transmission-wireguard
LABEL org.opencontainers.image.source="https://github.com/mikesplain/docker-transmission-wireguard"

ENV DOCKERIZE_VERSION=v0.6.1 \
    S6_VERSION=v2.2.0.3

FROM base as base-amd64

ENV DOCKERIZE_FILENAME dockerize-alpine-linux-amd64-${DOCKERIZE_VERSION}.tar.gz
ENV DOCKERIZE_URL https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/${DOCKERIZE_FILENAME}
ENV S6_FILENAME s6-overlay-amd64.tar.gz
ENV S6_URL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_FILENAME}

FROM base as base-armv6

ENV DOCKERIZE_FILENAME dockerize-linux-armel-${DOCKERIZE_VERSION}.tar.gz
ENV DOCKERIZE_URL https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/${DOCKERIZE_FILENAME}
ENV S6_FILENAME s6-overlay-arm.tar.gz
ENV S6_URL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_FILENAME}

FROM base as base-armv7

ENV DOCKERIZE_FILENAME dockerize-linux-armhf-${DOCKERIZE_VERSION}.tar.gz
ENV DOCKERIZE_URL https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/${DOCKERIZE_FILENAME}
ENV S6_FILENAME s6-overlay-armhf.tar.gz
ENV S6_URL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_FILENAME}

FROM base as base-arm64

ENV DOCKERIZE_FILENAME dockerize-linux-armhf-${DOCKERIZE_VERSION}.tar.gz
ENV DOCKERIZE_URL https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/${DOCKERIZE_FILENAME}
ENV S6_FILENAME s6-overlay-aarch64.tar.gz
ENV S6_URL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_FILENAME}

FROM base as base-386

ENV DOCKERIZE_FILENAME dockerize-linux-386-${DOCKERIZE_VERSION}.tar.gz
ENV DOCKERIZE_URL https://github.com/jwilder/dockerize/releases/download/${DOCKERIZE_VERSION}/${DOCKERIZE_FILENAME}
ENV S6_FILENAME s6-overlay-x86.tar.gz
ENV S6_URL https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/${S6_FILENAME}


ARG TARGETARCH
ARG TARGETVARIANT
FROM base-${TARGETARCH}${TARGETVARIANT}

ADD ${S6_URL} /

ADD ${DOCKERIZE_URL} /

ADD https://github.com/Secretmapper/combustion/archive/release.zip /

RUN tar xzvf ${S6_FILENAME} \
    && rm ${S6_FILENAME} \
    && tar -C /usr/local/bin -xzvf ${DOCKERIZE_FILENAME} \
    && rm ${DOCKERIZE_FILENAME} \
    && apk add --no-cache --update wireguard-tools transmission-daemon unzip curl git wget jq procps transmission-cli \
    && rm -rf /usr/share/transmission/web/* \
    && unzip /release.zip \
    && ls /combustion-release \
    && mv /combustion-release/* /usr/share/transmission/web/ \
    && rm /release.zip \
    && rmdir /combustion-release  \
    && adduser --home /config --shell /bin/false --disabled-password twg_user \
    && sed -i '/net.ipv4.conf.all.src_valid_mark=1/d' /usr/bin/wg-quick \
    && wget https://github.com/pia-foss/manual-connections/archive/v2.0.0.zip \
    && unzip /v2.0.0.zip \
    && mv manual-connections-2.0.0 /etc/pia \
    && rm -rf /v2.0.0.zip \
    && sed -i 's/sysctl -n net.ipv6.conf.all.disable_ipv6/echo 1/g' /etc/pia/connect_to_wireguard_with_token.sh \
    && sed -i 's/sleep 900/echo -n \$port > \/etc\/pia\/port \&\& sleep 900/g' /etc/pia/port_forwarding.sh \
    && echo -n 9090 > /etc/pia/port

ADD https://raw.githubusercontent.com/SebDanielsson/dark-combustion/master/main.77f9cffc.css /usr/share/transmission/web/

COPY root/ .

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    GLOBAL_APPLY_PERMISSIONS=true \
    TRANSMISSION_ALT_SPEED_DOWN=50 \
    TRANSMISSION_ALT_SPEED_ENABLED=false \
    TRANSMISSION_ALT_SPEED_TIME_BEGIN=540 \
    TRANSMISSION_ALT_SPEED_TIME_DAY=127 \
    TRANSMISSION_ALT_SPEED_TIME_ENABLED=false \
    TRANSMISSION_ALT_SPEED_TIME_END=1020 \
    TRANSMISSION_ALT_SPEED_UP=50 \
    TRANSMISSION_BIND_ADDRESS_IPV4=0.0.0.0 \
    TRANSMISSION_BIND_ADDRESS_IPV6=:: \
    TRANSMISSION_BLOCKLIST_ENABLED=false \
    TRANSMISSION_BLOCKLIST_URL=http://www.example.com/blocklist \
    TRANSMISSION_CACHE_SIZE_MB=4 \
    TRANSMISSION_DHT_ENABLED=true \
    TRANSMISSION_DOWNLOAD_DIR=/data/completed \
    TRANSMISSION_DOWNLOAD_QUEUE_ENABLED=true \
    TRANSMISSION_DOWNLOAD_QUEUE_SIZE=5 \
    TRANSMISSION_ENCRYPTION=1 \
    TRANSMISSION_IDLE_SEEDING_LIMIT=30 \
    TRANSMISSION_IDLE_SEEDING_LIMIT_ENABLED=false \
    TRANSMISSION_INCOMPLETE_DIR=/data/incomplete \
    TRANSMISSION_INCOMPLETE_DIR_ENABLED=true \
    TRANSMISSION_LPD_ENABLED=false \
    TRANSMISSION_MAX_PEERS_GLOBAL=200 \
    TRANSMISSION_MESSAGE_LEVEL=2 \
    TRANSMISSION_PEER_CONGESTION_ALGORITHM= \
    TRANSMISSION_PEER_ID_TTL_HOURS=6 \
    TRANSMISSION_PEER_LIMIT_GLOBAL=200 \
    TRANSMISSION_PEER_LIMIT_PER_TORRENT=50 \
    TRANSMISSION_PEER_PORT=51413 \
    TRANSMISSION_PEER_PORT_RANDOM_HIGH=65535 \
    TRANSMISSION_PEER_PORT_RANDOM_LOW=49152 \
    TRANSMISSION_PEER_PORT_RANDOM_ON_START=false \
    TRANSMISSION_PEER_SOCKET_TOS=default \
    TRANSMISSION_PEX_ENABLED=true \
    TRANSMISSION_PORT_FORWARDING_ENABLED=false \
    TRANSMISSION_PREALLOCATION=1 \
    TRANSMISSION_PREFETCH_ENABLED=1 \
    TRANSMISSION_QUEUE_STALLED_ENABLED=true \
    TRANSMISSION_QUEUE_STALLED_MINUTES=30 \
    TRANSMISSION_RATIO_LIMIT=2 \
    TRANSMISSION_RATIO_LIMIT_ENABLED=false \
    TRANSMISSION_RENAME_PARTIAL_FILES=true \
    TRANSMISSION_RPC_AUTHENTICATION_REQUIRED=false \
    TRANSMISSION_RPC_BIND_ADDRESS=0.0.0.0 \
    TRANSMISSION_RPC_ENABLED=true \
    TRANSMISSION_RPC_HOST_WHITELIST= \
    TRANSMISSION_RPC_HOST_WHITELIST_ENABLED=false \
    TRANSMISSION_RPC_PASSWORD=password \
    TRANSMISSION_RPC_PORT=9091 \
    TRANSMISSION_RPC_URL=/transmission/ \
    TRANSMISSION_RPC_USERNAME=username \
    TRANSMISSION_RPC_WHITELIST=127.0.0.1 \
    TRANSMISSION_RPC_WHITELIST_ENABLED=false \
    TRANSMISSION_SCRAPE_PAUSED_TORRENTS_ENABLED=true \
    TRANSMISSION_SCRIPT_TORRENT_DONE_ENABLED=false \
    TRANSMISSION_SCRIPT_TORRENT_DONE_FILENAME= \
    TRANSMISSION_SEED_QUEUE_ENABLED=false \
    TRANSMISSION_SEED_QUEUE_SIZE=10 \
    TRANSMISSION_SPEED_LIMIT_DOWN=100 \
    TRANSMISSION_SPEED_LIMIT_DOWN_ENABLED=false \
    TRANSMISSION_SPEED_LIMIT_UP=100 \
    TRANSMISSION_SPEED_LIMIT_UP_ENABLED=false \
    TRANSMISSION_START_ADDED_TORRENTS=true \
    TRANSMISSION_TRASH_ORIGINAL_TORRENT_FILES=false \
    TRANSMISSION_UMASK=2 \
    TRANSMISSION_UPLOAD_SLOTS_PER_TORRENT=14 \
    TRANSMISSION_UTP_ENABLED=false \
    TRANSMISSION_WATCH_DIR=/data/watch \
    TRANSMISSION_WATCH_DIR_ENABLED=true \
    TRANSMISSION_HOME=/data/transmission-home \
    TRANSMISSION_WATCH_DIR_FORCE_GENERIC=false \
    PUID= \
    PGID= \
    INTERFACE=pia \
    KILLSWITCH= \
    OVERWRITE_CONFIGURATION=

ENTRYPOINT ["/init"]
