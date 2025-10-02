# n8n 更新指南

## 快速更新流程

### 前置檢查

```bash
# 1. 確認當前版本
ssh supa "docker exec n8n_app n8n --version"

# 2. 確認服務運行正常
ssh supa "docker ps | grep n8n"

# 3. 檢查磁碟空間
ssh supa "df -h"
```

### 標準更新步驟

```bash
# 1. 【必須】執行備份
ssh supa "/root/backup-n8n.sh"

# 2. 拉取最新映像
ssh supa "cd /root && docker compose pull n8n"

# 3. 重新創建容器
ssh supa "cd /root && docker compose up -d n8n"

# 4. 確保網絡連接正確
ssh supa "docker network connect supabase-n8n-minimal_default n8n_app 2>/dev/null || true"

# 5. 檢查服務狀態
ssh supa "docker logs n8n_app --tail 50"

# 6. 驗證訪問
curl -I https://n8n.uncle6.me
```

## 故障排查

### 問題 1: 404 Not Found

**檢查步驟**:
```bash
# 1. 檢查 Traefik labels
ssh supa "docker inspect n8n_app --format '{{json .Config.Labels}}' | grep traefik"

# 2. 檢查網絡連接
ssh supa "docker inspect n8n_app --format '{{range .NetworkSettings.Networks}}{{println .NetworkID}}{{end}}'"

# 3. 查看 Traefik 日誌
ssh supa "docker logs traefik --tail 50 | grep -i n8n"
```

**解決方案**:
```bash
# 如果缺少 labels，重新創建容器
ssh supa "cd /root && docker compose up -d --force-recreate n8n"

# 如果網絡丟失
ssh supa "docker network connect supabase-n8n-minimal_default n8n_app"

# 重啟 Traefik
ssh supa "docker restart traefik"
```

### 問題 2: Credentials could not be decrypted

**原因**: 加密金鑰丟失或改變

**檢查**:
```bash
ssh supa "docker exec n8n_app cat /home/node/.n8n/config"
```

**解決方案**:
```bash
# 從備份恢復
ssh supa "/root/restore-n8n.sh"
```

### 問題 3: Database connection failed

**檢查數據庫**:
```bash
ssh supa "docker ps | grep supabase-db"
ssh supa "docker logs supabase-db --tail 50"
```

**解決方案**:
```bash
# 重啟數據庫
ssh supa "docker restart supabase-db"

# 等待數據庫啟動
sleep 10

# 重啟 n8n
ssh supa "docker restart n8n_app"
```

## 重要配置

### 必須的環境變數

```bash
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=db
DB_POSTGRESDB_DATABASE=postgres
DB_POSTGRESDB_USER=supabase_admin
N8N_ENCRYPTION_KEY=iE1dGMZQsK8IPCt6pvIi4X+eFxhb7lbs  # 絕對不能改！
```

### 必須的 Traefik Labels

```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.n8n.rule=Host(\`n8n.uncle6.me\`)"  # 必須用反引號
  - "traefik.http.routers.n8n.tls.certresolver=letsencrypt"
  - "traefik.http.services.n8n.loadbalancer.server.port=5678"
```

### 必須的 Volume

```yaml
volumes:
  - supabase-n8n-minimal_n8n_data:/home/node/.n8n
```

## 回滾流程

如果更新後出現問題：

```bash
# 1. 停止新版本
ssh supa "docker stop n8n_app && docker rm n8n_app"

# 2. 從備份恢復
ssh supa "/root/restore-n8n.sh"

# 3. 指定舊版本（如果需要）
ssh supa "cd /root && docker compose pull n8n:1.106.3"
```

## 測試清單

更新後必須檢查：

- [ ] n8n 界面可以訪問 (https://n8n.uncle6.me)
- [ ] 可以登入
- [ ] 現有工作流正常顯示
- [ ] 憑證可以正常解密
- [ ] Webhook 正常工作
- [ ] 定時任務正常執行

## 相關文檔

- [備份與恢復指南](./BACKUP.md)
- [經驗教訓記錄](../.lessons-learned.md)
- [快速參考](../scripts/n8n-backup-cheatsheet.txt)

## 聯絡資訊

- n8n 官方文檔: https://docs.n8n.io
- GitHub Issues: https://github.com/n8n-io/n8n/issues
- 版本發佈: https://github.com/n8n-io/n8n/releases
