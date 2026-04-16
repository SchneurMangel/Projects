# Incident Handler's Journal
# Google Cybersecurity Certificate - Portfolio Project
# Author: Schneur Mangel

---

## Entry 1

**Date:** April 15, 2026  
**Analyst:** Schneur Mangel  
**Incident type:** Brute force attack / unauthorized access  

---

### What happened

At 11:47 PM an alert fired in Chronicle SIEM for unusual login activity on the VPN server. An external IP address made 47 failed login attempts in under two minutes. On the 48th attempt the login succeeded using the employee account jsmith.

After getting in the attacker connected to an internal file server and transferred approximately 200 MB of data outbound. The attack was detected through SIEM log analysis and packet capture review.

---

### The 5 W's

**Who:**  
An unknown external attacker using IP address 185.220.101.45. The attacker gained access through the employee account jsmith, which belongs to a regular member of staff.

**What:**  
A brute force attack against the VPN server. The attacker tried 47 passwords until one worked. After getting in they accessed an internal file server and sent a large amount of data outside the network.

**Where:**  
The attack entered through the VPN server. Once inside the attacker moved to an internal file server. Data was transferred to an unknown external destination.

**When:**  
- 23:47:02 — first failed login attempt  
- 23:47:02 to 23:48:10 — 47 failed attempts over approximately one minute  
- 23:48:51 — successful login  
- 23:49:00 onwards — attacker activity on internal network  

**Why:**  
The jsmith account had no lockout policy. This allowed the attacker to make unlimited login attempts without being blocked. A stronger password or a lockout policy after a few failed attempts would have stopped this attack.

---

### Tools used

- **Chronicle SIEM** — used to search login event logs, identify the brute force attempts, confirm the successful login, and find network activity after the breach
- **tcpdump / Wireshark** — used to review packet captures and confirm suspicious outbound traffic

---

### What I found

1. 47 failed login attempts from 185.220.101.45 confirmed in Chronicle
2. One successful login at 23:48:51 using the jsmith account
3. Connection to internal file server after login
4. 200 MB transferred outbound possible data exfiltration

---

### Response actions taken

1. Disabled the jsmith account
2. Blocked 185.220.101.45 at the firewall
3. Saved packet capture and SIEM logs as evidence
4. Flagged the internal file server for review
5. Reported to security manager

---

### Recommendations

- Enable account lockout after 5 failed login attempts
- Require stronger passwords or multi-factor authentication on VPN accounts
- Set up alerts for large outbound transfers
- Review all VPN accounts for similar weak password issues

---

### Indicators of Compromise (IOCs)

| What | Value |
|---|---|
| Attacker IP | 185.220.101.45 |
| Compromised account | jsmith |
| Entry point | VPN server |
| Internal target | File server |
| Outbound transfer | ~200 MB |

---

### Reflections

This incident showed me how important account lockout policies are. Without one, a brute force attack can keep trying indefinitely. The SIEM made it straightforward to confirm what happened by searching login events step by step first looking at failed attempts, then successful ones, then what came after. The hardest part was piecing together the timeline across both the SIEM logs and the packet capture to get the full picture.
