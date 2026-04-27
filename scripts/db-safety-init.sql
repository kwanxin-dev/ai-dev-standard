-- ============================================================
-- DB Safety Init — 多 AI 協作安全表初始化
--
-- 使用方式：
--   mysql -u root -p your_database < scripts/db-safety-init.sql
--
-- 建立：
--   1. schema_migrations — 防止 migration 重複執行
--   2. trigger_registry  — 防止 trigger 被靜默覆蓋
--
-- 安全：使用 IF NOT EXISTS，重複執行不會報錯
-- ============================================================

-- 1. Migration 登記表
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

-- 2. Trigger 鎖定表（如果專案不用 DB trigger 可省略）
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

-- 驗證
SELECT 'schema_migrations' AS created_table, COUNT(*) AS rows_count FROM schema_migrations
UNION ALL
SELECT 'trigger_registry', COUNT(*) FROM trigger_registry;
