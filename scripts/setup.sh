#!/bin/bash
# MTProxy setup script.
# Follows the official build & run guide from:
#   https://github.com/TelegramMessenger/MTProxy
#
# Run on the server as root:
#   bash setup.sh

set -e

INSTALL_DIR="/opt/mtproxy"
DATA_DIR="/etc/mtproxy"
SERVICE_NAME="MTProxy"

# ── 1. Dependencies ─────────────────────────────────────────────────────────
echo "[1/6] Installing dependencies..."
apt-get update -q
apt-get install -y git curl build-essential libssl-dev zlib1g-dev xxd

# ── 2. Clone or update source ────────────────────────────────────────────────
echo "[2/6] Getting source from https://github.com/TelegramMessenger/MTProxy ..."
if [ -d "$INSTALL_DIR/.git" ]; then
    git -C "$INSTALL_DIR" pull origin master
elif [ -d "$INSTALL_DIR" ]; then
    echo "       $INSTALL_DIR exists but is not a git repo — removing and cloning fresh..."
    rm -rf "$INSTALL_DIR"
    git clone https://github.com/TelegramMessenger/MTProxy "$INSTALL_DIR"
else
    git clone https://github.com/TelegramMessenger/MTProxy "$INSTALL_DIR"
fi

# ── 3. Build ─────────────────────────────────────────────────────────────────
echo "[3/6] Building..."
cd "$INSTALL_DIR"
# Fix crash on systems with PID > 65535 (modern Linux allows PIDs up to 4194304)
sed -i '/assert.*0xffff0000/d' common/pid.c
sed -i 's/PID\.pid = p;/PID.pid = p \& 0xffff;/' common/pid.c
make
BINARY="$INSTALL_DIR/objs/bin/mtproto-proxy"

# ── 4. Download Telegram configs ─────────────────────────────────────────────
echo "[4/6] Downloading proxy-secret and proxy-multi.conf from Telegram..."
mkdir -p "$DATA_DIR"
curl -s https://core.telegram.org/getProxySecret  -o "$DATA_DIR/proxy-secret"
curl -s https://core.telegram.org/getProxyConfig  -o "$DATA_DIR/proxy-multi.conf"

# ── 5. Generate secret (keep existing if already set) ────────────────────────
echo "[5/6] Generating secret..."
SECRET_FILE="$DATA_DIR/secret"
if [ -f "$SECRET_FILE" ]; then
    SECRET=$(cat "$SECRET_FILE")
    echo "       Using existing secret: $SECRET"
else
    SECRET=$(head -c 16 /dev/urandom | xxd -ps)
    echo "$SECRET" > "$SECRET_FILE"
    echo "       Generated secret: $SECRET"
fi

# ── 6. Systemd service ───────────────────────────────────────────────────────
echo "[6/6] Creating systemd service /etc/systemd/system/${SERVICE_NAME}.service ..."
cat > "/etc/systemd/system/${SERVICE_NAME}.service" << EOF
[Unit]
Description=MTProxy - Telegram proxy server
After=network.target

[Service]
Type=simple
ExecStart=$BINARY \\
    -u nobody \\
    -p 8888 \\
    -H 443 \\
    -S $SECRET \\
    --aes-pwd $DATA_DIR/proxy-secret $DATA_DIR/proxy-multi.conf \\
    -M 1
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable "$SERVICE_NAME"
systemctl restart "$SERVICE_NAME"

# ── Cron: daily config update at 04:00 ──────────────────────────────────────
CRON_JOB="0 4 * * * $(dirname "$0")/update-config.sh >> /var/log/mtproxy-update.log 2>&1"
(crontab -l 2>/dev/null | grep -v "update-config.sh"; echo "$CRON_JOB") | crontab -

# ── Done ─────────────────────────────────────────────────────────────────────
SERVER_IP=$(curl -s https://api.ipify.org)
echo ""
echo "====================================="
echo "Proxy is running!"
echo "Secret: $SECRET"
echo ""
echo "Stats:  wget -qO- localhost:8888/stats"
echo ""
echo "Connection link:"
echo "tg://proxy?server=${SERVER_IP}&port=443&secret=${SECRET}"
echo "====================================="
