#!/bin/bash

Simple Xray + SSH Auto Installer (Tanpa Cek IP) Domain default: simplevpn.my.id Author: ChatGPT for custom user request ========== Konfigurasi Awal ========== 

DOMAIN="simplevpn.my.id" XRAY_PATH="/etc/xray" XRAY_BIN="/usr/local/bin/xray" XRAY_SERVICE="/etc/systemd/system/xray.service" XRAY_CONF="$XRAY_PATH/config.json" UUID=$(cat /proc/sys/kernel/random/uuid)

========== Update & Install Tools ========== 

echo "[+] Update dan install dependensi..." apt update -y && apt upgrade -y apt install -y curl socat cron bash unzip wget screen net-tools jq

========== Install SSL Cert ========== 

echo "[+] Mendapatkan sertifikat SSL dari Let's Encrypt..." systemctl stop nginx 2>/dev/null mkdir -p /etc/letsencrypt/live/$DOMAIN certbot certonly --standalone --noninteractive --register-unsafely-without-email --agree-tos -d $DOMAIN

========== Install Xray ========== 

echo "[+] Mengunduh dan menginstal Xray..." mkdir -p $XRAY_PATH mkdir -p /usr/local/share/xray cd /tmp curl -L -o xray.zip https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip unzip xray.zip install -m 755 xray $XRAY_BIN install -m 755 geo* /usr/local/share/xray/

========== Konfigurasi Xray (Trojan saja sebagai contoh) ========== 

echo "[+] Membuat konfigurasi Xray..." cat > $XRAY_CONF << END { "inbounds": [ { "port": 443, "protocol": "trojan", "settings": { "clients": [ { "password": "$UUID" } ] }, "streamSettings": { "network": "tcp", "security": "tls", "tlsSettings": { "certificates": [ { "certificateFile": "/etc/letsencrypt/live/$DOMAIN/fullchain.pem", "keyFile": "/etc/letsencrypt/live/$DOMAIN/privkey.pem" } ] } } } ], "outbounds": [ { "protocol": "freedom" } ] } END

========== Buat Service Systemd ========== 

echo "[+] Membuat service systemd untuk Xray..." cat > $XRAY_SERVICE << END [Unit] Description=Xray Service After=network.target nss-lookup.target

[Service] User=root ExecStart=$XRAY_BIN run -config $XRAY_CONF Restart=on-failure

[Install] WantedBy=multi-user.target END

========== Aktifkan & Jalankan ========== 

chmod +x $XRAY_BIN systemctl daemon-reexec systemctl daemon-reload systemctl enable xray systemctl restart xray

========== Output Akhir ========== 

echo "" echo "======================" echo "Installasi selesai!" echo "UUID : $UUID" echo "Trojan : trojan://$UUID@$DOMAIN:443" echo "======================" echo ""

Tambahkan menu (sementara dummy) 

echo '#!/bin/bash echo "===== MENU =====" echo "1. Buat Akun VMess/VLESS/Trojan" echo "2. Hapus Akun" echo "3. Lihat Log" echo "4. Keluar"' > /usr/bin/menu chmod +x /usr/bin/menu

