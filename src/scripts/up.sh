#!/bin/bash

# NIC
nic=wlan0
ap=wlan0_ap
station=wlan0_sta

# The subnet IP mask.
mask=/24

# The subnet IP range.
subnet_ip=10.10.0.0$mask

# The IP of the subnet NIC on the subnet.
server_ip=10.10.0.1$mask

# The dhcpd configuration, lease and PID files to use.
dhcpd_conf=$APPDIR/config/dhcpd/dhcpd.conf
dhcpd_lease=/tmp/dhcpd.lease
dhcpd_pid=/tmp/dhcpd.pid

# Hostapd config and pid files
hostapd_conf=$APPDIR/config/hostapd/hostapd.conf
hostapd_pid=/tmp/hostapd.pid

# Bind config
named_conf=$APPDIR/config/bind/named.conf
named_pid=/tmp/named.pid

# Create virtual interfaces
iw dev "$nic" interface add "$station" type station
iw dev "$nic" interface add "$ap" type __ap

# Set MAC addresses
ip link set dev "$station" address 00:0f:60:06:8c:24
ip link set dev "$ap" address 00:0f:60:06:8c:28

# Open up DNS (53) and DHCP (67) ports on subnet_nic.
iptables -A INPUT -i "$ap" -s "$subnet_ip" -p tcp --dport 53 -j ACCEPT
iptables -A INPUT -i "$ap" -s "$subnet_ip" -p udp --dport 53 -j ACCEPT
iptables -A INPUT -i "$ap" -p udp --dport 67 -j ACCEPT

# Accept ICMP (ping) request packets so clients can check their connections.
iptables -A INPUT -i "$ap" -p icmp --icmp-type echo-request -j ACCEPT
#iptables -A OUTPUT -i "$ap" -p icmp --icmp-type echo-reply -j ACCEPT

# Set the static IP for subnet_nic.
ip addr replace "$server_ip" dev "$ap"

# Start up station interface
ip link set dev "$station" up

# Set channel of station interface
iw dev "$station" set channel 6

# Ensure the lease file exists.
mkdir -p -- "${dhcpd_lease%/*}"
[[ -f $dhcpd_lease ]] || touch "$dhcpd_lease"

# Launch bind
named -4 -c "$named_conf"

# Configure Hostapd
hostapd -B -P "$hostapd_pid" "$hostapd_conf"

# Launch the DHCP server
dhcpd -4 -q -cf "$dhcpd_conf" -lf "$dhcpd_lease" -pf "$dhcpd_pid" "$ap"

for SCRIPT in $APPDIR/scripts/start.d/*
  do
    if [ -f $SCRIPT -a -x $SCRIPT ]
    then
      echo -e "\e[1;32mRunning $(basename $SCRIPT)\e[0m"
      $SCRIPT
    fi
done

exit 0
