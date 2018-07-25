#!/usr/bin/env bash
# Script to harden firewall to isolate ft_bridge network
#
# TLDR - only stunnel out to https, only unbound out to dsn, all other out and inbound traffic dropped.
##
if [[ $EUID -ne 0 ]]; then
   echo "This script is executing firewall.sh for ft_cache, sudo  privilage to update iptables"
   echo "Please enter your password to continue."
fi

[ "$EUID" -eq 0 ] || exec sudo "$0" "$@"
##############
# Egress Rules:
# Allow only stunnel to connect out for DNS, drop all other UDP traffic
# Docker is a "bit of an arse" it can use FORWARD or DOCKER-ISOLATION... so add to both
##

# Flush the chains
iptables -F FORWARD
iptables -F DOCKER-ISOLATION

# Allow outbound HTTPs from Stunnel (7.253) and outbound DNS from unbound (7.248) only
iptables -I FORWARD 1 -s 10.99.7.248 -p udp -d 0/0 --dport 53 -j ACCEPT
iptables -I FORWARD 2 -s 10.99.7.248 -p tcp -d 0/0 --dport 53 -j ACCEPT
iptables -I FORWARD 3 -s 10.99.7.253 -p tcp -d 0/0 --dport 443 -j ACCEPT
iptables -I FORWARD 4  -d 0/0 -i ft_bridge ! -o ft_bridge -j REJECT --reject-with icmp-port-unreachable

iptables -I DOCKER-ISOLATION 1 -s 10.99.7.248 -p udp -d 0/0 --dport 53 -j ACCEPT
iptables -I DOCKER-ISOLATION 2 -s 10.99.7.248 -p tcp -d 0/0 --dport 53 -j ACCEPT
iptables -I DOCKER-ISOLATION 3 -s 10.99.7.253 -p tcp -d 0/0 --dport 443 -j ACCEPT
iptables -I DOCKER-ISOLATION 4 -d 0/0 -i ft_bridge ! -o ft_bridge -j REJECT --reject-with icmp-port-unreachable

##############
# Ingress Rules:
# Block all inbound traffic to ft_bridge interface
# allow access from lo 127.0.0.1 localhost to test services.
# allow hosts on ft_bridge to communicate with each other
##

# Create/Flush a PRE_DOCKER chain
chain_exists()
{
    [ $# -lt 1 -o $# -gt 2 ] && {
        echo "Usage: chain_exists <chain_name> [table]" >&2
        return 1
    }
    local chain_name="$1" ; shift
    [ $# -eq 1 ] && local table="--table $1"
    iptables $table -n --list "$chain_name" >/dev/null 2>&1
}
chain_exists B4_DOCKER || iptables -N B4_DOCKER
iptables -F B4_DOCKER

# Default Chain Rule Drop  add allow connections from local host
iptables -I B4_DOCKER -j DROP
iptables -I B4_DOCKER 1 -i lo -s 127.0.0.1  -j ACCEPT

# Allow hosts on ft_bridge to talk to each other
iptables -I B4_DOCKER 2 -o ft_bridge -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I B4_DOCKER 3 -i ft_bridge ! -o ft_bridge -j ACCEPT
iptables -I B4_DOCKER 4 -m state --state RELATED -j ACCEPT
iptables -I B4_DOCKER 5 -i ft_bridge -o ft_bridge -j ACCEPT

# Insert to the top of FORWARD and DOCKER-ISOLATION as both can be used
iptables -I FORWARD -o ft_bridge -j B4_DOCKER
iptables -I DOCKER-ISOLATION -o ft_bridge -j B4_DOCKER