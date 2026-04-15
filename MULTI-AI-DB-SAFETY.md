# Multi-AI DB Safety — 多 AI 共用資料庫協作規範

## 問題

當多個 AI（Claude / Codex / Gemini）同時開發同一個專案，檔案隔離可以靠 Git Worktree 或獨立目錄解決，但**資料庫是共用的**。以下三種衝突無法靠 Git 解決：

| 衝突類型 | 情境 | 後果 |
|---------|------|------|
| Migration 重複執行 | AI-A 跑了 `ALTER TABLE ADD COLUMN x`，AI-B 不知道又跑一次 | 報錯：Duplicate column |
| Trigger 靜默覆蓋 | AI-A 建了 trigger，AI-B 重建同名 trigger 把 AI-A 的邏輯覆蓋 | **不報錯**，邏輯斷裂 |
| 測試資料互擾 | AI-A 插入測試資料改變筆數，AI-B 驗證筆數時以為出 bug | 假性失敗 |

## 解決方案

### 1. schema_migrations — Migration 防重複執行

建立一張登記表，每次跑 migration 前先查、跑完登記：

```sql
CREATE TABLE IF NOT EXISTS schema_migrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    filename VARCHAR(255) NOT NULL UNIQUE COMMENT '遷移檔名（唯一鍵，防止重複執行）',
    checksum VARCHAR(64) DEFAULT NULL COMMENT 'SHA-256 校驗碼（可選）',
    applied_by VARCHAR(50) NOT NULL COMMENT '執行者標識（claude / codex / gemini / manual）',
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP COMMENT '執行時間',
    description VARCHAR(500) DEFAULT NULL COMMENT '簡述此 migration 做了什麼',
    INDEX idx_applied_by (applied_by),
    INDEX idx_applied_at (applied_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Migration 登記表：防止多 AI 重複執行 schema 變更';
```

**執行流程：**

```
執行 migration 前
    │
    ▼
查詢 schema_migrations：這個 filename 執行過嗎？
    │
    ├── 是 → 跳過，回報「已被 xxx 於 yyyy 執行過」
    │
    └── 否 → 登記 + 執行（在 transaction 中）
                │
                ├── 成功 → commit
                └── 失敗 → rollback + 刪除登記
```

### 2. trigger_registry — Trigger Ownership 鎖定

建立一張擁有者登記表，修改 trigger 前先查 ownership：

```sql
CREATE TABLE IF NOT EXISTS trigger_registry (
    trigger_name VARCHAR(128) PRIMARY KEY COMMENT 'Trigger 名稱',
    event_table VARCHAR(128) NOT NULL COMMENT '綁定的表名',
    owner VARCHAR(50) NOT NULL COMMENT '擁有者標識（claude / codex / system）',
    description VARCHAR(500) DEFAULT NULL COMMENT '此 trigger 的用途',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_owner (owner),
    INDEX idx_event_table (event_table)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4
  COMMENT='Trigger 鎖定表：防止多 AI 靜默覆蓋 trigger';
```

**執行流程：**

```
修改 trigger 前
    │
    ▼
查詢 trigger_registry：這個 trigger 屬於誰？
    │
    ├── 屬於別人 → ⛔ 阻斷，回報「此 trigger 屬於 xxx，你不能修改」
    ├── 屬於自己 → 執行修改 + 更新 registry
    └── 未登記   → 執行修改 + 新增 registry
```

> **注意：** 如果你的專案不使用 DB trigger（邏輯全在應用層），可以跳過此表。

### 3. 測試資料 ID 分區

各 AI 使用不同的 ID 範圍，避免互相干擾：

| 範圍 | 用途 |
|------|------|
| 1 – 999 | 正式資料（不可刪改） |
| 1000 – 1999 | AI-1（如 claude）測試用 |
| 2000 – 2999 | AI-2（如 codex）測試用 |
| 3000 – 3999 | AI-3（如 gemini）測試用 |
| 4000 – 4999 | 手動測試用 |

**規則：**
- 插入測試資料時**必須**指定 ID 在自己的範圍內
- 驗證筆數時排除測試資料：`SELECT COUNT(*) FROM xxx WHERE id < 1000`
- 各 AI 可自由清理**自己範圍**的測試資料，不可動別人的

## 快速開始

```bash
# 1. 初始化安全表（在你的專案 DB 上執行）
mysql -u root -p your_database < scripts/db-safety-init.sql

# 2. 複製對應語言的 helper 到你的專案
cp multi-ai-examples/php/safe_migration.php /your-project/includes/
# 或
cp multi-ai-examples/nodejs/safeMigration.js /your-project/lib/
# 或
cp multi-ai-examples/python/safe_migration.py /your-project/utils/

# 3. 將以下規則加入你專案的 CLAUDE.md（見 CLAUDE-CI-RULES.md 第 8 條）

# 4. 登記現有 trigger（如有）
mysql -u root -p your_database -e "
  INSERT INTO trigger_registry (trigger_name, event_table, owner, description)
  VALUES ('your_trigger', 'your_table', 'system', '描述');
"
```

## 與現有標準的關係

此規範補充了 `Phase A`（開發階段）的 DB 安全缺口：

```
Phase A (Development)
├── Review Gate          ← 既有（程式碼審查）
├── Adversarial Review   ← 既有（安全角度審查）
└── DB Safety            ← 新增（多 AI 共用 DB 防護）
        ├── schema_migrations（防重複 migration）
        ├── trigger_registry（防 trigger 覆蓋）
        └── ID 分區（防測試資料互擾）

Phase C/D (Deployment)
├── DB Backup            ← 既有（部署前備份）
└── DB Rollback          ← 既有（失敗回滾）
```

對應的審查角度：**B4 Regression Safety**（回歸安全性）。
