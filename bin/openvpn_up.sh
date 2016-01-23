#!/bin/bash

#
# Deluge-openvpn 
#

#
# Openvpn_up.sh - Script runs when the VPN tunnel successfully activated, and enables routing and a few other things for deluge  
#

# IPVPN variable 
IPVPN=$4

CONFIG_PATH='/opt/deluge-openvpn/etc/deluge-openvpn.conf'

# Check if config file is set correctly
CONFIG_SYNTAX="^\s*#|^\s*$|^OVPN_+[a-zA-Z_]+=.*"
if egrep -q -v "${CONFIG_SYNTAX}" "$CONFIG_PATH"; then
  echo "Error parsing config file ${CONFIG_PATH}." >&2
  echo "The following lines in the configfile do not fit the syntax:" >&2
  egrep -vn "${CONFIG_SYNTAX}" "$CONFIG_PATH"
  exit 5
fi
source "${CONFIG_PATH}"

# Setup openvpn routing but only for the vpn table
/usr/sbin/ip route add ${IPVPN%.*}.0/24 dev $1 proto kernel scope link src $4 table vpn 
/usr/sbin/ip route add 128.0.0.0/1 via ${IPVPN%.*}.252 dev $1 table vpn 
/usr/sbin/ip route add ${OVPN_NET_NW} dev ${OVPN_NET_INT} proto kernel scope link src ${OVPN_NET_IP} table vpn ip route add 0.0.0.0/1 via ${IPVPN%.*}.252 dev $1 table vpn 
/usr/sbin/ip route add default via ${OVPN_NET_GW} table vpn 
/usr/sbin/ip rule add from ${IPVPN%.*}.0/24 table vpn 

# Masquerade traffic for both local and vpn traffic
/usr/sbin/iptables -t nat -A POSTROUTING -o ${OVPN_NET_INT} -j MASQUERADE 
/usr/sbin/iptables -t nat -A POSTROUTING -o $1 -j MASQUERADE 

# Allow session continuation traffic 
/usr/sbin/iptables -A INPUT -i $1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# BitTorrent Ports - Optional
#/usr/sbin/iptables -A INPUT -i $1 -p tcp --dport 56881:56889 -j ACCEPT
#/usr/sbin/iptables -A INPUT -i $1 -p udp --dport 56881:56889 -j ACCEPT

# Update VPN IP for Deluge
/usr/bin/sed -i "s/BIND_TO_IP=\".*\"/BIND_TO_IP=\"${IPVPN}\"/" $OVPN_DELUGE
/usr/bin/sed -i "s/VPN_IP=\".*\"/VPN_IP=\"${IPVPN}\"/" $OVPN_S_CHECK

# Restarting deluge service
/usr/bin/systemctl restart deluged.service
