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

btrfsback-lite is a lightweight, production-ready backup and replication toolkit built entirely in **pure Bash**, relying on native **BTRFS snapshot** and **btrfs send/receive** mechanisms.

It is designed for simplicity, auditability, and predictable behavior in production Linux environments.

Typical use cases:

- Root filesystem backups (/)
- LXD container snapshotting
- Incremental off-site replication
- Automated retention policies
- Multi-volume backup orchestration

---

## Features

| Feature | Description |
|----------|-------------|
| Incremental replication | Uses native `btrfs send/receive` |
| Snapshot automation | Scheduled snapshot creation |
| Retention management | Local and remote cleanup policies |
| Secure transfer | SSH-based replication |
| Email reporting | Execution summary after each run |
| Error visibility | Full stdout/stderr logging |
| Pure Bash | No external frameworks |
| Monitoring ready | Hooks for Nagios / Zabbix |

---

## Requirements

### System packages

```bash
sudo apt update
sudo apt install -y coreutils tree bsd-mailx postfix pv gawk
```

Prerequisites
BTRFS filesystem
btrfs-progs installed
Passwordless SSH access to backup host
Pre-created destination directories

### Supported distributions:

Ubuntu 22.04+
Debian 11 / 12
Any modern Linux with BTRFS support

Installation
```
wget -O /usr/local/sbin/btrfsback-lite https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite && wget -O /usr/local/sbin/autosnaps-btrfsback-lite.sh https://raw.githubusercontent.com/unix1984/btrfsback-lite/refs/heads/main/autosnaps-btrfsback-lite.sh && wget -O /etc/btrfsback-lite.cfg https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite.cfg && chmod +x /usr/local/sbin/btrfsback-lite /usr/local/sbin/autosnaps-btrfsback-lite.sh
```

CLI Reference
```
-s, --subvol         Source BTRFS subvolume
-l, --local-dir      Local snapshot directory
-d, --daily-local    Number of local snapshots to keep
-H, --remote-host    Remote backup host (IP/FQDN)
-r, --remote-dir     Remote snapshot directory
-D, --daily-remote   Number of remote snapshots to keep
-h, --help           Show help
```

Manual Usage
```
btrfsback-lite \
  --subvol / \
  --local-dir /mnt/sda2/autosnap-test \
  --daily-local 4 \
  --remote-host 10.5.5.4 \
  --remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test \
  --daily-remote 6
```
Cron Example
```
0 23 * * * root /usr/local/sbin/btrfsback-lite \
--subvol / \
--local-dir /mnt/sda2/autosnap-test \
--daily-local 4 \
--remote-host 10.5.5.4 \
--remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test \
--daily-remote 6 \
> /var/log/btrfsback-lite.log 2>&1
```

Multi-Volume Orchestration
```
0 1 * * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg DAILY
0 3 * * 0 root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg WEEKLY
0 4 1 * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg MONTHLY
0 5 1 1 * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg YEARLY
```

Central Configuration
```
/usr/local/sbin/btrfsback-lite --subvol /mnt/sda3/containers/container1 --local-dir /mnt/sda3/autosnap/container1 --daily-local 10 --remote-host 10.5.5.4 --remote-dir /backup/container1 --daily-remote 15
/usr/local/sbin/btrfsback-lite --subvol /mnt/sda3/containers/container2 --local-dir /mnt/sda3/autosnap/container2 --daily-local 10 --remote-host 10.5.5.4 --remote-dir /backup/container2 --daily-remote 15
/usr/local/sbin/btrfsback-lite --subvol /mnt/sda3/containers/container3 --local-dir /mnt/sda3/autosnap/container3 --daily-local 10 --remote-host 10.5.5.4 --remote-dir /backup/container3 --daily-remote 15
```

## btrlb (Local-only version, no replication.)

Lightweight tool for local snapshot rotation only (no replication).

Install
```
wget -O /usr/local/sbin/btrlb https://raw.githubusercontent.com/unix1984/btrfs/main/btrlb
chmod +x /usr/local/sbin/btrlb
```
Example
```
btrlb --subvol / --local-dir /mnt/sda2/autosnap-test --daily-local 10
```

Cron
```
0 23 * * * root /usr/local/sbin/btrlb \
--subvol / \
--local-dir /mnt/sda2/autosnap-test \
--daily-local 10 \
> /var/log/btrlb.log 2>&1
```

Architecture
BTRFS snapshot creation per subvolume
Retention-based cleanup system
Incremental replication via btrfs send/receive
SSH-based secure transport
Centralized logging and reporting
Design Philosophy
Minimalism over complexity
Pure Linux tooling only
Fully transparent Bash implementation
No external dependencies beyond system packages
Deterministic and predictable behavior
License

MIT
