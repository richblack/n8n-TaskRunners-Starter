#!/bin/bash

# n8n 恢復腳本
# 從備份恢復 n8n 工作流和配置

# 顏色定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

BACKUP_DIR="/root/backups/n8n"

echo "========================================"
echo "n8n 備份恢復工具"
echo "========================================"
echo ""

# 列出可用的備份
echo "可用的備份:"
echo ""
ls -lhd ${BACKUP_DIR}/n8n_backup_* 2>/dev/null | awk '{print NR". "$9" ("$6" "$7" "$8")"}'

if [ $? -ne 0 ]; then
    echo -e "${RED}✗ 沒有找到備份檔案${NC}"
    exit 1
fi

echo ""
echo "最新備份: ${BACKUP_DIR}/latest"
echo ""

# 如果有參數，使用指定的備份路徑
if [ -n "$1" ]; then
    RESTORE_PATH="$1"
else
    # 否則使用最新的備份
    RESTORE_PATH="${BACKUP_DIR}/latest"
fi

# 檢查備份路徑是否存在
if [ ! -d "${RESTORE_PATH}" ]; then
    echo -e "${RED}✗ 備份路徑不存在: ${RESTORE_PATH}${NC}"
    exit 1
fi

echo -e "${YELLOW}準備從以下位置恢復:${NC}"
echo "  ${RESTORE_PATH}"
echo ""

# 顯示備份資訊
if [ -f "${RESTORE_PATH}/backup_info.txt" ]; then
    echo "備份資訊:"
    cat "${RESTORE_PATH}/backup_info.txt"
    echo ""
fi

# 確認恢復操作
echo -e "${RED}警告: 此操作將覆蓋現有的 n8n 數據！${NC}"
read -p "確定要繼續嗎？(yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "操作已取消"
    exit 0
fi

echo ""
echo "[開始恢復] $(date)"

# 1. 停止 n8n 服務
echo "[1/3] 停止 n8n 服務..."
docker stop n8n_app
echo -e "  ${GREEN}✓${NC} n8n 已停止"

# 2. 恢復數據庫
echo "[2/3] 恢復數據庫..."
if [ -f "${RESTORE_PATH}/postgres_full.sql.gz" ]; then
    gunzip -c "${RESTORE_PATH}/postgres_full.sql.gz" | docker exec -i supabase-db psql -U supabase_admin -d postgres > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✓${NC} 數據庫恢復完成"
    else
        echo -e "  ${RED}✗${NC} 數據庫恢復失敗"
    fi
else
    echo -e "  ${YELLOW}!${NC} 未找到完整數據庫備份，嘗試恢復 n8n 工作流數據..."
    if [ -f "${RESTORE_PATH}/n8n_workflows.sql" ]; then
        docker exec -i supabase-db psql -U supabase_admin -d postgres < "${RESTORE_PATH}/n8n_workflows.sql" > /dev/null 2>&1
        echo -e "  ${GREEN}✓${NC} n8n 工作流數據恢復完成"
    fi
fi

# 3. 恢復 n8n 配置檔案
echo "[3/3] 恢復 n8n 配置檔案..."
if [ -f "${RESTORE_PATH}/n8n_data.tar.gz" ]; then
    docker run --rm         -v supabase-n8n-minimal_n8n_data:/data         -v "${RESTORE_PATH}":/backup         alpine sh -c "rm -rf /data/* && tar xzf /backup/n8n_data.tar.gz -C /data"
    echo -e "  ${GREEN}✓${NC} 配置檔案恢復完成"
else
    echo -e "  ${YELLOW}!${NC} 未找到配置檔案備份"
fi

# 4. 啟動 n8n 服務
echo ""
echo "啟動 n8n 服務..."
docker start n8n_app
sleep 5

# 檢查服務狀態
if docker ps | grep -q n8n_app; then
    echo -e "${GREEN}✓ n8n 服務已啟動${NC}"
else
    echo -e "${RED}✗ n8n 服務啟動失敗${NC}"
fi

echo ""
echo "========================================"
echo -e "${GREEN}恢復完成！${NC}"
echo "========================================"
echo ""
echo "請檢查 n8n 服務狀態: docker logs n8n_app"
