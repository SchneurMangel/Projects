# Chronicle SIEM Queries
# Google Cybersecurity Certificate - Portfolio Project
# Author: Schneur Mangel
#
# These queries were written to investigate an SSH brute force attack.
# Each query answers one specific question in the investigation.
# Chronicle uses UDM (Unified Data Model) which means every log from
# every device uses the same field names, making it easy to search across
# multiple sources at once.


---

## Query 1 — Confirm the brute force attack

**Question:** Did the attacker really send 47 failed login attempts?

```
metadata.event_type = "USER_LOGIN"
security_result.action = "BLOCK"
principal.ip = "185.220.101.45"
```

**What each line does:**
- `metadata.event_type = "USER_LOGIN"` — only show login events
- `security_result.action = "BLOCK"` — only show failed attempts
- `principal.ip = "185.220.101.45"` — only show events from the attacker's IP

**What to look for:** If this returns 47 results, the alert is confirmed real.

---

## Query 2 — Check if the attacker got in

**Question:** Did any of those attempts succeed?

```
metadata.event_type = "USER_LOGIN"
security_result.action = "ALLOW"
principal.ip = "185.220.101.45"
```

**What changed:** `BLOCK` became `ALLOW` now we are looking for successful logins instead of failed ones.

**What to look for:** If this returns one result, the attacker got in. The `target.user` field in that result will show which account was compromised.

---

## Query 3 - Find the compromised account

**Question:** Which user account did the attacker break into?

```
metadata.event_type = "USER_LOGIN"
security_result.action = "ALLOW"
principal.ip = "185.220.101.45"
target.user.userid != ""
```

**What changed:** Added `target.user.userid != ""` to make sure the result includes the username field.

**What to look for:** The `target.user.userid` field will show the account name. This account should be locked immediately.

---

## Query 4 — Check what the attacker did after getting in

**Question:** Did the attacker move around the network or steal any data?

```
metadata.event_type = "NETWORK_CONNECTION"
principal.ip = "185.220.101.45"
```

**What changed:** Switched from `USER_LOGIN` to `NETWORK_CONNECTION` now we are looking at all network activity from that IP, not just logins.

**What to look for:**
- Connections to internal servers possible lateral movement
- Large outbound transfers possible data exfiltration
- No results — attacker may not have done anything after getting in

---

## Query 5 — Check the timeline

**Question:** When exactly did each event happen?

```
metadata.event_type = "USER_LOGIN"
principal.ip = "185.220.101.45"
```

**What this does:** Removes the BLOCK/ALLOW filter so you see all login events both failed and successful in chronological order. This lets you build a timeline of the attack from first attempt to successful login.

**What to look for:** The timestamps on each event. A gap between the last failed attempt and the successful one might indicate the attacker paused and changed their approach.

---

## UDM Field Reference

These are the fields used in the queries above.

| Field | What it means |
|---|---|
| `metadata.event_type` | What type of event this is (login, network connection, etc.) |
| `security_result.action` | Whether the action was allowed or blocked |
| `principal.ip` | The IP address that initiated the action |
| `target.user.userid` | The username being targeted |
| `principal.hostname` | The hostname of the source machine |
| `target.ip` | The IP address being connected to |
