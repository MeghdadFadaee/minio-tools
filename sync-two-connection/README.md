# 🪣 MinIO Backup Sync Script

![Bash](https://img.shields.io/badge/Bash-blue?logo=gnu-bash&logoColor=white)
![MinIO](https://img.shields.io/badge/MinIO-Client-orange?logo=minio&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

## 🧠 Overview
This script automates **incremental synchronization** between two MinIO buckets (or aliases) using the `mc` (MinIO Client).  
It compares file lists between a **source** and **destination**, and only copies **new files** that don’t yet exist in the destination.

Useful for:
- Incremental daily backups
- Synchronizing environments (e.g. `production-storage → backup-storage`)
- Automated log-friendly backups with per-day directories

---

## ⚙️ Features
- 🪄 Detects and syncs **only new files**
- 🧾 Creates daily log folders (`./logs/YYYY-MM-DD/`)
- 📊 Shows **real-time progress**
- 🧩 Works with any configured `mc alias`
- 🪶 Lightweight – requires only Bash and `mc`

---

## 🧰 Requirements
Before running the script, make sure you have:
- **Bash** (default in most Linux systems)
- **MinIO Client (`mc`)** installed and in `$PATH`
- Configured MinIO aliases via:
  ```bash
  mc alias set production-storage https://example.com ACCESS_KEY SECRET_KEY
  mc alias set backup-storage https://backup.example.com ACCESS_KEY SECRET_KEY
  ```

You can verify your connections:
```bash
mc ls production-storage
mc ls backup-storage
```

---

## 🚀 Setup

Clone the repository and make the script executable:

```bash
git clone https://github.com/<your-username>/minio-backup-sync.git
cd minio-backup-sync
chmod +x sync.sh
```

Optionally, create a `logs` folder (auto-created if missing):
```bash
mkdir -p logs
```

---

## 🧭 Usage

Basic syntax:
```bash
./sync.sh <source-alias/path> <dest-alias/path>
```

Example:
```bash
./sync.sh production-storage/general-storage backup-storage/general-storage
```

---

## 📜 How It Works

1. **Input validation** → Ensures both source and destination are provided.  
2. **Logging setup** → Creates a folder for today’s date under `./logs/YYYY-MM-DD/`.  
3. **File listing** → Lists and sorts all files in both locations.  
4. **Comparison** → Finds files missing in destination.  
5. **Copying** → Copies missing files one-by-one, showing progress.  
6. **Completion** → Appends timestamps and results to `sync.log`.

---

## 📁 Log Structure
Logs are organized by date:
```
logs/
└── 2025-10-05/
    ├── temp/
    │   ├── source_files.txt
    │   ├── dest_files.txt
    │   └── files_to_copy.txt
    └── sync.log
```

View logs in real-time:
```bash
tail -f logs/$(date +%Y-%m-%d)/sync.log
```

---

## 📊 Example Output

```
🧾 logging in: logs/2025-10-05/sync.log
🔄 2025-10-05 15:12:01 - Starting sync from production-storage/general-storage to backup-storage/general-storage
📦 2025-10-05 15:12:04 - Found 428 files in source
📦 2025-10-05 15:12:07 - Found 420 files in destination
🔢 Found 8 new file(s) to sync.
📤 [8/8] Copying: images/cover.jpg
✅ Sync complete at 2025-10-05 15:13:10
```

---

## 🧹 Optional Tips
- Automate with `cron`:
  ```bash
  0 3 * * * /path/to/sync.sh production-storage/general-storage backup-storage/general-storage >> /path/to/logs/cron.log 2>&1
  ```
- View previous day’s sync:
  ```bash
  cat logs/$(date -d "yesterday" +%Y-%m-%d)/sync.log
  ```

---

## 🧑‍💻 Author
**Meghdad Fadaee**  
📂 GitHub: [@your-username](https://github.com/your-username)

---

📝 **License:** MIT — feel free to use, modify, and distribute.
