# 🧩 MinIO Backup Sync via SSH Tunnel

![Bash](https://img.shields.io/badge/Bash-blue?logo=gnu-bash&logoColor=white)
![MinIO](https://img.shields.io/badge/MinIO-Client-orange?logo=minio&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green)

## 🧠 Overview
This script is a **static, automated backup tool** for synchronizing MinIO storage between a remote and a local environment.  
It automatically creates a secure **SSH tunnel** to the remote MinIO service, mounts it locally, and performs an **incremental sync** (only new files) to a backup destination.

---

## ⚙️ Features
- 🔐 Automatic SSH tunnel creation & cleanup
- 🔄 Incremental sync — only copies new files
- 🧾 Per-day logging under `./logs/YYYY-MM-DD/`
- 📊 Real-time progress display
- 🧹 Automatic PID and temporary file cleanup

---

## 🧰 Pre-configured Settings

The following settings are hard-coded inside the script:

| Variable | Description | Value                              |
|-----------|-------------|------------------------------------|
| `REMOTE_SERVER` | Remote host running MinIO | `0.0.0.0`                          |
| `REMOTE_SERVICE_PORT` | Remote MinIO service port | `9000`                             |
| `LOCAL_PORT` | Local port for SSH tunnel | `9020`                             |
| `SSH_USER` | SSH username | `root`                             |
| `SSH_PORT` | SSH port | `22`                               |
| `SOURCE` | MinIO alias & bucket for source | `production-minio/general-storage` |
| `DEST` | MinIO alias & bucket for backup | `backup-minio/general-storage`  |

---

## 🧩 Prerequisites

You need the following installed and configured:

- **Bash shell**
- **MinIO Client (`mc`)**
- **SSH access** to the remote server (using provided credentials)
- Local `mc` aliases set up, for example:

```bash
mc alias set production-minio http://127.0.0.1:9020 ACCESS_KEY SECRET_KEY
mc alias set backup-minio http://127.0.0.1:9000 ACCESS_KEY SECRET_KEY
```

Make sure aliases work before running:
```bash
mc ls production-minio
mc ls backup-minio
```

---

## 🚀 How It Works

1. **Creates SSH Tunnel**
  - Opens a tunnel from `localhost:9020` → `0.0.0.0:9000`
  - Stores tunnel PID in `/tmp/ssh_tunnel_9020.pid`
2. **Performs Sync**
  - Lists all files in both MinIO buckets
  - Compares them and finds new ones
  - Copies only missing files to destination
3. **Handles Cleanup**
  - When the script exits (normally or interrupted), it closes the tunnel and removes the PID file.

---

## 🧭 Usage

Simply run the script manually or via `cron`:

```bash
./script.sh
```

If you want to run it on a schedule (e.g., every night at 3 AM):

```bash
0 3 * * * /path/to/script.sh >> /path/to/logs/cron.log 2>&1
```

---

## 📁 Log Structure

Logs are created daily under the `logs/` folder:

```
logs/
└── 2025-10-05/
    ├── temp/
    │   ├── source_files.txt
    │   ├── dest_files.txt
    │   └── files_to_copy.txt
    └── sync.log
```

To watch logs in real-time:

```bash
tail -f logs/$(date +%Y-%m-%d)/sync.log
```

---

## 🧪 Example Output

```
running the minio script...
trying to create ssh tunnel...
accessing the service 185.142.157.47:9000 through localhost:9020 ...
tunnel has been created.
🔄 2025-10-05 15:12:01 - Starting sync from yadovin-minio/yadoovin-storage to backup-storage/yadovin-storage
📦 Found 1253 files in source
📦 Found 1247 files in destination
🔢 Found 6 new file(s) to sync.
📤 [6/6] Copying: photos/2025/img001.jpg
✅ Sync complete at 2025-10-05 15:14:11
running cleanup proccess...
stoping the tunnel (PID: 4213)...
tunnel has been stoped.
Done cleaning up.
```

---

## 🧹 Cleanup Notes

The script automatically cleans up:
- The SSH tunnel process (`kill` on exit)
- The PID file `/tmp/ssh_tunnel_9020.pid`

If needed, you can manually remove it:
```bash
rm -f /tmp/ssh_tunnel_9020.pid
```

---

## 🧑‍💻 Author

**Meghdad Fadaee**  
📂 GitHub: [@MeghdadFadaee](https://github.com/MeghdadFadaee)

---

📝 **License:** MIT — free to use, modify, and distribute.
