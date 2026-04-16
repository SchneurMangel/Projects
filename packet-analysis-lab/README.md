# Packet Analysis Lab

**Google Cybersecurity Certificate | Portfolio Project**  
**Author:** Schneur Mangel  
**Tools:** tcpdump · Wireshark · Python

---

## Overview

This project walks through a network intrusion investigation using packet analysis. It covers skills from the Google Cybersecurity Certificate including reading packet captures, identifying suspicious traffic patterns, and documenting findings.

---

## Scenario

An alert fired at 2:16 AM for unusual outbound traffic from an internal workstation.

A workstation at **192.168.1.105** connected to an unknown external IP (**45.33.32.156**) on **port 4444** at 2:14 AM. Around 40 MB of data was sent outbound over the next 47 minutes. The workstation also looked up suspicious domains and then sent connection requests to six other internal machines.

---

## Network Details

| Host | IP Address | Notes |
|---|---|---|
| Suspect workstation | 192.168.1.105 | Source of suspicious traffic |
| External server | 45.33.32.156 | Unknown — not a trusted destination |
| Internal hosts | 192.168.1.106 – .111 | Targeted by the suspect host |
| DNS server | 8.8.8.8 | Google public DNS |

---

## Step 1 — Capture the traffic

```bash
# Capture traffic from the suspect host and save to a file
sudo tcpdump -i eth0 host 192.168.1.105 -w suspect.pcap

# Read the file back with timestamps
tcpdump -r suspect.pcap -n -tttt
```

---

## Step 2 — What the capture showed

```
02:14:03  192.168.1.105 --> 45.33.32.156   TCP  SYN      port 4444
02:14:03  45.33.32.156  --> 192.168.1.105  TCP  SYN-ACK  port 4444
02:14:03  192.168.1.105 --> 45.33.32.156   TCP  ACK      connection open
02:14:04  192.168.1.105 --> 45.33.32.156   TCP  PSH      40 MB sent outbound

02:14:03  192.168.1.105 --> 8.8.8.8        UDP  DNS  nmap.org
02:14:04  192.168.1.105 --> 8.8.8.8        UDP  DNS  pastebin.com

02:15:01  192.168.1.105 --> 192.168.1.106  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.107  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.108  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.109  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.110  TCP  SYN  port 22
02:15:01  192.168.1.105 --> 192.168.1.111  TCP  SYN  port 22
```

---

## Findings

### Finding 1 — Suspicious connection on port 4444 | HIGH

Port 4444 is not used by any normal business application. It is commonly associated with attacker tools that allow remote control of a machine. The SYN, SYN-ACK, ACK sequence shows the connection was fully established.

```bash
tcpdump -r suspect.pcap port 4444
```

**MITRE ATT&CK:** [T1571 — Non-Standard Port](https://attack.mitre.org/techniques/T1571/)

---

### Finding 2 — Large outbound data transfer | HIGH

40 MB was sent from the internal host to the external server. Data flowing outward in large amounts suggests files were being copied off the machine by the attacker.

```bash
tcpdump -r suspect.pcap "len > 1400 and src host 192.168.1.105"
```

**MITRE ATT&CK:** [T1041 — Exfiltration Over C2 Channel](https://attack.mitre.org/techniques/T1041/)

---

### Finding 3 — Internal port scan | MEDIUM

The suspect host sent SYN packets to six different internal machines on port 22 (SSH) within one second. This is a sign the attacker was looking for other machines on the network to access.

```bash
tcpdump -r suspect.pcap "tcp and src host 192.168.1.105"
```

**MITRE ATT&CK:** [T1046 — Network Service Discovery](https://attack.mitre.org/techniques/T1046/)

---

### Finding 4 — Suspicious DNS queries | MEDIUM

The workstation looked up `nmap.org` and `pastebin.com` at 2 AM. Nmap is a network scanning tool. Pastebin is often used to store and download malicious scripts. Neither lookup is normal for a workstation at that hour.

```bash
tcpdump -r suspect.pcap "udp port 53 and src host 192.168.1.105"
```

**MITRE ATT&CK:** [T1105 — Ingress Tool Transfer](https://attack.mitre.org/techniques/T1105/)

---

## Indicators of Compromise (IOCs)

| Type | Value | Severity |
|---|---|---|
| External IP | 45.33.32.156 | High |
| Compromised host | 192.168.1.105 | High |
| Port | TCP 4444 | High |
| DNS query | nmap.org | Medium |
| DNS query | pastebin.com | Medium |
| Scan targets | 192.168.1.106 – .111 | Medium |

---

## Recommended Actions

1. Disconnect 192.168.1.105 from the network
2. Block 45.33.32.156 at the firewall
3. Save the packet capture as evidence before making any changes
4. Check hosts .106 through .111 for any new unexpected connections
5. Review what files were stored on the compromised machine

---

## Running the Python Script

The included `analysis.py` applies the same detection logic above in Python.

```bash
python analysis.py
```

No extra libraries needed runs on standard Python 3.

---

## Files

```
packet-analysis-lab/
├── README.md        ← this file
├── analysis.py      ← Python script that checks for the four findings
└── tcpdump_ref.sh   ← tcpdump commands used in this investigation
```

---

## What I Learned

- How the TCP 3-way handshake works (SYN, SYN-ACK, ACK)
- How to use tcpdump to capture and filter network traffic
- How to identify suspicious ports, large outbound transfers, and port scans
- How to use the MITRE ATT&CK framework to classify findings
- How to document findings and recommend response actions

---

## References

- [Google Cybersecurity Certificate](https://www.coursera.org/professional-certificates/google-cybersecurity)
- [MITRE ATT&CK Framework](https://attack.mitre.org/)
- [tcpdump Documentation](https://www.tcpdump.org/manpages/tcpdump.1.html)
- [Wireshark Documentation](https://www.wireshark.org/docs/)
