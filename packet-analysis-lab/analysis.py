# =============================================================================
# Packet Analysis Script
# Google Cybersecurity Certificate - Portfolio Project
# Author: Schneur Mangel
#
# What this script does:
#   Simulates a SOC analyst reviewing packet capture data after an alert fires.
#   It checks for four common signs of a network intrusion:
#     1. Connections to known malicious ports (C2 traffic)
#     2. Large amounts of data being sent outbound (data exfiltration)
#     3. One internal host scanning many others (port scanning)
#     4. DNS queries to suspicious domains (tool staging)
#
# How to run:
#   python analysis.py
# =============================================================================


# -----------------------------------------------------------------------------
# PACKET DATA
# -----------------------------------------------------------------------------
# In a real investigation, this data would come from a PCAP file opened in
# Wireshark or read with tcpdump. Here we represent each packet as a
# dictionary so we can practice the analysis logic in plain Python.
#
# Each packet has:
#   - timestamp : when the packet was captured
#   - src_ip    : where the packet came from
#   - dst_ip    : where the packet is going
#   - dst_port  : which port on the destination it is targeting
#   - protocol  : TCP or UDP
#   - size      : how many bytes this packet contains
#   - flags     : TCP control flags (SYN = start connection, ACK = acknowledge,
#                 PSH = push data, FIN = close connection)
#   - dns_query : if this was a DNS lookup, what domain was queried

packets = [
    # --- Suspicious traffic from 192.168.1.105 ---

    # Step 1: The attacker's machine initiates a TCP connection to port 4444
    # SYN = "I want to connect" (first step of the TCP 3-way handshake)
    {
        "timestamp": "02:14:03",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "45.33.32.156",
        "dst_port":  4444,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },
    # Step 2: The external server responds (SYN-ACK = "ok, connecting")
    {
        "timestamp": "02:14:03",
        "src_ip":    "45.33.32.156",
        "dst_ip":    "192.168.1.105",
        "dst_port":  4444,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN-ACK",
        "dns_query": ""
    },
    # Step 3: The handshake completes. An active session is now open.
    # PSH = data is being pushed through the connection
    # 40,000,000 bytes = 40 MB being sent OUT to the attacker
    {
        "timestamp": "02:14:04",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "45.33.32.156",
        "dst_port":  4444,
        "protocol":  "TCP",
        "size":      40000000,
        "flags":     "PSH",
        "dns_query": ""
    },

    # DNS query for nmap.org - nmap is a port scanning tool
    # No legitimate user should be looking this up at 2 AM
    {
        "timestamp": "02:14:03",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "8.8.8.8",
        "dst_port":  53,
        "protocol":  "UDP",
        "size":      80,
        "flags":     "",
        "dns_query": "nmap.org"
    },
    # DNS query for pastebin.com - commonly used by attackers to host scripts
    {
        "timestamp": "02:14:04",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "8.8.8.8",
        "dst_port":  53,
        "protocol":  "UDP",
        "size":      80,
        "flags":     "",
        "dns_query": "pastebin.com"
    },

    # Internal port scan - the compromised host is probing other machines
    # on the internal network to find new targets. Each SYN is a probe.
    {
        "timestamp": "02:15:01",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "192.168.1.106",
        "dst_port":  22,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },
    {
        "timestamp": "02:15:01",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "192.168.1.107",
        "dst_port":  22,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },
    {
        "timestamp": "02:15:01",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "192.168.1.108",
        "dst_port":  22,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },
    {
        "timestamp": "02:15:01",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "192.168.1.109",
        "dst_port":  22,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },
    {
        "timestamp": "02:15:01",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "192.168.1.110",
        "dst_port":  22,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },
    {
        "timestamp": "02:15:01",
        "src_ip":    "192.168.1.105",
        "dst_ip":    "192.168.1.111",
        "dst_port":  22,
        "protocol":  "TCP",
        "size":      60,
        "flags":     "SYN",
        "dns_query": ""
    },

    # --- Normal traffic (should NOT be flagged) ---
    # These represent typical business traffic to HTTPS sites
    {
        "timestamp": "02:13:55",
        "src_ip":    "192.168.1.101",
        "dst_ip":    "172.217.0.46",
        "dst_port":  443,
        "protocol":  "TCP",
        "size":      2048,
        "flags":     "PSH",
        "dns_query": ""
    },
    {
        "timestamp": "02:13:56",
        "src_ip":    "192.168.1.102",
        "dst_ip":    "13.107.42.14",
        "dst_port":  443,
        "protocol":  "TCP",
        "size":      1024,
        "flags":     "PSH",
        "dns_query": ""
    },
]


# -----------------------------------------------------------------------------
# DETECTION RULES
# -----------------------------------------------------------------------------
# These are the thresholds and known-bad values we check each packet against.
# A real SOC would tune these based on what is normal in their environment.

# Ports commonly used by attacker tools and reverse shells
# Port 4444 = Metasploit default | 1337 / 31337 = classic hacker ports
SUSPICIOUS_PORTS = [4444, 1337, 31337, 8888, 9999, 6666]

# If a host sends more than this many bytes outbound, flag for exfiltration
# 10,000,000 bytes = 10 MB
EXFIL_LIMIT = 10000000

# If one host sends SYN packets to this many different internal IPs, it is scanning
SCAN_LIMIT = 5

# Domains attackers commonly use to download tools or host malicious scripts
SUSPICIOUS_DOMAINS = ["pastebin.com", "nmap.org", "ngrok.io", "serveo.net"]


# -----------------------------------------------------------------------------
# ANALYSIS
# -----------------------------------------------------------------------------
# We loop through every packet and run our four checks.
# Anything suspicious gets added to the matching findings list.

c2_findings       = []   # C2 / malicious port connections
exfil_findings    = []   # Data exfiltration
scan_findings     = []   # Internal port scanning
dns_findings      = []   # Suspicious DNS queries

# To detect exfiltration we need to add up bytes across multiple packets.
# This dictionary stores the running total for each src -> dst pair.
# Key = "src_ip -> dst_ip", Value = total bytes sent
bytes_sent = {}

# To detect port scanning we need to track how many unique internal hosts
# one IP has sent SYN packets to.
# Key = src_ip, Value = list of destination IPs it has SYN'd
syn_targets = {}

# --- Main loop ---
for packet in packets:

    src      = packet["src_ip"]
    dst      = packet["dst_ip"]
    port     = packet["dst_port"]
    protocol = packet["protocol"]
    size     = packet["size"]
    flags    = packet["flags"]
    query    = packet["dns_query"]
    time     = packet["timestamp"]

    # -- Check 1: C2 traffic --
    # If the destination port is in our suspicious list, flag it.
    # We only care about TCP because C2 shells use TCP connections.
    if protocol == "TCP" and port in SUSPICIOUS_PORTS:
        c2_findings.append(
            f"  [HIGH] {time} | {src} --> {dst}:{port} | flags: {flags}"
        )

    # -- Check 2: Data exfiltration --
    # Only track traffic that starts from inside our network (192.168.x.x).
    # We add up the bytes for each unique src --> dst pair.
    if src.startswith("192.168."):
        pair = src + " -> " + dst
        if pair not in bytes_sent:
            bytes_sent[pair] = 0
        bytes_sent[pair] = bytes_sent[pair] + size

    # -- Check 3: Port scan detection --
    # A port scan is when one host sends SYN packets to many different targets.
    # We only care about scans against OTHER internal hosts (192.168.x.x).
    # A SYN to an external IP is just a normal outbound connection attempt.
    if protocol == "TCP" and flags == "SYN" and src.startswith("192.168.") and dst.startswith("192.168."):
        if src not in syn_targets:
            syn_targets[src] = []
        # Only add the destination if it isn't already in the list
        if dst not in syn_targets[src]:
            syn_targets[src].append(dst)

    # -- Check 4: Suspicious DNS --
    # If a DNS query contains any of our suspicious domains, flag it.
    if query != "":
        for domain in SUSPICIOUS_DOMAINS:
            if domain in query:
                dns_findings.append(
                    f"  [MEDIUM] {time} | {src} queried: {query}"
                )


# --- Post-loop checks ---
# These need all packets processed first before we can evaluate them.

# Check exfiltration totals
for pair in bytes_sent:
    total = bytes_sent[pair]
    if total >= EXFIL_LIMIT:
        mb = round(total / 1000000, 2)
        exfil_findings.append(
            f"  [HIGH] {pair} | total sent: {mb} MB"
        )

# Check scan totals
for src in syn_targets:
    target_count = len(syn_targets[src])
    if target_count >= SCAN_LIMIT:
        targets = ", ".join(syn_targets[src])
        scan_findings.append(
            f"  [MEDIUM] {src} sent SYN to {target_count} hosts: {targets}"
        )


# -----------------------------------------------------------------------------
# REPORT
# -----------------------------------------------------------------------------

print("")
print("=" * 60)
print("  PACKET ANALYSIS REPORT")
print("  Google Cybersecurity Certificate - Portfolio Project")
print("=" * 60)

print("")
print("-- Finding 1: C2 / Malicious Port Traffic --")
if len(c2_findings) > 0:
    for finding in c2_findings:
        print(finding)
    print("")
    print("  Action: Isolate the source host immediately.")
    print("  Block the external IP at the firewall.")
    print("  Preserve the PCAP before making any changes.")
else:
    print("  No suspicious port connections detected.")

print("")
print("-- Finding 2: Potential Data Exfiltration --")
if len(exfil_findings) > 0:
    for finding in exfil_findings:
        print(finding)
    print("")
    print("  Action: Review what data is stored on the source host.")
    print("  Check DLP logs. Begin a data breach assessment.")
else:
    print("  No large outbound transfers detected.")

print("")
print("-- Finding 3: Internal Port Scanning --")
if len(scan_findings) > 0:
    for finding in scan_findings:
        print(finding)
    print("")
    print("  Action: Check the scanned hosts for new or unexpected connections.")
    print("  The attacker may be looking for machines to move to next.")
else:
    print("  No port scanning detected.")

print("")
print("-- Finding 4: Suspicious DNS Queries --")
if len(dns_findings) > 0:
    for finding in dns_findings:
        print(finding)
    print("")
    print("  Action: Investigate what was downloaded from these domains.")
    print("  Attackers use these sites to host malicious scripts and tools.")
else:
    print("  No suspicious DNS queries detected.")

print("")
print("=" * 60)
print("  END OF REPORT")
print("=" * 60)
print("")
