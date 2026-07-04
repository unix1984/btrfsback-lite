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
