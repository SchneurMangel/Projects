https://roadmap.sh/projects/server-stats
Goal of this project is to write a script to analyse server performance stats.

server-stats.sh
A lightweight Bash script that gives you an instant snapshot of your server's health — no dependencies, no installs required.
What it reports:

CPU usage (live-sampled)
Memory & swap (used / free / available)
Disk usage across all filesystems
Top 5 processes by CPU and memory
Network interfaces, uptime, load average, and logged-in users
Recent failed login attempts (requires sudo)


Files
Platform
server-stats.sh Linux
mac-stats.sh macOS

Usage
Linux:
bashchmod +x server-stats.sh
bash server-stats.sh

# Full output including failed logins
sudo bash server-stats.sh
macOS:
bashchmod +x mac-stats.sh
bash mac-stats.sh

# Full output including failed logins
sudo bash mac-stats.sh
