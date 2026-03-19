#!/bin/bash
# Initial setup script for MTProxy.
# Run once on the server: bash scripts/setup.sh

set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$DIR/config"
ENV_FILE="$DIR/.env"

echo "[1/5] Downloading Telegram proxy configs..."
mkdir -p "$CONFIG_DIR"
curl -s https://core.telegram.org/getProxySecret -o "$CONFIG_DIR/proxy-secret"
curl -s https://core.telegram.org/getProxyConfig -o "$CONFIG_DIR/proxy-multi.conf"

echo "[2/5] Generating secret..."
SECRET=$(head -c 16 /dev/urandom | xxd -ps)
echo "SECRET=$SECRET" > "$ENV_FILE"
echo "       Secret: $SECRET"

echo "[3/5] Building Docker image..."
cd "$DIR"
docker compose build

echo "[4/5] Starting proxy..."
docker compose up -d

echo "[5/5] Setting up daily cron update (04:00)..."
CRON_JOB="0 4 * * * $DIR/scripts/update-config.sh >> /var/log/mtproxy-update.log 2>&1"
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
