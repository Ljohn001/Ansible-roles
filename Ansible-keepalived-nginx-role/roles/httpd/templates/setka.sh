#!/bin/bash
#
vip={{ vip }}
iface={{ iface }}
case $1 in
start)
	echo 1 > /proc/sys/net/ipv4/conf/all/arp_ignore
	echo 1 > /proc/sys/net/ipv4/conf/$iface/arp_ignore
	echo 2 > /proc/sys/net/ipv4/conf/all/arp_announce
	echo 2 > /proc/sys/net/ipv4/conf/$iface/arp_announce
	ifconfig lo:0 $vip broadcast $vip netmask 255.255.255.255 up
	;;
stop)
	ifconfig lo:0 down
	echo 0 > /proc/sys/net/ipv4/conf/all/arp_ignore
	echo 0 > /proc/sys/net/ipv4/conf/$iface/arp_ignore
	echo 0 > /proc/sys/net/ipv4/conf/all/arp_announce
	echo 0 > /proc/sys/net/ipv4/conf/$iface/arp_announce
	;;
*)
	echo "Usage: `basename $0` {start|stop}"
	exit 1
esac
