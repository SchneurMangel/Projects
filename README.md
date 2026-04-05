https://roadmap.sh/projects/server-stats
Goal of this project is to write a script to analyse server performance stats.

server-stats.sh
A lightweight Bash script that gives you an instant snapshot of your Linux server's health — no dependencies, no installs required.
What it reports:

CPU usage (live-sampled)
Memory & swap (used / free / available)
Disk usage across all filesystems
Top 5 processes by CPU and memory
Network interfaces, uptime, load average, and logged-in users
Recent failed login attempts (requires root)

Usage:
bashchmod +x server-stats.sh
bash server-stats.sh        # standard output
sudo bash server-stats.sh   # includes failed login attempts
