#!/bin/bash
# ========================================================================
# 🛰️  MinIO Remote Sync Script with SSH Tunnel
# ------------------------------------------------------------------------
# This script creates an SSH tunnel to a remote server running MinIO,
# then synchronizes objects from a source bucket to a backup bucket.
#
# Author: Meghdad Fadaee
# Version: 1.2 (2025-10-05)
# ========================================================================

# --- Configuration ------------------------------------------------------
REMOTE_SERVICE_PORT="9000"             # Port of remote MinIO service
REMOTE_SERVER="0.0.0.0"                # Remote server IP or domain
LOCAL_PORT="9020"                      # Local port for SSH tunnel
SSH_PORT="22"                          # SSH port
SSH_USER="root"                        # SSH username

SOURCE="production-minio/general-storage"
DEST="backup-minio/general-storage"

TODAY=$(date +%Y-%m-%d)
LOG_DIR="./logs/$TODAY"
TMP_DIR="$LOG_DIR/tmp"
LOG_FILE="$LOG_DIR/sync.log"
PID_FILE="/tmp/ssh_tunnel_$LOCAL_PORT.pid"
TUNNEL_PID=""

# --- Functions ----------------------------------------------------------

log() {
    local LEVEL="$1"
    local MSG="$2"
    local TIME=$(date '+%F %T')
    echo "[$TIME] [$LEVEL] $MSG" | tee -a "$LOG_FILE"
}

cleanup() {
    log "INFO" "Running cleanup process..."

    if [ ! -z "$TUNNEL_PID" ] && kill -0 "$TUNNEL_PID" 2>/dev/null; then
        log "INFO" "Stopping SSH tunnel (PID: $TUNNEL_PID)..."
        kill "$TUNNEL_PID"
        wait "$TUNNEL_PID" 2>/dev/null
        log "INFO" "Tunnel has been stopped."
    fi

    [ -f "$PID_FILE" ] && rm -f "$PID_FILE"

    log "INFO" "Cleanup complete. Exiting script."
    exit
}

# --- Main Script --------------------------------------------------------
trap cleanup EXIT INT TERM

mkdir -p "$TMP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

log "INFO" "Starting MinIO sync process..."
log "INFO" "Today: $TODAY"
log "INFO" "Creating SSH tunnel from localhost:$LOCAL_PORT to $REMOTE_SERVER:$REMOTE_SERVICE_PORT ..."

# Create SSH tunnel in background
ssh -N -L "$LOCAL_PORT:localhost:$REMOTE_SERVICE_PORT" "$SSH_USER@$REMOTE_SERVER" -p "$SSH_PORT" &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > "$PID_FILE"

sleep 2

if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
    log "ERROR" "Failed to establish SSH tunnel. Exiting."
    exit 1
fi

log "SUCCESS" "SSH tunnel established (PID: $TUNNEL_PID)."
log "INFO" "Comparing files between $SOURCE and $DEST ..."

# Generate file lists
mc ls --recursive "$SOURCE" | awk '{print $NF}' | sort > "$TMP_DIR/source_files.txt"
mc ls --recursive "$DEST" | awk '{print $NF}' | sort > "$TMP_DIR/dest_files.txt"

# Find files missing in destination
comm -23 "$TMP_DIR/source_files.txt" "$TMP_DIR/dest_files.txt" > "$TMP_DIR/files_to_copy.txt"

TOTAL=$(wc -l < "$TMP_DIR/files_to_copy.txt")
COUNT=0

if [ "$TOTAL" -eq 0 ]; then
    log "SUCCESS" "No new files to sync. Everything is up to date ✅"
    exit 0
fi

log "INFO" "Found $TOTAL new file(s) to sync."

# --- Sync Loop ----------------------------------------------------------
while read -r FILE; do
    [ -z "$FILE" ] && continue
    COUNT=$((COUNT + 1))
    PROGRESS="[$COUNT/$TOTAL]"
    log "INFO" "$PROGRESS Copying: $FILE"
    if mc cp "$SOURCE/$FILE" "$DEST/$FILE" >> "$LOG_FILE" 2>&1; then
        log "SUCCESS" "$PROGRESS Successfully copied: $FILE"
    else
        log "ERROR" "$PROGRESS Failed to copy: $FILE"
    fi
done < "$TMP_DIR/files_to_copy.txt"

log "SUCCESS" "✅ Sync completed successfully at $(date '+%F %T')"
