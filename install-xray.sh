#!/bin/bash
# Simple Xray + Trojan Installer (Tanpa Cek IP)
# Domain default: simplevpn.my.id

# ========== Konfigurasi Awal ==========
DOMAIN="simplevpn.my.id"
UUID=$(cat /proc/sys/kernel/random/uuid)
XRAY_PATH="/usr/local/bin/xray"
XRAY_CONF_DIR="/etc/xray"
XRAY_LOG_DIR="/var/log/xray"
XRAY_SERVICE="/etc/systemd/system/xray.service"

# ========== Install Xray ==========
echo "Mengunduh Xray..."
mkdir -p /tmp/xray && cd /tmp/xray
curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
unzip xray.zip
install -m 755 xray "$XRAY_PATH"
mkdir -p /usr/local/share/xray
install -m 644 geoip.dat /usr/local/share/xray/
install -m 644 geosite.dat /usr/local/share/xray/

# ========== Generate Sertifikat SSL ==========
echo "Memasang SSL Let's Encrypt..."
apt install -y socat cron curl unzip nginx certbot
systemctl stop nginx
certbot certonly --standalone --register-unsafely-without-email --agree-tos -d $DOMAIN

# ========== Buat Config Xray ==========
mkdir -p $XRAY_CONF_DIR
cat > $XRAY_CONF_DIR/config.json <<EOF
{
  "log": {
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log",
    "loglevel": "info"
  },
  "inbounds": [
    {
      "port": 443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$UUID"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem"
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom"
    }
  ]
}
EOF

# ========== Buat Service Xray ==========
mkdir -p $XRAY_LOG_DIR
cat > $XRAY_SERVICE <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=$XRAY_PATH run -config $XRAY_CONF_DIR/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable xray
systemctl restart xray

# ========== Output ==========
clear
echo "✅ Xray + Trojan berhasil terinstal!"
echo "=============================="
echo "Domain     : $DOMAIN"
echo "Port       : 443"
echo "UUID       : $UUID"
echo "Protocol   : trojan"
echo "Link       : trojan://$UUID@$DOMAIN:443"
echo "=============================="
