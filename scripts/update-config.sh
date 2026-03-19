#!/bin/bash
# Daily update of Telegram proxy configuration files.
# Run via cron: 0 4 * * * /home/user/telegram_proxy/scripts/update-config.sh

set -e

DIR="$(cd "$(dirname "$0")/.." && pwd)"
CONFIG_DIR="$DIR/config"

echo "[$(date)] Updating Telegram proxy config..."

curl -s https://core.telegram.org/getProxySecret -o "$CONFIG_DIR/proxy-secret"
curl -s https://core.telegram.org/getProxyConfig -o "$CONFIG_DIR/proxy-multi.conf"

echo "[$(date)] Restarting proxy container..."
cd "$DIR"
docker compose restart mtproto-proxy

echo "[$(date)] Done."
