###############
# scaleya.com #
###############

#!/bin/bash
sudo add-apt-repository ppa:greaterfire/trojan -y
apt-get update
apt install socat -y
apt install trojan -y
apt install nginx -y
service nginx stop
curl https://raw.githubusercontent.com/Neilpang/acme.sh/master/acme.sh > acme.sh&&bash acme.sh --install \--home /etc

read -p "pls input ur domain:" ym
echo "ur domain is $ym"
read -p "pls input ur mm:" mm
echo "ur mm is $mm"
ecc="ecc"

/etc/acme.sh --issue --standalone  -d $ym --keylength ec-256
mkdir -p /etc/letsencrypt/$ym\_ecc
/etc/acme.sh --install-cert -d $ym --ecc \
        --cert-file /etc/letsencrypt/$ym\_ecc/cert.pem \
        --key-file /etc/letsencrypt/$ym\_ecc/private.key \
        --fullchain-file /etc/letsencrypt/$ym\_ecc/fullchain.pem \
        --reloadcmd "sudo systemctl restart nginx.service"


sudo chmod +rx /etc/letsencrypt/$ym\_ecc/*

cat > /etc/trojan/config.json << EOF   
{
    "run_type": "server",
    "local_addr": "::",
    "local_port": 443,
    "remote_addr": "127.0.0.1",
    "remote_port": 80,
    "password": [
        "$mm"
    ],
    "log_level": 1,
    "ssl": {
        "cert": "/etc/letsencrypt/${ym}_${ecc}/cert.pem",
        "key": "/etc/letsencrypt/${ym}_${ecc}/private.key",
        "key_password": "",
        "cipher": "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384",
        "cipher_tls13": "TLS_AES_128_GCM_SHA256:TLS_CHACHA20_POLY1305_SHA256:TLS_AES_256_GCM_SHA384",
        "prefer_server_cipher": true,
        "alpn": [
            "http/1.1"
        ],
        "reuse_session": true,
        "session_ticket": false,
        "session_timeout": 600,
        "plain_http_response": "",
        "curves": "",
        "dhparam": ""
    },
    "tcp": {
        "prefer_ipv4": false,
        "no_delay": true,
        "keep_alive": true,
        "reuse_port": false,
        "fast_open": false,
        "fast_open_qlen": 20
    },
    "mysql": {
        "enabled": false,
        "server_addr": "127.0.0.1",
        "server_port": 3306,
        "database": "trojan",
        "username": "trojan",
        "password": ""
    }
}
EOF

systemctl enable trojan
systemctl start trojan 
#systemctl status trojan 



apt-get install cron -y
#systemctl status cron

echo "0 0 * * * root service trojan restart" >> /etc/crontab
systemctl restart cron