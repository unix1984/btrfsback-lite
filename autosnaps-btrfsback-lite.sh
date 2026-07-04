#!/bin/bash
#set -e
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

LOGFILE="/var/log/btrfsback-lite-$(date +%Y-%m-%d_%H-%M-%S).log"
exec > >(tee "$LOGFILE") 2>&1

# E-Mail Banner.
cat <<'EOF'
___  ___ ____ ____ ____    ___  ____ ____ _  _ _  _ ___     ____ ____ ___  ____ ____ ___
|__]  |  |__/ |___ [__     |__] |__| |    |_/  |  | |__]    |__/ |___ |__] |  | |__/  | 
|__]  |  |  \ |    ___]    |__] |  | |___ | \_ |__| |       |  \ |___ |    |__| |  \  | 

EOF

# ================================
# Parse arguments
# ================================
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"; shift 2 ;;
        DAILY|WEEKLY|MONTHLY|YEARLY)
            SECTION="$1"; shift ;;
        *) echo "Unknown argument: $1"; exit 1 ;;
    esac
done

if [[ -z "$CONFIG_FILE" ]] || [[ ! -f "$CONFIG_FILE" ]]; then
    echo "Config file not found!"
    exit 1
fi

if [[ -z "$SECTION" ]]; then
    echo "Section not specified (DAILY, WEEKLY, MONTHLY, YEARLY)"
    exit 1
fi

# Load config
source "$CONFIG_FILE"

# Assign variables dynamically
for VAR in BTRFSBACK_PATH CONTAINERS LOCALDIR_LXD LOCALDIR_ROOTFS REMOTE_IP REMOTEDIR_ROOTFS REMOTEDIR_LXD LSNAP_ROOTFS RSNAP_ROOTFS LSNAP_LXD RSNAP_LXD EMAIL EXCLUDE_CONTAINERS BTRFS_SUBVOL_ROOTFS; do
    DYNVAR="${SECTION}_${VAR}"
    declare "$VAR"="${!DYNVAR}"
done

###############
# ROOTFS Backup
$BTRFSBACK_PATH --subvol $BTRFS_SUBVOL_ROOTFS --local-dir $LOCALDIR_ROOTFS --snap-local $LSNAP_ROOTFS --remote-host $REMOTE_IP --remote-dir $REMOTEDIR_ROOTFS --snap-remote $RSNAP_ROOTFS

# update grub-btrfs
echo "========================================================================================"
echo "Updating GRUB with BTRFS Snapshots."
echo "========================================================================================"
update-grub
echo " "

#######################
# LXD Containers Backup
# Create directories for LXD Backups.
echo "========================================================================================"
echo "Create directories for LXD Backups."
echo "----------------------------------------------------------------------------------------"
DIRS=""
for d in $CONTAINERS/*; do
    CTNAME=$(basename "$d")
    # Skip excluded containers
    [[ " $EXCLUDE_CONTAINERS " =~ " $CTNAME " ]] && continue
    DIRS+="$REMOTEDIR_LXD/$CTNAME "
done

ssh root@$REMOTE_IP "for d in $DIRS; do mkdir -p \$d || exit 1; done"

if [ $? -eq 0 ]; then
    echo "Directories created - OK ✓"
else
    echo "- Some directories failed!"
fi
echo "========================================================================================"
echo " "
echo "Excluded containers for $SECTION: $EXCLUDE_CONTAINERS"

# Create snapshots and replicate all containers recursive.
for d in $CONTAINERS/*; do
    CTNAME=$(basename "$d")
    [[ " $EXCLUDE_CONTAINERS " =~ " $CTNAME " ]] && continue

# Create local directory if it does not exist
    mkdir -p "$LOCALDIR_LXD/$CTNAME"

    $BTRFSBACK_PATH --subvol $d --local-dir $LOCALDIR_LXD/$CTNAME --snap-local $LSNAP_LXD --remote-host $REMOTE_IP --remote-dir $REMOTEDIR_LXD/$CTNAME --snap-remote $RSNAP_LXD
done

echo " Btrfs Filesystem Usage Summary:"
echo "-----------------------------------------------------------------------------------------"
echo "Local:"
echo -n "ROOTFS (local): "
LC_ALL=C btrfs filesystem usage -h $LOCALDIR_ROOTFS | \
  awk '/^ *Used:/{u=$2}/^ *Free \(estimated\):/{f=$3}END{print "Used=" u ", Free≈" f}'

echo -n "LXD (local): "
LC_ALL=C btrfs filesystem usage -h $LOCALDIR_LXD | \
  awk '/^ *Used:/{u=$2}/^ *Free \(estimated\):/{f=$3}END{print "Used=" u ", Free≈" f}'

echo "-----------------------------------------------------------------------------------------"
echo "Remote:"
echo -n "ROOTFS (remote) on $REMOTE_IP: "
REMOTE_OUT=$(ssh -o ConnectTimeout=5 root@$REMOTE_IP "LC_ALL=C btrfs filesystem usage -h \"$REMOTEDIR_ROOTFS\"" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$REMOTE_OUT" ]; then
    echo "$REMOTE_OUT" | awk '/^ *Used:/{u=$2}/^ *Free \(estimated\):/{f=$3}END{print "Used=" u ", Free≈" f}'
else
    echo "FAILED (host unreachable or error)"
fi

echo -n "LXD (remote) on $REMOTE_IP: "
REMOTE_OUT=$(ssh -o ConnectTimeout=5 root@$REMOTE_IP "LC_ALL=C btrfs filesystem usage -h \"$REMOTEDIR_LXD\"" 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$REMOTE_OUT" ]; then
    echo "$REMOTE_OUT" | awk '/^ *Used:/{u=$2}/^ *Free \(estimated\):/{f=$3}END{print "Used=" u ", Free≈" f}'
else
    echo "FAILED (host unreachable or error)"
fi

echo "========================================================================================"
echo " All backups and processes are complete - OK ✓     -     " `date "+%Y-%m-%d %H:%M:%S"`
echo "========================================================================================"
echo " "

# Suspend NAS-N305
#ssh 192.168.11.11 systemctl suspend && echo " Suspending $REMOTE_IP: OK ✓" || echo "Suspending $REMOTE_IP: FAILED"

# Poweroff pfSense Home
#ssh 192.168.11.1 "echo 'Shutting down pfSense...' && poweroff" && echo "Shutting down pfSense: OK ✓" || echo "Shutting down pfSense: FAILED"

# Send E-mail report
#cat $LOGFILE | mail -s "BTRFS Snapshots and Replication E-Mail report." -a "From: btrfsback@$(hostname)" $EMAIL

(
  BOUNDARY="MAILPART-$(date +%s)-$$"
  HOSTNAME="$(hostname)"
  MSGID="$(date +%s).$$.$HOSTNAME"

  echo "From: btrfsback@$HOSTNAME"
  echo "To: $EMAIL"
  echo "Subject: BTRFS Snapshots and Replication - ${SECTION^} E-Mail report."
  echo "Date: $(LC_ALL=C date -R)"
  echo "Message-ID: <$MSGID>"
  echo "MIME-Version: 1.0"
  echo "Content-Type: multipart/alternative; boundary=\"$BOUNDARY\""
  echo "Content-Transfer-Encoding: 8bit"
  echo

  # Plain text
  echo "--$BOUNDARY"
  echo "Content-Type: text/plain; charset=UTF-8"
  echo "Content-Transfer-Encoding: 8bit"
  echo
  cat "$LOGFILE"
  echo

  # HTML (monospace, banner)
  echo "--$BOUNDARY"
  echo "Content-Type: text/html; charset=UTF-8"
  echo "Content-Transfer-Encoding: 8bit"
  echo
  echo "<!DOCTYPE html>"
  echo "<html><body>"
  echo "<pre style=\"font-family: monospace; font-size: 12px; white-space: pre;\">"
  cat "$LOGFILE"
  echo "</pre>"
  echo "</body></html>"
  echo

  echo "--$BOUNDARY--"
) | sendmail -t

