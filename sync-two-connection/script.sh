#!/bin/bash
# ========================================================================
# 🪣 MinIO Direct Sync Script
# ------------------------------------------------------------------------
# Syncs new files between two MinIO aliases or paths using the `mc` client.
# Example:
#   ./sync.sh production-storage/general-storage backup-storage/general-storage
#
# Author: Meghdad Fadaee
# Version: 1.1 (2025-10-05)
# ========================================================================

# --- Input Validation ---------------------------------------------------
if [ $# -ne 2 ]; then
  echo "❌ Usage: $0 <source-alias/path> <dest-alias/path>"
  echo "   Example: $0 production-storage/general-storage backup-storage/general-storage"
  exit 1
fi

SOURCE="$1"
DEST="$2"

# --- Setup --------------------------------------------------------------
TODAY=$(date +%Y-%m-%d)
LOG_DIR="./logs/$TODAY"
TMP_DIR="$LOG_DIR/tmp"
LOG_FILE="$LOG_DIR/sync.log"

mkdir -p "$TMP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

# --- Helper for logs ----------------------------------------------------
log() {
    local LEVEL="$1"
    local MSG="$2"
    local TIME=$(date '+%F %T')
    echo "[$TIME] [$LEVEL] $MSG" | tee -a "$LOG_FILE"
}

# --- Start --------------------------------------------------------------
log "INFO" "Starting sync process..."
log "INFO" "Source: $SOURCE"
log "INFO" "Destination: $DEST"
log "INFO" "Log file: $LOG_FILE"

# --- Step 1: List Source Files ------------------------------------------
log "INFO" "Listing files in source..."
if ! mc ls --recursive "$SOURCE" | awk '{print $NF}' | sort > "$TMP_DIR/source_files.txt"; then
    log "ERROR" "Failed to list files from source: $SOURCE"
    exit 1
fi
SOURCE_COUNT=$(wc -l < "$TMP_DIR/source_files.txt")
log "INFO" "Found $SOURCE_COUNT file(s) in source."

# --- Step 2: List Destination Files -------------------------------------
log "INFO" "Listing files in destination..."
if ! mc ls --recursive "$DEST" | awk '{print $NF}' | sort > "$TMP_DIR/dest_files.txt"; then
    log "ERROR" "Failed to list files from destination: $DEST"
    exit 1
fi
DEST_COUNT=$(wc -l < "$TMP_DIR/dest_files.txt")
log "INFO" "Found $DEST_COUNT file(s) in destination."

# --- Step 3: Compare Lists ----------------------------------------------
log "INFO" "Comparing file lists to find new files..."
comm -23 "$TMP_DIR/source_files.txt" "$TMP_DIR/dest_files.txt" > "$TMP_DIR/files_to_copy.txt"
TOTAL=$(wc -l < "$TMP_DIR/files_to_copy.txt")

if [ "$TOTAL" -eq 0 ]; then
    log "SUCCESS" "✅ No new files to sync. Everything is up to date."
    exit 0
fi

log "INFO" "🔢 Found $TOTAL new file(s) to sync."

# --- Step 4: Sync Files -------------------------------------------------
COUNT=0
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

# --- Done ---------------------------------------------------------------
log "SUCCESS" "✅ Sync completed successfully at $(date '+%F %T')"
