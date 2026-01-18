# n8n Task Runners Starter

> **教學首選**：不需信用卡、不需繁瑣設定，使用 GitHub Codespaces 一鍵啟動。

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/richblack/n8n-TaskRunners-Starter)

這個 Starter Kit 包含一個預先配置好的 n8n 環境，整合了 PostgreSQL 資料庫和一個專用的 Python Task Runner。
特別適合 **教學環境** 或 **需要安裝自定義 Python 套件** 的場景。

## 🚀 快速開始 (GitHub Codespaces)

這是最簡單的啟動方式，完全在瀏覽器中執行：

1. 點擊上方的 **Open in GitHub Codespaces** 按鈕。
2. 登入 GitHub 帳號並確認建立 Codespace。
3. 等待環境建置完成（約 2-3 分鐘），系統會自動執行 `docker-compose up`。
4. 當右下角出現 "Open in Browser" 提示時，點擊即可開啟 n8n (Port 5678)。
   - 或切換到 "PORTS" 分頁，點擊 5678 旁的地球圖示。

---

## ☁️ 部署至 Zeabur (雲端環境)

<a href="https://zeabur.com/templates/56Y03Z?referralCode=richblack"><img src="https://zeabur.com/button.svg" alt="Deploy on Zeabur"/></a>


## 快速開始

### 1. 複製並設定環境變數

```bash
cp .env.example .env
```

編輯 `.env` 檔案，設定你的密碼和金鑰：

```bash
# 產生隨機金鑰
openssl rand -hex 32
```

### 2. 啟動服務

```bash
docker compose up -d
```

### 3. 存取 n8n

開啟瀏覽器前往 http://localhost:5678

## 檔案結構

```
.
├── docker-compose.yml          # 主要配置檔
├── .env.example                # 環境變數範本
└── task-runner/
    ├── Dockerfile              # Python runner 自訂映像
    └── n8n-task-runners.json   # Python 模組白名單設定
```

## 包含的服務

| 服務 | 說明 | 端口 |
|------|------|------|
| n8n | 工作流程自動化平台 | 5678 |
| db | PostgreSQL 資料庫 | - |
| task-runners | Python Code Tool 執行環境 | - |

## Python Code Tool 使用說明

### 變數名稱（v2.0+ 重要變更）

```python
# 取得輸入資料
data = _query  # 注意：v2.0 使用 _query，不是 query
```

### 程式碼範本

```python
import warnings
warnings.filterwarnings('ignore')

import sys
import io

old_stderr = sys.stderr
sys.stderr = io.StringIO()

try:
    import json
    import pandas as pd

    # 取得輸入資料
    input_data = _query

    if isinstance(input_data, str):
        input_data = json.loads(input_data)

    # 你的分析邏輯
    df = pd.DataFrame(input_data)
    result = {
        "count": int(len(df)),  # 注意：使用 int() 轉換 numpy 類型
        "columns": list(df.columns)
    }

    response = json.dumps(result, ensure_ascii=False)

except Exception as e:
    response = f"錯誤：{str(e)}"
finally:
    sys.stderr = old_stderr

return response
```

## 新增 Python 套件

1. 編輯 `task-runner/Dockerfile`：

```dockerfile
RUN pip install --no-cache-dir \
    --target=/opt/runners/task-runner-python/.venv/lib/python3.13/site-packages \
    pandas numpy \
    scikit-learn \    # 新增套件
    requests
```

2. 重建並重啟：

```bash
docker compose build --no-cache task-runners
docker compose up -d task-runners
```

## 版本資訊

| 元件 | 版本 |
|------|------|
| n8n | 2.2.3 |
| runners | 2.2.3 |
| Python | 3.13 |
| pandas | 2.3.3 |
| numpy | 2.4.0 |

## 常見問題

### Failed to read result from child process

**原因**：Python 模組被禁用或 stderr 干擾。

**解決方案**：
1. 確認 `n8n-task-runners.json` 設定正確
2. 在程式碼開頭加入 `warnings.filterwarnings('ignore')`
3. 捕獲 stderr（參考上方範本）

### ModuleNotFoundError

**原因**：套件未安裝在 task-runner 容器中。

**解決方案**：修改 Dockerfile 新增套件後重建。

### JSON 序列化錯誤

**原因**：numpy 類型（int64/float64）無法直接序列化。

**解決方案**：使用 `int()`、`float()`、`list()` 轉換。

## 參考資源

- [n8n 官方文件](https://docs.n8n.io/)
- [n8n Task Runners 文件](https://docs.n8n.io/hosting/scaling/task-runners/)

## 授權

MIT License

## Zeabur 部署指南

由於 n8n v2.0+ 架構包含三個核心服務（Main, Database, Worker），在 Zeabur 部署時請遵循以下步驟：

### 重點說明
此專案會建立三個服務：
1. **n8n-stack-db** (PostgreSQL)
2. **n8n-stack-n8n** (主程式)
3. **n8n-stack-task-runners** (Python Worker)

### 部署步驟

1. **建立專案**：在 Zeabur 建立一個新專案。
2. **部署服務**：
    - 選擇 **Deploy New Service** -> **Git**。
    - 選擇此儲存庫。
    - Zeabur 應會自動偵測到 `docker-compose.yml` 並詢問是否要部署所有服務，請確認三個服務都被勾選。
3. **環境變數設定**：
    - 服務建立後，請到各個服務的 "Settings" -> "Environment Variables" 設定 `.env` 中提到的變數。
    - 特別注意 `POSTGRES_PASSWORD` 和 `N8N_ENCRYPTION_KEY` 必須在相關服務中一致。
    - Zeabur 會自動處理內部網路連線，通常不需要修改 host 設定，但請確認 `DB_POSTGRESDB_HOST` 指向正確的資料庫服務名稱（Zeabur 可能會加上前綴，如 `n8n-stack-db`）。

### 常見問題：部署設定
**Q: 如果自動部署失敗（只出現一個 Caddy 靜態服務或 SERVICE_NOT_FOUND）？**
A: 這表示 Zeabur 未能正確識別 `docker-compose.yml`。請改用 **手動分開部署** 模式，這是最穩定的方式：

1. **建立資料庫 (Service 1)**：
   - 點選 "Prebuilt Services" -> 搜尋並選擇 **PostgreSQL**。
   - 記下連線資訊（或使用 Zeabur 內網 dns）。

2. **建立 n8n 主程式 (Service 2)**：
   - 點選 "Prebuilt Services" -> "Docker Image"。
   - 輸入 Image: `n8nio/n8n:2.2.3`（或最新版）。
   - 設定環境變數（參考 `.env`）。

3. **建立 Task Runner (Service 3)**：
   - 點選 "Git Service" -> 選擇本專案儲存庫。
   - **關鍵設定**：在 "Settings" -> "Source" -> **"Root Directory"** 輸入 `/task-runner`。
        - 這會告訴 Zeabur 進入該目錄讀取 `Dockerfile`，從而正確建立 Python Worker。
   - 設定環境變數，並確保 `N8N_RUNNERS_TASK_BROKER_URI` 指向 n8n 主程式的內部網址。

**Q: 服務之間如何連線？**
A: 在 Zeabur 中，使用服務名稱作為 Host。
- n8n 連 DB：`DB_POSTGRESDB_HOST` = `postgresql` (或您建立的 DB 服務名稱)
- Worker 連 n8n：`N8N_RUNNERS_TASK_BROKER_URI` = `http://n8n:5679` (將 `n8n` 替換為您的 n8n 服務名稱)


## 進階：建立 Zeabur 部署模板 (Template)

如果您希望將此專案製作成 "Deploy on Zeabur" 的一鍵部署模板，可以使用本專案內附的 `zeabur.yaml`。

此檔案依照 [Zeabur Template Specification](https://zeabur.com/docs/deploy/template-spec) 撰寫，定義了三個服務的自動部署流程。

**使用方式：**
1. 將此專案 Push 到您的 GitHub。
2. 修改 `zeabur.yaml` 中的 `spec.services[2].spec.source.url`，將其指向您的 GitHub Repo URL（需公開或授權）。

**3. 透過 CLI 提交與部署：**

如果您已安裝並登入 Zeabur CLI (`npx zeabur auth login`)：

- **立即部署 (測試用)**：
  ```bash
  npx zeabur template deploy -f zeabur.yaml
  ```
  這會直接在您選擇的專案中建立服務。

- **註冊模板 (分享用)**：
  ```bash
  npx zeabur template create -f zeabur.yaml
  ```
  這會將模板儲存到您的帳戶，您可以在 Dashboard 查看代碼 (Code)，讓其他人透過該代碼部署。



