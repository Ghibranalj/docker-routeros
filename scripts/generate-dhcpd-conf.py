#!/usr/bin/env python3

import argparse
import ipaddress
import json
import re
import socket
import subprocess

from typing import List, Iterable

DEFAULT_ROUTE = 'default'
DEFAULT_DNS_IPS = '1.1.1.1'

DHCP_CONF_TEMPLATE = """
# Specify the interface to listen on
# interface=eth0

# Specify the DHCP range
dhcp-range={host_addr},{host_addr},{subnet},infinite

# Specify the default gateway
dhcp-option=3,{gateway}

# Specify the DNS server
dhcp-option=6,{dns}

# Specify lease file location
dhcp-leasefile=/var/lib/misc/dnsmasq.leases

# Disable DNS
port=0

# Don't forward DNS queries
bogus-priv

# Enable DHCP logging
log-dhcp

"""


def default_route(routes):
    """Returns the host's default route"""
    for route in routes:
        if route['dst'] == DEFAULT_ROUTE:
            return route
    raise ValueError('no default route')

def addr_of(addrs, dev : str) -> ipaddress.IPv4Interface:
    """Finds and returns the IP address of `dev`"""
    for addr in addrs:
        if addr['ifname'] != dev:
            continue
        info = addr['addr_info'][0]
        return ipaddress.IPv4Interface((info['local'], info['prefixlen']))
    raise ValueError('dev {0} not found'.format(dev))

def generate_conf(intf_name : str, dns_ : str) -> str:
    """Generates a dhcpd config. `intf_name` is the interface to listen on."""
    with subprocess.Popen(['ip', '-json', 'route'], stdout=subprocess.PIPE) as proc:
        routes = json.load(proc.stdout)
    with subprocess.Popen(['ip', '-json', 'addr'], stdout=subprocess.PIPE) as proc:
        addrs = json.load(proc.stdout)
    
    droute = default_route(routes)
    host_addr = addr_of(addrs, droute['dev'])

    return DHCP_CONF_TEMPLATE.format(
        dhcp_intf = intf_name,
        dns = dns_,
        gateway = droute['gateway'],
        host_addr = host_addr.ip,
        hostname = socket.gethostname(),
        subnet = host_addr.network.netmask,
    )

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('intf_name')
    parser.add_argument('dns_ips', nargs='*')
    args = parser.parse_args()

    dns_ips = args.dns_ips
    if not dns_ips:
        dns_ips = DEFAULT_DNS_IPS

    print(generate_conf(args.intf_name, dns_ips))
