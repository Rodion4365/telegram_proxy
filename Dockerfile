FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y \
    git curl build-essential libssl-dev zlib1g-dev xxd \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN git clone https://github.com/TelegramMessenger/MTProxy.git .

# Fix crash on systems with PID > 65535 (modern Linux allows PIDs up to 4194304)
RUN sed -i '/assert.*0xffff0000/d' common/pid.c && \
    sed -i 's/PID\.pid = p;/PID.pid = p \& 0xffff;/' common/pid.c

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
