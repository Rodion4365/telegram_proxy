#!/bin/bash
# Setup script for MTProxy.
# Based on https://github.com/TelegramMessenger/MTProxy
#
# Usage on server:
#   git clone https://github.com/TelegramMessenger/MTProxy /opt/mtproxy
#   cd /opt/mtproxy
#   curl -fsSL https://raw.githubusercontent.com/Rodion4365/telegram_proxy/main/scripts/setup.sh | bash

set -e

DIR="$(pwd)"
CONFIG_DIR="$DIR/config"
ENV_FILE="$DIR/.env"
SCRIPTS_DIR="$DIR/scripts"

echo "[1/6] Downloading docker-compose and update script..."
mkdir -p "$SCRIPTS_DIR" "$CONFIG_DIR"

curl -fsSL https://raw.githubusercontent.com/Rodion4365/telegram_proxy/main/Dockerfile -o "$DIR/Dockerfile"
curl -fsSL https://raw.githubusercontent.com/Rodion4365/telegram_proxy/main/docker-compose.yml -o "$DIR/docker-compose.yml"
curl -fsSL https://raw.githubusercontent.com/Rodion4365/telegram_proxy/main/scripts/update-config.sh -o "$SCRIPTS_DIR/update-config.sh"
chmod +x "$SCRIPTS_DIR/update-config.sh"

echo "[2/6] Downloading Telegram proxy configs..."
curl -s https://core.telegram.org/getProxySecret -o "$CONFIG_DIR/proxy-secret"
curl -s https://core.telegram.org/getProxyConfig -o "$CONFIG_DIR/proxy-multi.conf"

echo "[3/6] Generating secret..."
SECRET=$(head -c 16 /dev/urandom | xxd -ps)
echo "SECRET=$SECRET" > "$ENV_FILE"
echo "       Secret: $SECRET"

echo "[4/6] Building Docker image from source..."
docker compose build

echo "[5/6] Starting proxy..."
docker compose up -d

echo "[6/6] Setting up daily cron update at 04:00..."
CRON_JOB="0 4 * * * $SCRIPTS_DIR/update-config.sh >> /var/log/mtproxy-update.log 2>&1"
(crontab -l 2>/dev/null | grep -v "update-config.sh"; echo "$CRON_JOB") | crontab -

SERVER_IP=$(curl -s https://api.ipify.org)
echo ""
echo "====================================="
echo "Proxy is running!"
echo "Secret: $SECRET"
echo ""
echo "Connection link:"
echo "tg://proxy?server=${SERVER_IP}&port=8443&secret=${SECRET}"
echo "====================================="
