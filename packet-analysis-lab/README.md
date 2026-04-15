# Packet Analysis Lab

**Google Cybersecurity Certificate | Portfolio Project**  
**Author:** Schneur Mangel  
**Tools:** tcpdump · Wireshark · Python  

---

## Overview

This project documents a network intrusion investigation from initial alert through to containment recommendations. It covers the core packet analysis skills from the Google Cybersecurity Certificate: capturing traffic, reading PCAP files, identifying suspicious patterns, and documenting findings.

The repository includes a Python script (`analysis.py`) that walks through the same analysis logic a SOC analyst would apply manually, written in plain readable code with comments explaining each step.

---

## Scenario

> **Alert:** 02:16 AM — unusual outbound traffic volume detected from an internal workstation.

A workstation at **192.168.1.105** opened a TCP connection to an unknown external IP (**45.33.32.156**) on **port 4444** at 2:14 AM. Over the next 47 minutes, approximately **120 MB of data** was transferred outbound. The host also made DNS queries for `nmap.org` and `pastebin.com`, then began sending SYN packets to six other internal machines.

**Goal:** Identify what happened, classify the threat, document indicators of compromise, and recommend response actions.

---

## Network Layout

| Host | IP Address | Role |
|---|---|---|
| Suspect workstation | 192.168.1.105 | Compromised internal host |
| External server | 45.33.32.156 | Attacker C2 infrastructure |
| Internal hosts | 192.168.1.106 – .111 | Port scan targets |
| DNS server | 8.8.8.8 | Google public DNS |

---

## Investigation

### Step 1 — Capture the traffic

```bash
# Capture all traffic from the suspect host and save to file
sudo tcpdump -i eth0 host 192.168.1.105 -w suspect.pcap

# Read it back with full timestamps
tcpdump -r suspect.pcap -n -tttt
```

### Step 2 — What the capture showed

```
02:14:03  192.168.1.105 --> 45.33.32.156   TCP  SYN      port 4444
02:14:03  45.33.32.156  --> 192.168.1.105  TCP  SYN-ACK  port 4444
02:14:03  192.168.1.105 --> 45.33.32.156   TCP  ACK      (connection established)
02:14:04  192.168.1.105 --> 45.33.32.156   TCP  PSH      40 MB of data sent outbound
...session continues for 47 minutes...

02:14:03  192.168.1.105 --> 8.8.8.8        UDP  DNS query: nmap.org
02:14:04  192.168.1.105 --> 8.8.8.8        UDP  DNS query: pastebin.com

02:15:01  192.168.1.105 --> 192.168.1.106  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.107  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.108  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.109  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.110  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.111  TCP  SYN  port 22
```

---

## Findings

### Finding 1 — C2 Connection on Port 4444 | HIGH

Port 4444 has no legitimate business use and is the default port for Metasploit reverse shells. The completed TCP 3-way handshake (SYN → SYN-ACK → ACK) confirms a live session was established with the external host. This is a strong indicator the workstation was running a remote access tool controlled by the attacker.

```bash
# Isolate the C2 traffic
tcpdump -r suspect.pcap port 4444

# View the data payload to check for cleartext commands
tcpdump -r suspect.pcap -A -s 200 port 4444
```

**MITRE ATT&CK:** T1571 — Non-Standard Port

---

### Finding 2 — Data Exfiltration | HIGH

Approximately 40 MB of data was sent from the internal host to the external C2 server. The traffic direction and volume indicate the attacker was pulling files off the machine rather than just sending commands.

```bash
# Show large outbound packets (likely data chunks being exfiltrated)
tcpdump -r suspect.pcap "len > 1400 and src host 192.168.1.105"
```

**MITRE ATT&CK:** T1041 — Exfiltration Over C2 Channel

---

### Finding 3 — Internal Port Scan | MEDIUM

Six sequential SYN packets to hosts .106 through .111 on port 22 (SSH) within one second is a port scan. The attacker is probing the internal network to find other machines they can access. This behaviour is called **lateral movement** — moving from one compromised host to others.

```bash
# Find all SYN-only packets from the suspect host
tcpdump -r suspect.pcap "tcp[tcpflags] == tcp-syn and src host 192.168.1.105"
```

**MITRE ATT&CK:** T1046 — Network Service Discovery

---

### Finding 4 — Suspicious DNS Queries | MEDIUM

DNS queries for `nmap.org` and `pastebin.com` at 2 AM are not normal workstation behaviour. Nmap is a port scanning tool — querying its domain suggests the attacker may have downloaded it. Pastebin is frequently used to host malicious scripts that can be fetched with a single command.

```bash
# Show all DNS queries from the suspect host
tcpdump -r suspect.pcap "udp port 53 and src host 192.168.1.105"
```

**MITRE ATT&CK:** T1105 — Ingress Tool Transfer

---

## Indicators of Compromise (IOCs)

| Type | Value | Severity |
|---|---|---|
| External IP (C2) | 45.33.32.156 | High |
| Compromised host | 192.168.1.105 | High |
| Malicious port | TCP 4444 | High |
| DNS query | nmap.org | Medium |
| DNS query | pastebin.com | Medium |
| Scan targets | 192.168.1.106 – .111 | Medium |

---

## Recommended Response Actions

1. **Isolate 192.168.1.105** — move to a quarantine VLAN. Do not power it off as memory forensics may be needed.
2. **Block 45.33.32.156** — add a deny rule at the perimeter firewall for all traffic to and from this IP.
3. **Preserve evidence** — copy the PCAP and all relevant logs to read-only storage before any remediation work begins.
4. **Check the scanned hosts** — review .106 through .111 for any unexpected new connections or logins after 02:15.
5. **Assess the exfiltrated data** — determine what was on the host and whether a data breach notification is required.
6. **Reset credentials** — any accounts that had active sessions on the compromised host should be treated as exposed.

---

## Running the Analysis Script

The included `analysis.py` script walks through the same logic above in plain Python.

```bash
python analysis.py
```

No additional libraries required — runs on standard Python 3.

---

## Repository Structure

```
packet-analysis-lab/
├── README.md        ← full investigation writeup (this file)
├── analysis.py      ← Python script walking through the analysis logic
└── tcpdump_ref.sh   ← tcpdump commands used in the investigation
```

---

## Concepts Covered

- TCP 3-way handshake (SYN / SYN-ACK / ACK)
- Port-based threat detection
- Data exfiltration indicators
- Internal network lateral movement
- DNS as an early warning layer
- MITRE ATT&CK framework mapping
- Evidence preservation and containment sequencing

---

## References

- [Google Cybersecurity Certificate](https://www.coursera.org/professional-certificates/google-cybersecurity)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [tcpdump Documentation](https://www.tcpdump.org/manpages/tcpdump.1.html)
- [Wireshark Documentation](https://www.wireshark.org/docs/)
