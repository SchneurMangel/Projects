#!/usr/bin/env bash
# tcpdump Command Reference
# Google Cybersecurity Certificate - Packet Analysis Lab
# Author: Schneur Mangel
#
# tcpdump captures and reads network traffic from the command line.
# Commands that capture live traffic need sudo (admin access).
# Commands that read saved files do not need sudo.


# --- Capturing traffic ---

# Capture all traffic on the network and save to a file
sudo tcpdump -i eth0 -w capture.pcap

# Capture traffic only from a specific IP address
sudo tcpdump -i eth0 host 192.168.1.105 -w suspect.pcap

# Capture traffic on a specific port
sudo tcpdump -i eth0 port 4444 -w port4444.pcap

# Stop after 100 packets
sudo tcpdump -i eth0 -c 100 -w capture.pcap


# --- Reading a saved file ---

# Read and print a saved capture file
tcpdump -r capture.pcap

# Read with full timestamps and no hostname resolution
tcpdump -r capture.pcap -n -tttt

# Read with more detail about each packet
tcpdump -r capture.pcap -v


# --- Filtering by IP ---

# Show only traffic FROM a specific host
tcpdump -r capture.pcap src host 192.168.1.105

# Show only traffic GOING TO a specific host
tcpdump -r capture.pcap dst host 45.33.32.156

# Show all traffic between two specific hosts (both directions)
tcpdump -r capture.pcap "host 192.168.1.105 and host 45.33.32.156"


# --- Filtering by port and protocol ---

# Show traffic on a specific port
tcpdump -r capture.pcap port 4444

# Show only TCP traffic
tcpdump -r capture.pcap tcp

# Show only DNS traffic (DNS uses UDP on port 53)
tcpdump -r capture.pcap udp port 53

# Remove normal web traffic to reduce noise
tcpdump -r capture.pcap "not port 443 and not port 80"


# --- Viewing packet contents ---

# Show packet data as readable text
# Useful for seeing if C2 traffic is unencrypted
tcpdump -r capture.pcap -A port 4444

# Show only large packets (possible data exfiltration)
tcpdump -r capture.pcap "len > 1400"


# --- Flag reference ---
# -i      : which network interface to listen on (eth0 = ethernet)
# -w      : save capture to a file
# -r      : read from a saved file
# -n      : show raw IP addresses, do not look up hostnames
# -v      : show more detail per packet
# -A      : show packet contents as readable text
# -c N    : stop after N packets
# -tttt   : show full date and time on each packet

# TCP flag meanings:
# SYN     : starting a new connection
# SYN-ACK : accepting a connection request
# ACK     : confirming data was received
# PSH     : sending data through the connection
# FIN     : closing a connection
# RST     : forcefully dropping a connection
