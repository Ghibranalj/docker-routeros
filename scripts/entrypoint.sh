#!/usr/bin/env bash

QEMU_BRIDGE_ETH1='qemubr1'
default_dev1='eth0'

# get ip of the default interface
IP_ADDRESS=$(ip -o -4 addr list $default_dev1 | awk '{print $4}')


# use the last ip of the subnet for dummy dnsmasq
DUMMY_DHCPD_IP=$(ipcalc $IP_ADDRESS | grep HostMax | awk '{print $2}')
echo "Dummy DHCPD IP: $DUMMY_DHCPD_IP"

# These scripts configure/deconfigure the VM interface on the bridge.
QEMU_IFUP='/routeros/qemu-ifup'
QEMU_IFDOWN='/routeros/qemu-ifdown'

# The name of the dhcpd config file we make
DHCPD_CONF_FILE='/dhcp/dhcpd.conf'
mkdir -p /dhcp

# check if mac address is set
# if not use default mac address
if [ -z "$MAC_ADDRESS" ]; then
   MAC_ADDRESS='52:54:00:12:34:56'
fi

# check if /dev/kvm exists and use it

if [ -e /dev/kvm ]; then
   USE_KVM='-enable-kvm'
   echo "KVM is enabled"
else
   USE_KVM=''
fi

# First step, we run the things that need to happen before we start mucking
# with the interfaces. We start by generating the DHCPD config file based
# on our current address/routes. We "steal" the container's IP, and lease
# it to the VM once it starts up.
/routeros/generate-dhcpd-conf.py $QEMU_BRIDGE_ETH1 > $DHCPD_CONF_FILE

function prepare_intf() {
   #First we clear out the IP address and route
   ip addr flush dev $1
   # Next, we create our bridge, and add our container interface to it.
   ip link add $2 type bridge
   ip link set dev $1 master $2
   # Then, we toggle the interface and the bridge to make sure everything is up
   # and running.
   ip link set dev $1 up
   ip link set dev $2 up

   # add ip to $2
   ip addr add $DUMMY_DHCPD_IP/24 dev $2

   # block outgoing traffic from dummy ip
   iptables -A OUTPUT -d $DUMMY_DHCPD_IP -j DROP
}

prepare_intf $default_dev1 $QEMU_BRIDGE_ETH1
# Finally, start our DHCPD server
# udhcpd -I $DUMMY_DHCPD_IP -f $DHCPD_CONF_FILE &

dnsmasq --test -C $DHCPD_CONF_FILE
if [ $? -ne 0 ]; then
   echo "DHCPD config file is invalid"
fi
echo "Starting dnsmasq..."
dnsmasq -d --listen-address=$DUMMY_DHCPD_IP -C $DHCPD_CONF_FILE &

mkdir -p '/image'
TARGET_IMAGE='/image/routeros.img'
# if Target doesnt exist copy RouterOS image to target
if [ ! -f $TARGET_IMAGE ]; then
   echo "Copying RouterOS image to target..."
   cp $ROUTEROS_IMAGE $TARGET_IMAGE
fi

# And run the VM! A brief explanation of the options here:
# -enable-kvm: Use KVM for this VM (much faster for our case).
# -nographic: disable SDL graphics.
# -serial mon:stdio: use "monitored stdio" as our serial output.
# -nic: Use a TAP interface with our custom up/down scripts.
# -drive: The VM image we're booting.
# mac: Set up your own interfaces mac addresses here, cause from winbox you can not change these later.
echo "Starting VM..."
echo "MAC address: $MAC_ADDRESS"
exec qemu-system-x86_64 \
   -nographic -serial mon:stdio \
   -vnc 0.0.0.0:0 \
   -m 512 \
   -smp 4,sockets=1,cores=4,threads=1 \
   -nic tap,id=qemu1,mac=$MAC_ADDRESS,script=$QEMU_IFUP,downscript=$QEMU_IFDOWN \
   "$@" $USE_KVM \
   -hda $TARGET_IMAGE
