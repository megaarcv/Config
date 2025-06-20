#!/bin/bash

Simple Xray + SSH Auto Installer (Tanpa Cek IP) Domain default: simplevpn.my.id Author: Custom by ChatGPT ========== Konfigurasi Awal ========== 

DOMAIN="simplevpn.my.id" XRAY_PATH=/usr/local/bin/xray XRAY_CONF_DIR=/etc/xray XRAY_CONF=$XRAY_CONF_DIR/config.json UUIDGEN=$(uuidgen)

========== Fungsi Install Xray ========== 

install_xray() { echo -e "\n[INFO] Mengunduh dan menginstal Xray..." mkdir -p $XRAY_CONF_DIR mkdir -p /usr/local/share/xray cd /tmp curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip unzip -o xray.zip install -m 755 xray $XRAY_PATH install -m 644 geoip.dat /usr/local/share/xray/geoip.dat install -m 644 geosite.dat /usr/local/share/xray/geosite.dat

Generate config.json awal dengan Trojan TLS 

cat > $XRAY_CONF << END { "inbounds": [ { "port": 443, "protocol": "trojan", "settings": { "clients": [ { "password": "$UUIDGEN" } ] }, "streamSettings": { "network": "tcp", "security": "tls", "tlsSettings": { "certificates": [ { "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem", "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem" } ] } } } ], "outbounds": [ { "protocol": "freedom" } ] } END

Setup systemd service 

cat > /etc/systemd/system/xray.service << END [Unit] Description=Xray Service After=network.target

[Service] ExecStart=$XRAY_PATH run -config $XRAY_CONF Restart=on-failure

[Install] WantedBy=multi-user.target END

systemctl daemon-reexec systemctl daemon-reload systemctl enable xray systemctl restart xray echo -e "[INFO] Xray berhasil diinstal dan dijalankan." }

========== Fungsi Buat Akun Trojan ========== 

buat_trojan() { echo -ne "Masukkan Nama User: "; read user exp_date=$(date -d "+30 days" +"%Y-%m-%d") uuid=$(uuidgen)

sed -i "/clients":

