#!/bin/bash

# Configuration file path
CONFIG_FILE="/etc/btrfsback-lite.cfg"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "CRITICAL - Configuration file not found: $CONFIG_FILE"
    exit 2
fi

# Load backup configuration variables
source "$CONFIG_FILE"

# Time thresholds in seconds for DAILY backups
WARNTIME=93600  # 26 hours
CRITTIME=172800 # 48 hours

get_snapshot_info() {
    local dir=$1
    local is_remote=$2
    local host=$3
    local latest_snap=""

    if [ "$is_remote" = "true" ]; then
        # Get the newest snapshot name matching the date pattern from remote host
        latest_snap=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$host" "ls -1d $dir/[0-9]*-[0-9]* 2>/dev/null | sort | tail -n 1")
    else
        # Get the newest snapshot name matching the date pattern locally
        latest_snap=$(ls -1d "$dir"/[0-9]*-[0-9]* 2>/dev/null | sort | tail -n 1)
    fi

    if [ -z "$latest_snap" ]; then
        echo "FAILED"
        return 1
    fi

    # Extract only the directory name (e.g., 2026-07-06_01-00-00)
    local snap_name=$(basename "$latest_snap")
    
    # Convert YYYY-MM-DD_HH-MM-SS to YYYY-MM-DD HH:MM:SS for date tool compatibility
    local formatted_date=$(echo "$snap_name" | sed 's/_/ /; s/-/:/4; s/-/:/4')
    
    # Convert to unix timestamp
    local timestamp=$(date -d "$formatted_date" +%s 2>/dev/null)
    
    if [ -z "$timestamp" ]; then
        echo "FAILED"
    else
        echo "$timestamp|$snap_name"
    fi
}

NOW=$(date +%s)
STATUS=0
OUTPUT=""

# 1. Check Local and Remote ROOTFS Backup Status
L_INFO=$(get_snapshot_info "$DAILY_LOCALDIR_ROOTFS" "false")
if [ "$L_INFO" = "FAILED" ] || [ -z "$L_INFO" ]; then
    OUTPUT+="Local ROOTFS: No valid snapshot found! | "
    STATUS=2
else
    L_TIME=$(echo "$L_INFO" | cut -d'|' -f1)
    L_NAME=$(echo "$L_INFO" | cut -d'|' -f2)
    AGE=$((NOW - L_TIME))
    if [ $AGE -gt $CRITTIME ]; then
        OUTPUT+="Local ROOTFS: Outdated (>48h) ($L_NAME) | "
        [ $STATUS -lt 2 ] && STATUS=2
    elif [ $AGE -gt $WARNTIME ]; then
        OUTPUT+="Local ROOTFS: Delayed (>26h) ($L_NAME) | "
        [ $STATUS -lt 1 ] && STATUS=1
    else
        OUTPUT+="Local ROOTFS: OK ($L_NAME) | "
    fi
fi

R_INFO=$(get_snapshot_info "$DAILY_REMOTEDIR_ROOTFS" "true" "$DAILY_REMOTE_IP")
if [ "$R_INFO" = "FAILED" ] || [ -z "$R_INFO" ]; then
    OUTPUT+="Remote ROOTFS: Host unreachable or no valid snapshot found! | "
    STATUS=2
else
    R_TIME=$(echo "$R_INFO" | cut -d'|' -f1)
    R_NAME=$(echo "$R_INFO" | cut -d'|' -f2)
    AGE=$((NOW - R_TIME))
    if [ $AGE -gt $CRITTIME ]; then
        OUTPUT+="Remote ROOTFS: Outdated (>48h) ($R_NAME) | "
        [ $STATUS -lt 2 ] && STATUS=2
    elif [ $AGE -gt $WARNTIME ]; then
        OUTPUT+="Remote ROOTFS: Delayed (>26h) ($R_NAME) | "
        [ $STATUS -lt 1 ] && STATUS=1
    else
        OUTPUT+="Remote ROOTFS: OK ($R_NAME) | "
    fi
fi

# 2. Check Each LXD Container Individually
for d in $DAILY_CONTAINERS/*; do
    [ -e "$d" ] || continue
    CTNAME=$(basename "$d")
    [[ " $DAILY_EXCLUDE_CONTAINERS " =~ " $CTNAME " ]] && continue

    # Local check for current container
    L_CT_INFO=$(get_snapshot_info "$DAILY_LOCALDIR_LXD/$CTNAME" "false")
    if [ "$L_CT_INFO" != "FAILED" ] && [ -n "$L_CT_INFO" ]; then
        CT_TIME=$(echo "$L_CT_INFO" | cut -d'|' -f1)
        CT_NAME=$(echo "$L_CT_INFO" | cut -d'|' -f2)
        AGE=$((NOW - CT_TIME))
        if [ $AGE -gt $CRITTIME ]; then
            OUTPUT+="Local LXD ($CTNAME): Outdated ($CT_NAME) | "
            [ $STATUS -lt 2 ] && STATUS=2
        elif [ $AGE -gt $WARNTIME ]; then
            OUTPUT+="Local LXD ($CTNAME): Delayed ($CT_NAME) | "
            [ $STATUS -lt 1 ] && STATUS=1
        else
            OUTPUT+="Local LXD ($CTNAME): OK ($CT_NAME) | "
        fi
    else
        OUTPUT+="Local LXD ($CTNAME): No snapshot found! | "
        [ $STATUS -lt 2 ] && STATUS=2
    fi

    # Remote check for current container
    R_CT_INFO=$(get_snapshot_info "$DAILY_REMOTEDIR_LXD/$CTNAME" "true" "$DAILY_REMOTE_IP")
    if [ "$R_CT_INFO" != "FAILED" ] && [ -n "$R_CT_INFO" ]; then
        CT_TIME=$(echo "$R_CT_INFO" | cut -d'|' -f1)
        CT_NAME=$(echo "$R_CT_INFO" | cut -d'|' -f2)
        AGE=$((NOW - CT_TIME))
        if [ $AGE -gt $CRITTIME ]; then
            OUTPUT+="Remote LXD ($CTNAME): Outdated ($CT_NAME) | "
            [ $STATUS -lt 2 ] && STATUS=2
        elif [ $AGE -gt $WARNTIME ]; then
            OUTPUT+="Remote LXD ($CTNAME): Delayed ($CT_NAME) | "
            [ $STATUS -lt 1 ] && STATUS=1
        else
            OUTPUT+="Remote LXD ($CTNAME): OK ($CT_NAME) | "
        fi
    else
        OUTPUT+="Remote LXD ($CTNAME): No snapshot or host down! | "
        [ $STATUS -lt 2 ] && STATUS=2
    fi
done

# Strip the trailing pipeline character
OUTPUT=$(echo "$OUTPUT" | sed 's/ | $//')

# Determine Nagios compliant exit code and string
case $STATUS in
    0) echo "OK - $OUTPUT" ;;
    1) echo "WARNING - $OUTPUT" ;;
    2) echo "CRITICAL - $OUTPUT" ;;
    *) echo "UNKNOWN - Unexpected error occurred" ; STATUS=3 ;;
esac

exit $STATUS
