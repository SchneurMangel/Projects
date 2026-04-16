# SIEM Investigation Lab

**Google Cybersecurity Certificate | Portfolio Project**  
**Author:** Schneur Mangel  
**Tool:** Chronicle SIEM

---

## What is a SIEM

A SIEM collects logs from every device on the network and puts them in one place. Without it you would have to log into each device separately to find out what happened. Chronicle uses a format called UDM where every log uses the same field names, which makes it easier to search and compare events across different sources.

---

## Scenario

An alert fired at 11:47 PM for unusual login activity on the VPN server.

An external IP (**185.220.101.45**) made 47 failed login attempts in under two minutes. On the 48th attempt the login succeeded.

The goal was to confirm the attack was real, find out which account was compromised, and check what the attacker did after getting in.

---

## What I found

**Step 1 — Confirmed the brute force**

I searched for failed logins from the attacker's IP and got 47 results back. The alert was real.

**Step 2 — Confirmed the attacker got in**

I changed the search to look for successful logins from the same IP and got one result. The attacker logged in successfully at 23:48:51.

**Step 3 — Found the compromised account**

The successful login result showed the account `jsmith` was accessed. This account belongs to a regular employee and should not be logging in at midnight from an external IP.

**Step 4 — Checked what they did after**

I searched for network activity from the attacker's IP after the login. There were two connections — one to an internal file server and one large outbound transfer. This suggests data may have been taken.

---

## Indicators of Compromise

| What | Value |
|---|---|
| Attacker IP | 185.220.101.45 |
| Compromised account | jsmith |
| Failed login attempts | 47 |
| Time of successful login | 23:48:51 |
| Suspicious outbound transfer | 200 MB |

---

## Recommended actions

1. Disable the jsmith account
2. Block 185.220.101.45 at the firewall
3. Investigate what was on the file server that was accessed
4. Turn on account lockout so brute force attempts get blocked automatically next time

---

## Files

```
siem-lab/
├── README.md              ← this file
└── chronicle_queries.md   ← the five Chronicle queries used in this investigation
```

---

## What I learned

- How a SIEM collects and organises logs from different sources
- How to write basic Chronicle UDM queries
- How to confirm a brute force attack using login event data
- How to identify a compromised account in the logs
- How to check what an attacker did after getting in

---

## References

- [Google Cybersecurity Certificate](https://www.coursera.org/professional-certificates/google-cybersecurity)
- [MITRE ATT&CK — Brute Force](https://attack.mitre.org/techniques/T1110/)
- [Chronicle SIEM Documentation](https://cloud.google.com/chronicle/docs)
