FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    git curl build-essential libssl-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
COPY MTProxy-master/ ./

RUN make && ls objs/bin/mtproto-proxy


FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    libssl3 zlib1g curl \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /build/objs/bin/mtproto-proxy /usr/local/bin/mtproto-proxy

RUN mkdir -p /data

WORKDIR /data

EXPOSE 443 8888

ENTRYPOINT ["mtproto-proxy"]
