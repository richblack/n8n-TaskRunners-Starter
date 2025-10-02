# n8n 備份系統使用說明

## 📦 備份內容

每次備份包含：
- **n8n_workflows.sql**: n8n 工作流、執行記錄、憑證數據
- **postgres_full.sql.gz**: 完整 PostgreSQL 數據庫（壓縮）
- **n8n_data.tar.gz**: n8n 配置檔案、加密金鑰、日誌
- **docker-compose*.yml**: Docker Compose 配置檔案
- **env.backup**: 環境變數配置

## ⏰ 自動備份

- **排程**: 每天凌晨 3:00 自動執行
- **保留期**: 30 天（舊備份自動清理）
- **日誌**: /var/log/n8n-backup.log

查看 cron 設定：
```bash
crontab -l
```

## 🔧 手動備份

執行手動備份：
```bash
/root/backup-n8n.sh
```

## 📂 備份位置

- **備份目錄**: /root/backups/n8n/
- **最新備份**: /root/backups/n8n/latest (符號連結)
- **歷史備份**: /root/backups/n8n/n8n_backup_YYYYMMDD_HHMMSS/

查看所有備份：
```bash
ls -lh /root/backups/n8n/
```

## 🔄 恢復備份

### 方法 1: 使用恢復腳本（推薦）

恢復最新備份：
```bash
/root/restore-n8n.sh
```

恢復指定備份：
```bash
/root/restore-n8n.sh /root/backups/n8n/n8n_backup_20251002_075732
```

### 方法 2: 手動恢復

1. 停止 n8n 服務：
```bash
docker stop n8n_app
```

2. 恢復數據庫：
```bash
cd /root/backups/n8n/latest
gunzip -c postgres_full.sql.gz | docker exec -i supabase-db psql -U supabase_admin -d postgres
```

3. 恢復配置檔案：
```bash
docker run --rm \
  -v supabase-n8n-minimal_n8n_data:/data \
  -v /root/backups/n8n/latest:/backup \
  alpine tar xzf /backup/n8n_data.tar.gz -C /data
```

4. 啟動服務：
```bash
docker start n8n_app
```

## 📊 檢查備份

查看最新備份資訊：
```bash
cat /root/backups/n8n/latest/backup_info.txt
```

檢查備份大小：
```bash
du -sh /root/backups/n8n/*
```

查看備份日誌：
```bash
tail -f /var/log/n8n-backup.log
```

## 🚨 緊急恢復

如果 n8n 完全無法啟動：

1. 找到最近的有效備份
2. 使用恢復腳本或手動恢復
3. 檢查 docker logs：
```bash
docker logs n8n_app --tail 100
```

## 💾 下載備份到本地

使用 scp 下載備份：
```bash
# 從本地機器執行
scp -r supa:/root/backups/n8n/latest ./n8n_backup_20251002
```

## 🔐 安全建議

1. **定期測試恢復** - 每月測試一次備份恢復流程
2. **異地備份** - 定期下載備份到本地或其他服務器
3. **監控磁碟空間** - 確保有足夠空間存放備份
4. **保護備份檔案** - 備份包含敏感資料（憑證、加密金鑰）

檢查磁碟空間：
```bash
df -h /root/backups
```

## 📝 備份腳本位置

- **備份腳本**: /root/backup-n8n.sh
- **恢復腳本**: /root/restore-n8n.sh
- **說明文件**: /root/backups/README.md

## 🔍 故障排除

### 備份失敗
1. 檢查磁碟空間：`df -h`
2. 檢查容器狀態：`docker ps -a`
3. 查看錯誤日誌：`tail /var/log/n8n-backup.log`

### 恢復失敗
1. 確認備份檔案完整性
2. 檢查數據庫連接
3. 查看容器日誌：`docker logs n8n_app`

---

**最後更新**: Thu Oct  2 16:01:01 CST 2025
**版本**: n8n 1.113.3
