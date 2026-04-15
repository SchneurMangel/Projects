# Packet Analysis Script
# Google Cybersecurity Certificate - Portfolio Project
# Author: Schneur Mangel
#
# Simulates a SOC analyst reviewing packet capture data after an alert.
# Checks for four signs of intrusion:
#   1. Connections on known malicious ports (C2 traffic)
#   2. Large outbound data transfers (exfiltration)
#   3. SYN packets to many internal hosts (port scanning)
#   4. DNS queries to suspicious domains (tool staging)
#
# Run: python analysis.py

# -- Packet data --
# Each packet is a dictionary representing one row from a packet capture.
# In a real investigation this data would come from Wireshark or tcpdump.

packets = [
    {"time": "02:14:03", "src": "192.168.1.105", "dst": "45.33.32.156",  "port": 4444, "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:14:03", "src": "45.33.32.156",  "dst": "192.168.1.105", "port": 4444, "protocol": "TCP", "size": 60,       "flags": "SYN-ACK", "dns": ""},
    {"time": "02:14:04", "src": "192.168.1.105", "dst": "45.33.32.156",  "port": 4444, "protocol": "TCP", "size": 40000000, "flags": "PSH",     "dns": ""},
    {"time": "02:14:03", "src": "192.168.1.105", "dst": "8.8.8.8",       "port": 53,   "protocol": "UDP", "size": 80,       "flags": "",        "dns": "nmap.org"},
    {"time": "02:14:04", "src": "192.168.1.105", "dst": "8.8.8.8",       "port": 53,   "protocol": "UDP", "size": 80,       "flags": "",        "dns": "pastebin.com"},
    {"time": "02:15:01", "src": "192.168.1.105", "dst": "192.168.1.106", "port": 22,   "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:15:01", "src": "192.168.1.105", "dst": "192.168.1.107", "port": 22,   "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:15:01", "src": "192.168.1.105", "dst": "192.168.1.108", "port": 22,   "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:15:01", "src": "192.168.1.105", "dst": "192.168.1.109", "port": 22,   "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:15:01", "src": "192.168.1.105", "dst": "192.168.1.110", "port": 22,   "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:15:01", "src": "192.168.1.105", "dst": "192.168.1.111", "port": 22,   "protocol": "TCP", "size": 60,       "flags": "SYN",     "dns": ""},
    {"time": "02:13:55", "src": "192.168.1.101", "dst": "172.217.0.46",  "port": 443,  "protocol": "TCP", "size": 2048,     "flags": "PSH",     "dns": ""},
    {"time": "02:13:56", "src": "192.168.1.102", "dst": "13.107.42.14",  "port": 443,  "protocol": "TCP", "size": 1024,     "flags": "PSH",     "dns": ""},
]

# -- Detection thresholds --
SUSPICIOUS_PORTS   = [4444, 1337, 31337, 8888, 9999, 6666]
EXFIL_LIMIT        = 10000000  # 10 MB
SCAN_LIMIT         = 5
SUSPICIOUS_DOMAINS = ["pastebin.com", "nmap.org", "ngrok.io"]

# -- Storage --
bytes_sent  = {}  # tracks total bytes per src -> dst pair
syn_targets = {}  # tracks unique internal hosts each IP has SYN'd

c2_findings    = []
exfil_findings = []
scan_findings  = []
dns_findings   = []

# -- Analysis loop --
for p in packets:

    # Check 1: C2 traffic
    if p["protocol"] == "TCP" and p["port"] in SUSPICIOUS_PORTS:
        c2_findings.append(f"  [HIGH]   {p['time']} | {p['src']} --> {p['dst']}:{p['port']} | {p['flags']}")

    # Check 2: Accumulate bytes for exfiltration detection
    if p["src"].startswith("192.168."):
        key = p["src"] + " -> " + p["dst"]
        if key not in bytes_sent:
            bytes_sent[key] = 0
        bytes_sent[key] += p["size"]

    # Check 3: Track SYN packets to internal hosts for scan detection
    if p["protocol"] == "TCP" and p["flags"] == "SYN" and p["src"].startswith("192.168.") and p["dst"].startswith("192.168."):
        if p["src"] not in syn_targets:
            syn_targets[p["src"]] = []
        if p["dst"] not in syn_targets[p["src"]]:
            syn_targets[p["src"]].append(p["dst"])

    # Check 4: Suspicious DNS queries
    if p["dns"] != "":
        for domain in SUSPICIOUS_DOMAINS:
            if domain in p["dns"]:
                dns_findings.append(f"  [MEDIUM] {p['time']} | {p['src']} queried: {p['dns']}")

# -- Post-loop: evaluate totals --
for key in bytes_sent:
    if bytes_sent[key] >= EXFIL_LIMIT:
        mb = round(bytes_sent[key] / 1000000, 2)
        exfil_findings.append(f"  [HIGH]   {key} | {mb} MB sent outbound")

for src in syn_targets:
    if len(syn_targets[src]) >= SCAN_LIMIT:
        scan_findings.append(f"  [MEDIUM] {src} SYN'd {len(syn_targets[src])} internal hosts: {', '.join(syn_targets[src])}")

# -- Print report --
print("\n" + "=" * 55)
print("  PACKET ANALYSIS REPORT")
print("  Google Cybersecurity Certificate")
print("=" * 55)

print("\n[1] C2 / Malicious Port Traffic")
if c2_findings:
    for f in c2_findings:
        print(f)
else:
    print("  No findings.")

print("\n[2] Data Exfiltration")
if exfil_findings:
    for f in exfil_findings:
        print(f)
else:
    print("  No findings.")

print("\n[3] Internal Port Scanning")
if scan_findings:
    for f in scan_findings:
        print(f)
else:
    print("  No findings.")

print("\n[4] Suspicious DNS Queries")
if dns_findings:
    for f in dns_findings:
        print(f)
else:
    print("  No findings.")

print("\n" + "=" * 55 + "\n")
