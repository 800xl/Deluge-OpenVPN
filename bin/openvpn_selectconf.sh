#!/bin/bash

#
# Deluge-openvpn
#

#
# Openvpn_selectconfig - When we find multiple .ovpn files in /opt/deluge-openvpn/ovpn, randomly pick a config and set this in openvpn.conf
#

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

FILES=(${OVPN_PATH}/*)
CFG_FILE="${FILES[RANDOM % ${#FILES[@]}]}"
/usr/bin/sed -i "s@OVPN_VPNCONF=\".*\"@OVPN_VPNCONF=\"${CFG_FILE}\"@" $OVPN_CONF
