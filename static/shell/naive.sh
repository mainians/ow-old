# user-agent https://www.whatismybrowser.com/guides/the-latest-user-agent/chrome
# Scaleya自用的naiveproxy安装脚本
# 只是适用于Ubuntu高版本

#! /bin/bash


sudo apt update 
apt -y install libnss3


repos="klzgrad/naiveproxy"


latest_version=$(curl \
-H "Accept: application/vnd.github.v3+json" \
-H "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/83.0.4103.61 Safari/537.36" \
-s "https://api.github.com/repos/$repos/tags" \
--connect-timeout 10 | grep  -m1 "name" | cut -d\" -f4)

if [[ $latest_version != v* ]]
then
  latest_version=v$latest_version
fi

cat <<EOF
$(echo -e "\e[31m$latest_version")
$(echo -e "\e[36m$latest_version")
EOF

curl https://getcaddy.com | bash -s personal http.forwardproxy

rm -rf /etc/caddy && rm -f /etc/systemd/system/caddy.service
mkdir -p /etc/caddy 

cat <<EOF > /etc/caddy/Caddyfile
wp.scaleya.xyz
root /var/www/html
tls scaleya.com@gmail.com
forwardproxy {
  basicauth admin admin
  hide_ip
  hide_via
  probe_resistance secret.localhost
  upstream http://127.0.0.1:8080
}
EOF

cat <<EOF > /etc/systemd/system/caddy.service
[Unit]
Description=Caddy
Documentation=https://caddyserver.com/docs/
After=network.target

[Service]
User=root
ExecStart=/usr/local/bin/caddy -agree --conf /etc/caddy/Caddyfile
ExecReload=/usr/local/bin/caddy reload --conf /etc/caddy/Caddyfile


[Install]
WantedBy=multi-user.target
EOF


systemctl daemon-reload
systemctl enable caddy
systemctl stop caddy
systemctl start caddy
systemctl status caddy


rm -rf /etc/NaiveProxy && rm -f /etc/systemd/system/naive.service
mkdir -p /etc/NaiveProxy && cd /etc/NaiveProxy

wget -O /etc/NaiveProxy/naive.tar.xz https://github.com/klzgrad/naiveproxy/releases/download/$latest_version/naiveproxy-$latest_version-linux-x64.tar.xz 

tar -xf naive.tar.xz && rm naive.tar.xz && cp naiveproxy*/* . && rm -r naiveproxy-*

cd 

cat <<EOF > /etc/systemd/system/naive.service
[Unit]
Description=NaiveProxy
Documentation=https://github.com/klzgrad/naiveproxy
After=network.target

[Service]
User=root
ExecStart=/etc/NaiveProxy/naive  /etc/NaiveProxy/config.json
TimeoutStopSec=5s
LimitNOFILE=1048576
LimitNPROC=512
PrivateTmp=true
ProtectSystem=full
AmbientCapabilities=CAP_NET_BIND_SERVICE

[Install]
WantedBy=multi-user.target
EOF

cat <<EOF > /etc/NaiveProxy/config.json
{
  "listen": "http://127.0.0.1:8080",
  "padding": true
}
EOF


systemctl daemon-reload
systemctl enable naive
systemctl stop naive
systemctl start naive
systemctl status naive