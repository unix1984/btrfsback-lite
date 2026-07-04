# 🚀 btrfsback-lite

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bash](https://img.shields.io/badge/Language-100%25%20Bash-4eaa42.svg)](https://www.gnu.org/software/bash/)
[![BTRFS](https://img.shields.io/badge/FS-BTRFS-blue.svg)](https://btrfs.readthedocs.io/)

A highly efficient, lightweight BTRFS snapshot and replication toolset.

> 💡 **Why "Lite"?** This toolset consists of dead-simple, **100% pure Bash scripts**. It is ultra-lightweight, universally compatible, and completely auditable. No heavy frameworks, no bloated dependencies—just native Bash and BTRFS power.

Perfect for automated production snapshotting and offsite replication of root filesystems (`/`) and live LXD containers.

---

## ✨ Key Features in v2.0

* ⚡ **Incremental Replication:** Leverages native BTRFS send/receive streams to sync only modified data blocks, slashing backup windows and bandwidth.
* 📬 **Rich E-Mail Reporting:** Dispatches a clean, detailed summary listing every single execution task and state at the end of the chain.
* 🛡️ **Fail-Safe Visibility:** Full stderr and stdout tracking. If a single snapshot fails, error outputs are explicitly spotlighted inside your daily report.
* 📈 **Monitoring Ready:** Built-in hooks for upcoming native Nagios and Zabbix telemetry probes.

---

## 🛠️ Infrastructure Requirements

2. Prerequisites
SSH Keys: Passwordless SSH key authentication must be actively deployed to the destination backup target.

Paths: Target storage directories must be initialized beforehand on both the local and remote sides.

Validated environments: Ubuntu 22.04 LTS, Debian 11/12 (Bookworm). Works seamlessly across any modern Linux distribution.

📦 Component Layout & Deployment
1. btrfsback-lite (Core Replicator)
Handles local snapshot aging policies and orchestrates secure, encrypted offsite transfers.

Install

wget -O /usr/local/sbin/btrfsback-lite [https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite](https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite)
chmod +x /usr/local/sbin/btrfsback-lite
Deploy system configuration profile

wget -O /etc/btrfsback-lite.cfg [https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite.cfg](https://raw.githubusercontent.com/unix1984/btrfsback-lite/main/btrfsback-lite.cfg)
CLI Reference
Plaintext
Options:
  -s, --subvol        Target BTRFS source subvolume path
  -l, --local-dir     Local retention directory path
  -d, --daily-local   Maximum local daily snapshots to retain
  -H, --remote-host   Remote replication target (IP / FQDN)
  -r, --remote-dir    Remote retention directory path
  -D, --daily-remote  Maximum remote daily snapshots to retain
  -h, --help          Show this manual


Manual Run Example

btrfsback-lite --subvol / --local-dir /mnt/sda2/autosnap-test --daily-local 4 --remote-host 10.5.5.4 --remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test --daily-remote 6
Single Subvolume Cron Configuration (/etc/cron.d/btrfsback-lite)

0 23 * * * root /usr/local/sbin/btrfsback-lite --subvol / --local-dir /mnt/sda2/autosnap-test --daily-local 4 --remote-host 10.5.5.4 --remote-dir /mnt/sdb2/BACKUP/VPS-rootfs/autosnap-test --daily-remote 6 > /var/log/btrfsback-lite.log 2>&1
2. Multi-Volume Orchestration (Automation Wrapper)
To execute continuous batch updates across several dynamic mountpoints (e.g. isolated LXD nodes) matching strict retention schedules, use the master orchestration runner with your central config profile.

Production Automation Cron (/etc/crontab or /etc/cron.d/btrfsback-lite-schedule)

# BTRFS autosnap and replication scheduling.
# DAILY snapshot - every day at 01:00
0 1 * * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg DAILY

# WEEKLY snapshot - every Sunday at 03:00
0 3 * * 0 root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg WEEKLY

# MONTHLY snapshot - 1st day of each month at 04:00
0 4 1 * * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg MONTHLY

# YEARLY snapshot - January 1st at 05:00
0 5 1 1 * root /usr/local/sbin/autosnaps-btrfsback-lite.sh --config /etc/btrfsback-lite.cfg YEARLY
Central Configuration Matrix Block (/etc/btrfsback-lite.cfg)
Bash
/usr/local/sbin/btrfsback-lite --subvol /mnt/sda3/containers/container1 --local-dir /mnt/sda3/autosnap-btrfsback/daily/container1 --daily-local 10 --remote-host 10.5.5.4 --remote-dir /mnt/rootfs/BACKUP-VPS/LXD/daily/container1 --daily-remote 15
/usr/local/sbin/btrfsback-lite --subvol /mnt/sda3/containers/container2 --local-dir /mnt/sda3/autosnap-btrfsback/daily/container2 --daily-local 10 --remote-host 10.5.5.4 --remote-dir /mnt/rootfs/BACKUP-VPS/LXD/daily/container2 --daily-remote 15
/usr/local/sbin/btrfsback-lite --subvol /mnt/sda3/containers/container3 --local-dir /mnt/sda3/autosnap-btrfsback/daily/container3 --daily-local 10 --remote-host 10.5.5.4 --remote-dir /mnt/rootfs/BACKUP-VPS/LXD/daily/container3 --daily-remote 15


### 1. System Packages
```bash
sudo apt update && sudo apt install -y coreutils tree bsd-mailx postfix pv gawk lolcat


# btrlb
Btrlb is a mini version that only rotates **local backups** with snapshots without replication.

![alt text](https://raw.githubusercontent.com/unix1984/btrfs/main/img/btrlb-help.png)

**Install:**

```wget -O /usr/local/sbin/btrlb https://raw.githubusercontent.com/unix1984/btrfs/main/btrlb && chmod +x /usr/local/sbin/btrlb```


**Dependencies:**

```apt install coreutils tree bsd-mailx postfix pv gawk lolcat```


**Example:**

```btrlb --subvol / --local-dir /mnt/sda2/autosnap-test --daily-local 10```



**cron:**

```0  23  * * *     root   /usr/local/sbin/btrlb --subvol / --local-dir /mnt/sda2/autosnap-test --daily-local 10 > /var/log/btrlb.log 2>&1```
<br/>
<br/>
<br/>
During operation:
![alt text](https://raw.githubusercontent.com/unix1984/btrfs/main/img/btrlb-operation.png)


