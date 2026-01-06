# n8n v2.0+ with Python Task Runner

n8n 自動化工作流程平台，含 Python Code Tool 支援（pandas/numpy）。

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
