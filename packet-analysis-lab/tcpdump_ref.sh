#!/usr/bin/env bash
# =============================================================================
# tcpdump Command Reference
# Google Cybersecurity Certificate - Portfolio Project
# Author: Schneur Mangel
#
# tcpdump is a command line tool that captures and reads network traffic.
# These are the commands used during the investigation in this lab.
#
# Note: Commands that capture live traffic require sudo (admin privileges).
#       Commands that read saved files (-r) do not need sudo.
# =============================================================================


# -----------------------------------------------------------------------------
# CAPTURING TRAFFIC
# -----------------------------------------------------------------------------

# Capture all traffic on the network interface and save it to a file
# -i eth0  = which network interface to listen on
# -w       = write the output to a file instead of printing it
sudo tcpdump -i eth0 -w capture.pcap

# Capture traffic only to or from a specific IP address
sudo tcpdump -i eth0 host 192.168.1.105 -w suspect.pcap

# Capture traffic on a specific port only (e.g. port 4444)
sudo tcpdump -i eth0 port 4444 -w port4444.pcap

# Stop after capturing 100 packets
sudo tcpdump -i eth0 -c 100 -w capture.pcap


# -----------------------------------------------------------------------------
# READING A SAVED PCAP FILE
# -----------------------------------------------------------------------------

# Read and print the contents of a saved capture file
# -r       = read from file
# -n       = do not resolve IP addresses to hostnames (keeps output clean)
# -tttt    = show full date and time for each packet
tcpdump -r capture.pcap -n -tttt

# Show more detail about each packet (protocol headers)
tcpdump -r capture.pcap -v


# -----------------------------------------------------------------------------
# FILTERING WHEN READING
# -----------------------------------------------------------------------------
# Filters let you focus on specific traffic and cut out the noise.

# Show only traffic from the suspect host
tcpdump -r capture.pcap src host 192.168.1.105

# Show only traffic going TO a specific external IP
tcpdump -r capture.pcap dst host 45.33.32.156

# Show only traffic on port 4444
tcpdump -r capture.pcap port 4444

# Show only TCP traffic
tcpdump -r capture.pcap tcp

# Show only DNS traffic (DNS uses UDP on port 53)
tcpdump -r capture.pcap udp port 53

# Combine filters: traffic FROM the suspect host on port 4444
tcpdump -r capture.pcap src host 192.168.1.105 and port 4444

# Exclude normal web traffic to reduce noise
tcpdump -r capture.pcap not port 443 and not port 80


# -----------------------------------------------------------------------------
# INVESTIGATION-SPECIFIC COMMANDS
# -----------------------------------------------------------------------------
# Commands used in this specific lab investigation.

# Find all TCP SYN packets (connection attempts - used to detect port scans)
# tcp[tcpflags] reads the TCP flags field directly from the packet header
tcpdump -r capture.pcap "tcp[tcpflags] == tcp-syn"

# View the data payload of packets in readable text (ASCII)
# -A = show payload as ASCII text
# -s 200 = capture the first 200 bytes of each packet
tcpdump -r capture.pcap -A -s 200 port 4444

# Show large packets only (over 1400 bytes - may indicate data being exfiltrated)
tcpdump -r capture.pcap "len > 1400"

# Show all traffic between two specific hosts
tcpdump -r capture.pcap "host 192.168.1.105 and host 45.33.32.156"


# -----------------------------------------------------------------------------
# QUICK FLAG REFERENCE
# -----------------------------------------------------------------------------
# -i    : which interface to capture on (eth0, wlan0, any)
# -w    : write capture to a file
# -r    : read from a file
# -n    : do not resolve hostnames (show raw IPs)
# -v    : verbose - show more detail per packet
# -A    : show packet payload as ASCII text
# -c N  : stop after capturing N packets
# -tttt : show full timestamp on each packet
# -s N  : how many bytes to capture per packet (0 = entire packet)
#
# TCP FLAGS (what each one means):
# SYN     : initiating a new connection
# SYN-ACK : acknowledging a connection request
# ACK     : confirming receipt of data
# PSH     : pushing data through the connection
# FIN     : closing a connection cleanly
# RST     : resetting / forcefully closing a connection
