#!/bin/bash

echo "Downloading and applying full tor list... please be patient, this may take some seconds..."

EXIT_NODES_URL="https://www.dan.me.uk/torlist/?exit"
#EXIT_NODES_URL="http://localhost:8080/torlist"  #Use this if you want to provide your own list or when testing this script, dan.me.uk blocks clients after the some requests; you may use pythom -m SimpleHTTPWebServer 8080
EXIT_NODES_FILE="torExitNodes.txt"

# create IPv4 chains
iptables -t filter -N TORFILTER > /dev/null 2>&1
iptables -t filter -N TORLOG > /dev/null 2>&1

# create IPv6 chains
ip6tables -t filter -N TORFILTER > /dev/null 2>&1
ip6tables -t filter -N TORLOG > /dev/null 2>&1

# forward incoming IPv4 packets to TORFILTER chain
iptables -t filter -C INPUT -j TORFILTER
if [ $? -ne 0 ]; then
    iptables -t filter -A INPUT -j TORFILTER
fi
iptables -t filter -C FORWARD -j TORFILTER
if [ $? -ne 0 ]; then
    iptables -t filter -A FORWARD -j TORFILTER
fi

# forward incoming IPv6 packets to TORFILTER chain
ip6tables -t filter -C INPUT -j TORFILTER
if [ $? -ne 0 ]; then
    ip6tables -t filter -A INPUT -j TORFILTER
fi
ip6tables -t filter -C FORWARD -j TORFILTER
if [ $? -ne 0 ]; then
    ip6tables -t filter -A FORWARD -j TORFILTER
fi

# configure IPv4 TORLOG chain to log and drop
iptables -t filter -C TORLOG -m limit --limit 10/min --limit-burst 1 -j LOG --log-prefix "Tor Node Packet: " --log-level 7
if [ $? -ne 0 ]; then
    iptables -t filter -A TORLOG -m limit --limit 10/min --limit-burst 1 -j LOG --log-prefix "Tor Node Packet: " --log-level 7
fi
iptables -t filter -C TORLOG -j DROP
if [ $? -ne 0 ]; then
    iptables -t filter -A TORLOG -j DROP
fi

# configure IPv6 TORLOG chain to log and drop
ip6tables -t filter -C TORLOG -m limit --limit 10/min --limit-burst 1 -j LOG --log-prefix "Tor Node Packet: " --log-level 7
if [ $? -ne 0 ]; then
    ip6tables -t filter -A TORLOG -m limit --limit 10/min --limit-burst 1 -j LOG --log-prefix "Tor Node Packet: " --log-level 7
fi
ip6tables -t filter -C TORLOG -j DROP
if [ $? -ne 0 ]; then
    ip6tables -t filter -A TORLOG -j DROP
fi

# grab current list of tor nodes
curl -k $EXIT_NODES_URL > $EXIT_NODES_FILE

# flush previous TORFILTER chain IPv4 and 6
iptables -t filter -F TORFILTER
ip6tables -t filter -F TORFILTER

# add rules for each node in list
while read line; do
	if [[ $line == *":"* ]]; then
		ip6tables -t filter -A TORFILTER -s $line/64 -j TORLOG
	else
		iptables -t filter -A TORFILTER -s $line/32 -j TORLOG
	fi
done < $EXIT_NODES_FILE

iptables -t filter -A TORFILTER -j RETURN
ip6tables -t filter -A TORFILTER -j RETURN

echo "Done, have fun :)"
