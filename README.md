# btrfsback-lite

<p align="center">
Lightweight BTRFS snapshot and replication toolkit written in pure Bash
</p>

<p align="center">

![Linux](https://img.shields.io/badge/Linux-supported-success)
![Bash](https://img.shields.io/badge/Bash-100%25-blue)
![BTRFS](https://img.shields.io/badge/BTRFS-snapshots-green)
![License](https://img.shields.io/badge/license-MIT-orange)

</p>

---

## Overview

btrfsback-lite is a lightweight and fully auditable backup system based on native BTRFS snapshot and send/receive functionality.

It is designed for production Linux environments where simplicity, transparency, and reliability are more important than complex frameworks.

Typical use cases:

- Root filesystem backups (/)
- LXD container snapshots
- Incremental off-site replication
- Automated retention policies
- Server fleet backup orchestration

---

## Key Features

| Feature | Description |
|----------|-------------|
| Incremental replication | Uses native `btrfs send/receive` |
| Snapshot automation | Scheduled local snapshots |
| Retention control | Configurable local and remote cleanup |
| SSH replication | Secure remote transfer via SSH |
| Email reporting | Full execution summary per run |
| Error visibility | Captures stdout/stderr for debugging |
| Pure Bash | No external runtime dependencies |
| Monitoring ready | Hooks for Nagios / Zabbix |

---

## Requirements

### System packages

```bash
sudo apt update
sudo apt install -y coreutils tree bsd-mailx postfix pv gawk lolcat

Prerequisites
BTRFS filesystem
Passwordless SSH access to backup server
Pre-created destination directories
Linux system with btrfs-progs

Supported distributions:

Ubuntu 22.04+
Debian 11 / 12
Any modern Linux with BTRFS support
Installation
Install main tool
sudo wget -O /usr/local/sbin/btrfsback-lite \
https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite

sudo chmod +x /usr/local/sbin/btrfsback-lite
Install configuration
sudo wget -O /etc/btrfsback-lite.cfg \
https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite.cfg
CLI Reference
-s, --subvol         Source BTRFS subvolume
-l, --local-dir      Local snapshot directory
-d, --daily-local    Number of local snapshots to retain
-H, --remote-host    Remote backup host
-r, --remote-dir     Remote snapshot directory
-D, --daily-remote   Number of remote snapshots to retain
-h, --help           Show help
Manual Usage
btrfsback-lite \
  --subvol / \
  --local-dir /mnt/sda2/autosnap-test \
  --daily-local 4 \
  --remote-host 10.5.5.4 \
  --remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test \
  --daily-remote 6
Cron Setup
0 23 * * * root /usr/local/sbin/btrfsback-lite \
--subvol / \
--local-dir /mnt/sda2/autosnap-test \
--daily-local 4 \
--remote-host 10.5.5.4 \
--remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test \
--daily-remote 6 \
> /var/log/btrfsback-lite.log 2>&1
Multi-Volume Orchestration

For multiple containers or subvolumes, use the orchestration wrapper.

Scheduler
0 1 * * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg DAILY
0 3 * * 0 root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg WEEKLY
0 4 1 * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg MONTHLY
0 5 1 1 * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg YEARLY
Central Configuration File
/usr/local/sbin/btrfsback-lite \
--subvol /mnt/sda3/containers/container1 \
--local-dir /mnt/sda3/autosnap/container1 \
--daily-local 10 \
--remote-host 10.5.5.4 \
--remote-dir /backup/lxd/container1 \
--daily-remote 15

/usr/local/sbin/btrfsback-lite \
--subvol /mnt/sda3/containers/container2 \
--local-dir /mnt/sda3/autosnap/container2 \
--daily-local 10 \
--remote-host 10.5.5.4 \
--remote-dir /backup/lxd/container2 \
--daily-remote 15
btrlb (Local-only version)

A simplified version of the tool that performs local snapshot rotation only without replication.

Install
wget -O /usr/local/sbin/btrlb \
https://raw.githubusercontent.com/unix1984/btrfs/main/btrlb

chmod +x /usr/local/sbin/btrlb
Example
btrlb --subvol / --local-dir /mnt/sda2/autosnap-test --daily-local 10
Cron
0 23 * * * root /usr/local/sbin/btrlb \
--subvol / \
--local-dir /mnt/sda2/autosnap-test \
--daily-local 10 \
> /var/log/btrlb.log 2>&1
Architecture
Local snapshot creation via BTRFS subvolume snapshots
Retention-based cleanup system
Incremental transfer via btrfs send/receive
Optional remote pruning
SSH-based secure transport
Logging and reporting pipeline
Design Philosophy
Minimalism over complexity
Native Linux tooling only
No external dependencies beyond standard system packages
Fully auditable Bash implementation
Predictable and deterministic behavior
License

MIT License
