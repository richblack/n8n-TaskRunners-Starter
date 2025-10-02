#!/bin/bash

# n8n 備份腳本
# 備份 n8n 工作流（從數據庫導出）和配置檔案

# 設定變數
BACKUP_DIR="/root/backups/n8n"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="${BACKUP_DIR}/n8n_backup_${DATE}"
RETENTION_DAYS=30  # 保留 30 天的備份

# 從 .env 讀取數據庫密碼
if [ -f /root/.env ]; then
    export $(grep -v '^#' /root/.env | xargs)
fi

# 創建備份目錄
mkdir -p "${BACKUP_PATH}"

echo "[備份開始] $(date)"
echo "備份位置: ${BACKUP_PATH}"

# 1. 備份 n8n 數據庫（包含所有工作流）
echo "[1/4] 備份 n8n 工作流數據..."
docker exec supabase-db pg_dump -U supabase_admin -d postgres     -t 'workflow_*'     -t 'execution_*'     -t 'credentials_*'     -t 'webhook_*'     -t 'tag_*'     -t 'settings'     -t 'shared_workflow'     -t 'shared_credentials'     --clean --if-exists     > "${BACKUP_PATH}/n8n_workflows.sql" 2>/dev/null

if [ $? -eq 0 ]; then
    echo "  ✓ 工作流數據備份完成"
else
    echo "  ✗ 工作流數據備份失敗"
fi

# 2. 備份完整的 PostgreSQL 數據庫（完整備份）
echo "[2/4] 備份完整數據庫..."
docker exec supabase-db pg_dump -U supabase_admin -d postgres     --clean --if-exists     | gzip > "${BACKUP_PATH}/postgres_full.sql.gz"

if [ $? -eq 0 ]; then
    echo "  ✓ 完整數據庫備份完成"
else
    echo "  ✗ 完整數據庫備份失敗"
fi

# 3. 備份 n8n 配置檔案和 volume 內容
echo "[3/4] 備份 n8n 配置檔案..."
docker run --rm     -v supabase-n8n-minimal_n8n_data:/data     -v "${BACKUP_PATH}":/backup     alpine tar czf /backup/n8n_data.tar.gz -C /data .

if [ $? -eq 0 ]; then
    echo "  ✓ 配置檔案備份完成"
else
    echo "  ✗ 配置檔案備份失敗"
fi

# 4. 備份 docker-compose 配置
echo "[4/4] 備份 Docker Compose 配置..."
cp /root/docker-compose*.yml "${BACKUP_PATH}/" 2>/dev/null
cp /root/.env "${BACKUP_PATH}/env.backup" 2>/dev/null
echo "  ✓ Docker Compose 配置備份完成"

# 生成備份資訊
cat > "${BACKUP_PATH}/backup_info.txt" << EOF
備份時間: $(date)
備份類型: n8n 工作流與配置
n8n 版本: $(docker exec n8n_app n8n --version 2>/dev/null || echo 'Unknown')
數據庫: PostgreSQL (Supabase)

備份內容:
- n8n_workflows.sql: n8n 工作流和憑證數據
- postgres_full.sql.gz: 完整 PostgreSQL 數據庫
- n8n_data.tar.gz: n8n 配置檔案和數據
- docker-compose*.yml: Docker Compose 配置
- env.backup: 環境變數配置

恢復方法:
1. 恢復數據庫: gunzip -c postgres_full.sql.gz | docker exec -i supabase-db psql -U supabase_admin -d postgres
2. 恢復 n8n 數據: docker run --rm -v supabase-n8n-minimal_n8n_data:/data -v $(pwd):/backup alpine tar xzf /backup/n8n_data.tar.gz -C /data
3. 重啟服務: cd /root && docker compose restart n8n
EOF

# 計算備份大小
BACKUP_SIZE=$(du -sh "${BACKUP_PATH}" | cut -f1)
echo ""
echo "[備份完成] $(date)"
echo "備份大小: ${BACKUP_SIZE}"
echo "備份位置: ${BACKUP_PATH}"

# 清理舊備份
echo ""
echo "[清理舊備份]"
find "${BACKUP_DIR}" -type d -name "n8n_backup_*" -mtime +${RETENTION_DAYS} -exec rm -rf {} + 2>/dev/null
OLD_BACKUPS=$(find "${BACKUP_DIR}" -type d -name "n8n_backup_*" | wc -l)
echo "  保留 ${OLD_BACKUPS} 個備份（${RETENTION_DAYS} 天內）"

# 創建最新備份的符號連結
ln -sfn "${BACKUP_PATH}" "${BACKUP_DIR}/latest"

echo ""
echo "========================================"
echo "備份腳本執行完成"
echo "========================================"
