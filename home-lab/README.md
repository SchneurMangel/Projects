Home Lab Portfolio
Shneur Mangel
schneurmangel@gmail.com
CompTIA Security+
Google Cybersecurity Certificate
Google IT Certificate

About This Lab
This portfolio documents the hands-on exercises I completed in my IT and cybersecurity home lab. I built the lab from scratch using UTM on my MacBook Pro M3 Pro, setting up both a Windows VM and a Linux VM and connecting them together to create a real practice environment. Everything in here was done by me, hands on, step by step.
The goal was to get real experience with the tools and techniques I had been learning about. Not just reading about them but actually running the commands, seeing the output, and understanding what it all means. I made mistakes along the way and figured them out, which is where most of the actual learning happened.

Lab Overview
ModuleToolsStatusSIEM QueriesSplunkCompleteVM Setup and Home Lab EnvironmentUTM, Ubuntu 26.04, WindowsCompletePacket AnalysisWireshark, tcpdumpCompleteNetwork ScanningNmapCompleteLog Analysisgrep, auth.logComplete

Module 1: Setting Up the Home Lab Environment
To start off, I created two virtual machines, a Windows VM and a Linux VM, and connected them together to build the home lab environment. I used UTM on my MacBook Pro M3 Pro with QEMU virtualization, and installed Ubuntu 26.04 LTS ARM64 as the Linux machine.
One thing I ran into right away was that the standard Ubuntu download is for x86 processors, which doesn't work on Apple Silicon. I had to find the ARM64 version specifically for M-series Macs. Small thing but the kind of real-world detail you don't get from just reading.
What I Set Up

Windows VM, already running from a previous setup
Ubuntu 26.04 LTS ARM64 VM, 2 CPU cores, 4096 MB RAM, 50 GB storage, OpenGL acceleration
Installed tools: Wireshark, tcpdump, Nmap, Python3, net-tools, curl, wget
Added my user to the wireshark group so I could capture packets without running sudo every time

Connecting the Two VMs
Both VMs sit on UTM's shared network in the 192.168.64.0/24 range.
Ubuntu VM:  192.168.64.4
Windows VM: 192.168.64.2
Gateway:    192.168.64.1  (UTM virtual router)
Network:    192.168.64.0/24
The first ping attempt failed, 100% packet loss. Windows blocks ICMP by default so it wasn't responding to pings even though it was online. I had to add a Windows Firewall rule to allow inbound ICMP. That's a real-world thing, Windows machines often look offline to a ping sweep because of this default setting.
netsh advfirewall firewall add rule name="Allow ICMP" protocol=icmpv4:8,any dir=in action=allow

Module 2: Packet Analysis
In this module I captured and analyzed live network traffic using tcpdump and Wireshark. The idea is to actually see what's happening on the network at the packet level. Not just know that traffic is flowing but understand exactly what kind of traffic, between who, and what protocol.
ICMP Capture with tcpdump
I started by capturing ping traffic between my two VMs. Running tcpdump in one terminal while pinging from the other, I could see every echo request going out and every echo reply coming back in real time.
bashsudo tcpdump -i any icmp -v
What I observed:

Captured 4 ICMP echo request / echo reply pairs between the two VMs
Source: 192.168.64.4 (Ubuntu) to Destination: 192.168.64.2 (Windows)
Each request/reply pair is one complete ping round trip
tcpdump captures both directions of traffic simultaneously

DNS Capture with tcpdump
Next I captured DNS traffic. Every time you type a domain name, your computer has to look up the IP address first. I ran nslookup for a few domains and watched the queries and responses in real time.
bashsudo tcpdump -i any port 53 -n
What I observed:

Each nslookup generates multiple packets, an A query for IPv4 and a AAAA query for IPv6, plus replies for both
DNS resolution path: Ubuntu (192.168.64.4) to local resolver (127.0.0.53) to gateway (192.168.64.1) to internet
google.com resolved to 142.251.41.174 (IPv4)
github.com resolved to 140.82.112.3 (IPv4, no IPv6 support)

Saving a Capture to File
I captured 30 seconds of live traffic to a .pcap file, then read it back. This is how analysts save network activity during an incident to analyze later.
bashsudo tcpdump -i any -w /tmp/capture.pcap -G 30 -W 1
sudo tcpdump -r /tmp/capture.pcap -n | head -50
Reading the file back I identified four protocols: DNS, ICMP, ARP, and IPv6. The ARP traffic was particularly interesting. It showed the VMs discovering each other's MAC addresses before they could communicate, which is something that happens automatically in the background on any network.
Wireshark GUI Analysis
After tcpdump I switched to Wireshark for a visual look at the same traffic. The main advantage of Wireshark is being able to filter thousands of packets down to exactly what you're looking for and then click into individual packets to inspect every layer.
Filters used:
FilterWhat it showedicmpPing request/reply pairs, gaps in packet numbers show filtered protocolsdnsA and AAAA queries per domaintcp.flags.syn == 1TCP connection initiations, first step of the 3-way handshake
Running curl http://example.com generated a SYN packet to 91.189.91.96 on port 80 (unencrypted HTTP).
Every packet has layers: Ethernet, then IP, then the protocol layer. The checksum field in each packet proves it wasn't modified in transit. Port 80 is unencrypted HTTP, port 443 is encrypted HTTPS.

Module 3: Network Scanning with Nmap
In this module I used Nmap to scan my home lab network. The goal was to understand what's visible on the network, what hosts are alive, what ports are open, what software is running, and what OS. This is reconnaissance, the first step in both attacking and defending a network.
Ping Sweep
I started with a ping sweep to discover what devices were on the network.
bashnmap -sn 192.168.64.0/24
Found 2 hosts: 192.168.64.1 (UTM gateway) and 192.168.64.4 (Ubuntu VM). The Windows VM at 192.168.64.2 was invisible because Windows blocks ICMP by default. Had to use the -Pn flag to scan it directly and confirm it was online.
Key lesson: a ping sweep is a starting point, not a complete picture. Hosts can be fully online but hidden if they block ICMP.
Port Scanning and Service Detection
I installed SSH and Apache on the Ubuntu VM to create some open ports, then scanned to see what Nmap could find.
bashnmap -sT 192.168.64.4          # basic TCP connect scan
nmap -sV 192.168.64.4          # version detection
sudo nmap -O 192.168.64.4      # OS fingerprinting
sudo nmap -A 192.168.64.4      # aggressive scan
Results with SSH and Apache running:
Port 22  TCP  open  ssh   OpenSSH 10.2p1
Port 80  TCP  open  http  Apache httpd 2.4.66
OS fingerprinting came back as Linux at 96% confidence, which is correct. It couldn't pinpoint the exact kernel version because Ubuntu 26.04 is newer than Nmap's fingerprint database.
Traceroute showed 0 hops when scanning my own VM since both are on the same machine. Scanning the Windows VM would show 1 hop through the UTM gateway.
Version detection matters because knowing the exact software version lets an attacker search CVE databases for known exploits against that specific version. This is why keeping software updated is important.
Saving Results and Cleanup
bashsudo nmap -A 192.168.64.4 -oA ~/nmap_results
# Creates: nmap_results.nmap, nmap_results.xml, nmap_results.gnmap
After finishing I stopped and disabled both services. SSH required an extra step in Ubuntu 26.04 because of socket-based activation. Had to stop ssh.socket separately, otherwise SSH could still be restarted even after stopping the service.

Module 4: Log Analysis
For log analysis I focused on reading and filtering auth.log, the Linux log file that records all login attempts, sudo commands, and SSH sessions. The goal was to understand what a normal log looks like versus what suspicious activity looks like.
Reading Auth Logs
bashsudo tail -50 /var/log/auth.log
sudo grep -i 'failed\|invalid\|unauthorized' /var/log/auth.log
Each auth.log entry contains the timestamp, hostname, username, terminal session (TTY), working directory, and the exact command run with sudo.
I found my own failed login attempts from when I forgot my password after setting up the VM. The entries were spaced out over time, which is normal. Brute force attacks look different, you get hundreds of failures clustered within seconds all from the same IP address, all automated. That clustering pattern is what triggers alerts in a SIEM.
One detail I noticed: the log recorded the command I used to read the log. auth.log logs itself being read.
Key log files in Linux:
Log FileWhat it contains/var/log/auth.logLogin attempts, sudo usage, SSH sessions/var/log/syslogGeneral system messages/var/log/apache2/access.logWeb server HTTP requests
I also have hands-on experience with Python scripting for network automation from a separate packet analysis lab. The next step is combining those Python skills with log analysis to build an automated log parser that flags brute force activity above a configurable threshold.

What I Took Away From This
The biggest thing I learned doing this hands on is that everything connects. When I was doing the Nmap scan and saw SSH on port 22, I already understood from the packet analysis module what SSH traffic actually looks like at the packet level. When I read the auth.log and saw failed login attempts, I understood from the Nmap module why port 22 being open matters. It's not just a list of tools, it's a full picture of how networks and security work together.
I also learned that real troubleshooting is just working through problems one step at a time. The Windows VM not responding to pings, SSH not stopping because of socket activation, the permission denied error when saving pcap files. None of those were in any tutorial. You figure them out, you understand why they happened, and you remember them.

Shneur Mangel | schneurmangel@gmail.com
