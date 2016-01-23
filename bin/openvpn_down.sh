#!/bin/sh 

#
# Deluge-openvpn
#

#
# Openvpn_down.sh - Script runs when the VPN tunnel has been broken down, and cleans up the vpn routing table and firewall rules
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

#Kill checkvpn process and stop deluged service
/usr/bin/killall openvpn_check
/usr/bin/systemctl stop deluged.service 

# Remove masquerading for eth0 and tun0
/usr/sbin/iptables -D POSTROUTING -t nat -o $OVPN_NET_INT -j MASQUERADE
/usr/sbin/iptables -D POSTROUTING -t nat -o $1 -j MASQUERADE

# Remove session continuation traffic 
/usr/sbin/iptables -D INPUT -i $1 -m state --state RELATED,ESTABLISHED -j ACCEPT

# Remove BitTorrent Ports - Optional
#/usr/sbin/iptables -D INPUT -i $1 -p tcp --dport 56881:56889 -j ACCEPT
#/usr/sbin/iptables -D INPUT -i $1 -p udp --dport 56881:56889 -j ACCEPT

# Remove rule for tun0 IP address
/usr/sbin/ip rule del from ${IPVPN%.*}.0/24 table vpn

# Flush vpn table
/usr/sbin/ip route flush table vpn
