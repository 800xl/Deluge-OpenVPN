# deluge-openvpn
Deluge openvpn scripts to route only the deluge service over vpn tunnel
Build on Centos 7 using IPVANISH as VPN Service

Used a few online resources, and will try to give credits while I start updating things...

# Quick install:
- Install openvpn and deluge
# yum install openvpn deluge deluge-common deluge-daemon deluge-web -y
- Configure deluge and confirm that it's working as expected (Will add a detailed tutorial later)

# Openvpn and Deluge configuration
- Clone deluge-openvpn into /opt
- Edit the config file: etc/deluge-openvpn.conf You will need to configure the network part, all others settings can be kept.
- Add "1 vpn" to /etc/iproute2/rt_tables Or use a different table number if 1 is used.
- Copy runscripts/deluged.conf towards /etc/sysconfig
- Either use the provided deluged.service and deluge-web.service systemctl files in runscripts/ to start deluge (# systemctl enable /opt/deluge-openvpn/runscripts/deluged.service) or Modify your own in /etc/systemd/system/deluge.service and adjust the ExecStart by adding the following options -i ${BIND_TO_IP} -u 127.0.0.1 (IE: ExecStart=/usr/bin/deluged -d –i ${BIND_TO_IP} –u 127.0.0.1 -c /var/lib/deluge -l /var/log/deluged.log –L warning")
- Add the openvpn service # systemctl enable /opt/deluge-openvpn/runscripts/openvpn.service

# VPN Service configuration
- If you are using the IPVANISH VPN services then edit the etc/openvpn_auth.conf file and add your IPVANISH username and password on separate lines in this file
- For other VPN services you have a few options:
1. Edit the ipvanish.ovpn file and change the remote servers to your service and add options you might require for this service
2. Delete the etc/ipvanish.ovpn file and save all the separate .ovpn files from your provider into the ovpn/ folder. (Keep in mind that the .ca file will need to be saved into the ca/ folder and specified in the config file. Also check the options already set on OVPN_OPTIONS. For instance the ca, route-nopull; these need to be removed from the .ovpn files.

The included ipvanish.ovpn file uses the multi-server option. And will random connect to any of the VPN servers specified in the file.
When you store multiple .ovpn files into the ovpn/ folder the script will randomly pick one from the list on start or restart.

When all is done start openvpn: systemctl start openvpn
This will restart the deluge service and will bind it towards the tun0 interface.

Confirm that deluge is using the openvpn tunnel by going to http://checkmytorrentip.upcoil.com/ and click the magnet link.
In a few seconds it should show you the IP which deluge is using to connect to the internet.

If you have trouble announcing to trackers you might need to uncomment the firewall settings in bin/openvpn_up.sh and bin/openvpn_down.sh. Some people also will need to forward the ports in their router towards the machine running deluge.
