#!/bin/bash

# Check if both source and destination are provided
if [ $# -ne 2 ]; then
  echo "❌ Usage: $0 <source-alias/path> <dest-alias/path>"
  echo "   Example: $0 production-storage/general-storage backup-storage/general-storage"
  exit 1
fi

SOURCE="$1"
DEST="$2"

TODAY=$(date +%Y-%m-%d)
TMP_DIR="./logs/$TODAY/temp"
LOG_FILE="./logs/$TODAY/sync.log"

mkdir -p "$TMP_DIR"
mkdir -p "$(dirname "$LOG_FILE")"

echo "🧾 logging in: $LOG_FILE"
echo "🔄 $(date '+%F %T') - Starting sync from $SOURCE to $DEST" >> "$LOG_FILE"


# List existing files in source
echo "📁 $(date '+%F %T') - Listing source files..." >> "$LOG_FILE"
mc ls --recursive "$SOURCE" | awk '{print $NF}' | sort > "$TMP_DIR/source_files.txt"
SOURCE_COUNT=$(wc -l < "$TMP_DIR/source_files.txt")
echo "📦 $(date '+%F %T') - Found $SOURCE_COUNT files in source ($SOURCE)" >> "$LOG_FILE"

# List existing files in destination
echo "📁 $(date '+%F %T') - Listing destination files..." >> "$LOG_FILE"
mc ls --recursive "$DEST" | awk '{print $NF}' | sort > "$TMP_DIR/dest_files.txt"
DEST_COUNT=$(wc -l < "$TMP_DIR/dest_files.txt")
echo "📦 $(date '+%F %T') - Found $DEST_COUNT files in destination ($DEST)" >> "$LOG_FILE"

# Compare or sync logic would go here...
echo "⚙️ $(date '+%F %T') - Ready to compare and sync..." >> "$LOG_FILE"

# Compare to find new files
comm -23 "$TMP_DIR/source_files.txt" "$TMP_DIR/dest_files.txt" > "$TMP_DIR/files_to_copy.txt"

TOTAL=$(wc -l < "$TMP_DIR/files_to_copy.txt")
COUNT=0

if [ "$TOTAL" -eq 0 ]; then
    echo "✅ No new files to sync." | tee -a "$LOG_FILE"
    exit 0
fi

echo "🔢 Found $TOTAL new file(s) to sync." | tee -a "$LOG_FILE"

# Loop to copy files with progress display
while read -r file; do
    COUNT=$((COUNT + 1))
    echo -ne "📤 [$COUNT/$TOTAL] Copying: $file\r"
    mc cp "$SOURCE/$file" "$DEST/$file" >> "$LOG_FILE" 2>&1
done < "$TMP_DIR/files_to_copy.txt"

echo -e "\n✅ Sync complete at $(date '+%F %T')" | tee -a "$LOG_FILE"
