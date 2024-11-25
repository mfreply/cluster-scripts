#!/bin/bash
# Run in VPS to generate another client for the wg VPN

CLIENT_IP=10.142.1.$(( 1 + $(sudo cat /etc/wireguard/wg0.conf | sed -En 's#AllowedIPs.*\.([0-9]+)/[0-9]+#\1#p' | sort -r | head -1) ))

read -p "Add new client with local IP ${CLIENT_IP}? [y/n] " -n 1 -r ans
echo ''
test $ans != 'y' && exit 0

PRIVATE_KEY=$(wg genkey)
PUBLIC_KEY=$(wg pubkey <<< ${PRIVATE_KEY})
SERVER_KEY=$(sudo cat /etc/wireguard/publickey)

tee client.conf << EOF
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${CLIENT_IP}/24
DNS = 10.142.1.1

[Peer]
PublicKey = ${SERVER_KEY}
Endpoint = 1.2.3.4:51820
AllowedIPs = 10.142.1.0/24
EOF

# generate qrcode
qrencode -t ansiutf8 < client.conf

sudo tee -a /etc/wireguard/wg0.conf << EOF
# ${1}
[Peer]
PublicKey = ${PUBLIC_KEY}
AllowedIPs = ${CLIENT_IP}/32

EOF
