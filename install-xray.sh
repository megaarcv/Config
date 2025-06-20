#!/bin/bash
# Simple Xray + SSH Auto Installer (Tanpa Cek IP)
# Domain default: simplevpn.my.id

domain="simplevpn.my.id"

echo -e "\n========== Setting Awal =========="
echo "Domain: $domain"

echo "🛠️ Menginstall dependensi..."
apt update -y
apt install -y curl wget unzip socat netcat cron bash-completion

echo "📥 Menginstall Xray Core..."
mkdir -p /etc/xray /usr/local/share/xray
cd /tmp
wget https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip -O xray.zip
unzip -o xray.zip
install -m 755 xray /usr/local/bin/xray
install -m 644 geo* /usr/local/share/xray/

echo "📄 Membuat sertifikat SSL (Let's Encrypt)..."
systemctl stop nginx 2>/dev/null
apt install -y certbot
certbot certonly --standalone --noninteractive --agree-tos -m admin@$domain -d $domain
mkdir -p /etc/letsencrypt/live/$domain

echo "⚙️ Membuat konfigurasi Xray Trojan TLS..."
cat <<EOF > /etc/xray/config.json
{
  "inbounds": [
    {
      "port": 443,
      "protocol": "trojan",
      "settings": {
        "clients": [
          {
            "password": "$(uuidgen)"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/etc/letsencrypt/live/$domain/fullchain.pem",
              "keyFile": "/etc/letsencrypt/live/$domain/privkey.pem"
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

echo "🔧 Membuat systemd service untuk Xray..."
cat <<EOF > /etc/systemd/system/xray.service
[Unit]
Description=Xray Service
After=network.target nss-lookup.target

[Service]
ExecStart=/usr/local/bin/xray run -config /etc/xray/config.json
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl enable xray
systemctl start xray

echo "📦 Menyiapkan menu interaktif..."
cat <<'EOF' > /usr/bin/menu
#!/bin/bash
clear
echo "========= MENU XRAY VPN ========="
echo "1. Tambah Akun Trojan"
echo "2. Lihat Config Aktif"
echo "3. Restart Xray"
echo "4. Keluar"
echo "================================="
read -p "Pilih opsi [1-4]: " opt
case $opt in
  1)
    read -p "Username: " user
    uuid=$(uuidgen)
    sed -i "/clients/a \        {\"password\": \"$uuid\"}," /etc/xray/config.json
    systemctl restart xray
    echo -e "\nAkun Trojan berhasil ditambahkan:"
    echo "trojan://$uuid@$domain:443"
    ;;
  2)
    grep password /etc/xray/config.json | cut -d'"' -f4 | while read line; do
      echo "trojan://$line@$domain:443"
    done
    ;;
  3)
    systemctl restart xray && echo "Xray berhasil direstart"
    ;;
  4)
    exit
    ;;
  *)
    echo "Pilihan tidak valid"
    ;;
esac
EOF

chmod +x /usr/bin/menu

echo -e "\n✅ Instalasi selesai! Ketik 'menu' untuk mulai mengelola akun."
