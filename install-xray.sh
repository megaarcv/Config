#!/bin/bash
# Simple Xray + SSH Auto Installer (Tanpa Cek IP)
# Domain default: simplevpn.my.id
# Author: ChatGPT custom request

DOMAIN="simplevpn.my.id"
XRAY_BIN="/usr/local/bin/xray"
XRAY_CONFIG="/etc/xray/config.json"
XRAY_SERVICE="/etc/systemd/system/xray.service"
XRAY_DIR="/etc/xray"
SHARE_DIR="/usr/local/share/xray"

install_xray() {
    echo "Mengunduh Xray Core..."
    mkdir -p $SHARE_DIR
    mkdir -p $XRAY_DIR
    cd /tmp && curl -LO https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip
    unzip -o Xray-linux-64.zip && install -m 755 xray $XRAY_BIN
    install -m 644 geoip.dat $SHARE_DIR/geoip.dat
    install -m 644 geosite.dat $SHARE_DIR/geosite.dat

    echo "Membuat file konfigurasi awal..."
    UUID=$(uuidgen)
    cat > $XRAY_CONFIG <<EOF
{
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

    echo "Membuat service systemd untuk Xray..."
    cat > $XRAY_SERVICE <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
Type=simple
ExecStart=$XRAY_BIN run -config $XRAY_CONFIG
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl enable xray
    systemctl start xray

    echo "Xray berhasil diinstal dan dijalankan!"
    echo "UUID: $UUID"
    echo "Link TLS: trojan://$UUID@$DOMAIN:443"
}

menu() {
    clear
    echo -e "=============================="
    echo -e "     AUTO XRAY INSTALLER     "
    echo -e "=============================="
    echo -e "1. Install Xray Trojan TLS"
    echo -e "0. Exit"
    echo -n "Pilih opsi: "
    read pilih
    case $pilih in
        1) install_xray ;;
        0) exit ;;
        *) echo "Pilihan tidak valid."; sleep 1; menu ;;
    esac
}

menu
