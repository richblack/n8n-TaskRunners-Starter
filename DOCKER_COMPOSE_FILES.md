# Docker Compose 檔案說明

## docker-compose.yml (主要檔案)
- **用途**: 精簡版設定，包含核心服務
- **服務數量**: 10 個服務
- **包含服務**:
  - Supabase 核心: studio, kong, auth, rest, meta, db
  - n8n (主服務)
  - caddy (反向代理)
  - ~~playwright~~ (已移除以節省記憶體)

## docker-compose.integrated.yml (完整版)
- **用途**: 完整功能版本，包含所有服務
- **服務數量**: 18+ 個服務
- **額外包含**:
  - traefik (反向代理，替代 caddy)
  - redis (用於 n8n 佇列)
  - n8n-worker (用於 n8n 任務處理)
  - realtime (Supabase 即時功能)
  - storage (Supabase 儲存服務)
  - imgproxy (圖片代理)
  - functions (Supabase Edge Functions)
  - analytics (分析服務)
  - vector (日誌收集)
  - supavisor (連線池管理)

## 使用建議

### 開發/測試環境
使用 `docker-compose.yml` (精簡版)
```bash
docker compose up -d
```

### 生產環境 (完整功能)
使用 `docker-compose.integrated.yml`
```bash
docker compose -f docker-compose.integrated.yml up -d
```

## 目前狀態
- 遠端伺服器目前使用混合模式
- 已停止服務: redis, n8n-worker, browserless/playwright
- 目的: 減少記憶體使用 (省下約 500MB)