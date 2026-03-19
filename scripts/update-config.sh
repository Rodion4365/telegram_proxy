#!/bin/bash
# Daily update of Telegram proxy config files.
# Source: https://github.com/TelegramMessenger/MTProxy (README: update configs regularly)
#
# Added to cron by setup.sh:
#   0 4 * * * /opt/mtproxy/scripts/update-config.sh >> /var/log/mtproxy-update.log 2>&1

set -e

DATA_DIR="/etc/mtproxy"

echo "[$(date)] Updating proxy-secret and proxy-multi.conf..."
curl -s https://core.telegram.org/getProxySecret  -o "$DATA_DIR/proxy-secret"
curl -s https://core.telegram.org/getProxyConfig  -o "$DATA_DIR/proxy-multi.conf"

echo "[$(date)] Restarting MTProxy service..."
systemctl restart MTProxy

echo "[$(date)] Done."
