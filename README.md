````markdown
# 🚀 btrfsback-lite

> **A lightweight, production-ready BTRFS snapshot & replication toolkit written in pure Bash.**

**btrfsback-lite** is a minimal yet powerful backup solution built around native **BTRFS snapshots** and **BTRFS send/receive** replication.

Designed for Linux servers, root filesystems (`/`) and live **LXD containers**, it provides fast incremental backups, automatic snapshot rotation, remote replication and detailed reporting — all without external frameworks or complex software stacks.

---

## ✨ Features

- ⚡ **Incremental Replication**
  - Uses native `btrfs send/receive`
  - Transfers only changed blocks
  - Minimizes backup time and network bandwidth

- 📸 **Automatic Snapshot Rotation**
  - Configurable local retention
  - Configurable remote retention

- 🔐 **Secure Remote Replication**
  - Passwordless SSH
  - Fully encrypted transport

- 📬 **Rich Email Reports**
  - Complete execution summary
  - Snapshot creation
  - Replication status
  - Cleanup results

- 🛡️ **Detailed Error Reporting**
  - Full stdout/stderr capture
  - Failed operations highlighted inside email reports

- 📈 **Monitoring Ready**
  - Native hooks prepared for
    - Nagios
    - Zabbix

- 💻 **100% Pure Bash**
  - No Python
  - No Perl
  - No external frameworks
  - Easy to audit and customize

---

# 🛠 Requirements

## Packages

```bash
sudo apt update

sudo apt install -y \
    coreutils \
    tree \
    bsd-mailx \
    postfix \
    pv \
    gawk \
    lolcat
```

---

## Prerequisites

- Passwordless SSH authentication
- Existing destination directories
- BTRFS filesystem
- Linux with BTRFS send/receive support

Validated on:

- ✅ Ubuntu 22.04 LTS
- ✅ Debian 11
- ✅ Debian 12 (Bookworm)

Works on virtually any modern Linux distribution supporting BTRFS.

---

# 📦 Components

The project currently contains two utilities.

| Tool | Description |
|------|-------------|
| **btrfsback-lite** | Local snapshots + remote incremental replication |
| **btrlb** | Local snapshots only (no replication) |

---

# 🚀 btrfsback-lite

The main replication engine.

Responsible for:

- snapshot creation
- snapshot rotation
- incremental replication
- remote cleanup
- email reporting

---

## Installation

### Install the executable

```bash
sudo wget -O /usr/local/sbin/btrfsback-lite \
https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite

sudo chmod +x /usr/local/sbin/btrfsback-lite
```

### Install the configuration profile

```bash
sudo wget -O /etc/btrfsback-lite.cfg \
https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite.cfg
```

---

# 📖 Command Line Options

```text
Options:

-s, --subvol
    Source BTRFS subvolume

-l, --local-dir
    Local snapshot directory

-d, --daily-local
    Number of local snapshots to keep

-H, --remote-host
    Remote host (IP/FQDN)

-r, --remote-dir
    Remote snapshot directory

-D, --daily-remote
    Number of remote snapshots to keep

-h, --help
    Show help
```

---

# ▶ Manual Example

```bash
btrfsback-lite \
    --subvol / \
    --local-dir /mnt/sda2/autosnap-test \
    --daily-local 4 \
    --remote-host 10.5.5.4 \
    --remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test \
    --daily-remote 6
```

---

# ⏰ Cron Example

`/etc/cron.d/btrfsback-lite`

```cron
0 23 * * * root \
/usr/local/sbin/btrfsback-lite \
--subvol / \
--local-dir /mnt/sda2/autosnap-test \
--daily-local 4 \
--remote-host 10.5.5.4 \
--remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test \
--daily-remote 6 \
> /var/log/btrfsback-lite.log 2>&1
```

---

# 📂 Multi-Volume Automation

For multiple LXD containers or multiple BTRFS subvolumes, use the orchestration wrapper together with a central configuration file.

---

## Scheduler

```cron
# DAILY
0 1 * * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg DAILY

# WEEKLY
0 3 * * 0 root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg WEEKLY

# MONTHLY
0 4 1 * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg MONTHLY

# YEARLY
0 5 1 1 * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg YEARLY
```

---

## Central Configuration

`/etc/btrfsback-lite.cfg`

```bash
/usr/local/sbin/btrfsback-lite \
--subvol /mnt/sda3/containers/container1 \
--local-dir /mnt/sda3/autosnap-btrfsback/daily/container1 \
--daily-local 10 \
--remote-host 10.5.5.4 \
--remote-dir /mnt/rootfs/BACKUP-VPS/LXD/daily/container1 \
--daily-remote 15

/usr/local/sbin/btrfsback-lite \
--subvol /mnt/sda3/containers/container2 \
--local-dir /mnt/sda3/autosnap-btrfsback/daily/container2 \
--daily-local 10 \
--remote-host 10.5.5.4 \
--remote-dir /mnt/rootfs/BACKUP-VPS/LXD/daily/container2 \
--daily-remote 15

/usr/local/sbin/btrfsback-lite \
--subvol /mnt/sda3/containers/container3 \
--local-dir /mnt/sda3/autosnap-btrfsback/daily/container3 \
--daily-local 10 \
--remote-host 10.5.5.4 \
--remote-dir /mnt/rootfs/BACKUP-VPS/LXD/daily/container3 \
--daily-remote 15
```

---

# 📦 btrlb

`btrlb` is the lightweight edition that performs **local snapshot rotation only**.

No remote replication.

Perfect for standalone machines or local backup retention.

---

## Screenshot

![Help](https://raw.githubusercontent.com/unix1984/btrfs/main/img/btrlb-help.png)

---

## Installation

```bash
wget -O /usr/local/sbin/btrlb \
https://raw.githubusercontent.com/unix1984/btrfs/main/btrlb

chmod +x /usr/local/sbin/btrlb
```

---

## Dependencies

```bash
sudo apt install \
    coreutils \
    tree \
    bsd-mailx \
    postfix \
    pv \
    gawk \
    lolcat
```

---

## Example

```bash
btrlb \
    --subvol / \
    --local-dir /mnt/sda2/autosnap-test \
    --daily-local 10
```

---

## Cron

```cron
0 23 * * * root \
/usr/local/sbin/btrlb \
--subvol / \
--local-dir /mnt/sda2/autosnap-test \
--daily-local 10 \
> /var/log/btrlb.log 2>&1
```

---

## During Operation

![Operation](https://raw.githubusercontent.com/unix1984/btrfs/main/img/btrlb-operation.png)

---

# ❤️ Philosophy

**btrfsback-lite** intentionally keeps everything simple.

- Pure Bash
- Native Linux utilities
- Native BTRFS
- No databases
- No daemons
- No external dependencies beyond standard Linux packages

Small, transparent, reliable.
````
