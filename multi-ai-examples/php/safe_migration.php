<?php
/**
 * Safe Migration Helper (PHP / PDO)
 *
 * 防止多 AI 同步開發時 migration 重複執行、trigger 被靜默覆蓋。
 * 需要先執行 scripts/db-safety-init.sql 建立安全表。
 *
 * 使用方式：
 *   require_once 'safe_migration.php';
 *
 *   // 安全執行 migration
 *   $result = safe_migrate($pdo, 'add_email_column.sql', 'claude', function($pdo) {
 *       $pdo->exec("ALTER TABLE customers ADD COLUMN email VARCHAR(255)");
 *   }, '客戶表新增 email 欄位');
 *   echo $result['message'];
 *
 *   // 安全修改 trigger
 *   $result = safe_trigger($pdo, 'after_order_insert', 'claude', function($pdo) {
 *       $pdo->exec("DROP TRIGGER IF EXISTS after_order_insert");
 *       $pdo->exec("CREATE TRIGGER after_order_insert AFTER INSERT ON orders ...");
 *   }, 'orders', '訂單新增後更新統計');
 */

/**
 * 安全執行 migration：檢查是否已執行過，未執行才跑
 *
 * @param PDO      $pdo        資料庫連線
 * @param string   $filename   Migration 檔名（唯一識別）
 * @param string   $appliedBy  執行者標識（claude / codex / gemini / manual）
 * @param callable $callback   實際要執行的 migration 邏輯
 * @param string   $desc       簡述此 migration 做了什麼
 * @return array   ['status' => 'applied'|'skipped', 'message' => string]
 */
function safe_migrate(PDO $pdo, string $filename, string $appliedBy, callable $callback, string $desc = ''): array
{
    $stmt = $pdo->prepare("SELECT id, applied_by, applied_at FROM schema_migrations WHERE filename = :f");
    $stmt->execute([':f' => $filename]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        return [
            'status'  => 'skipped',
            'message' => "Already applied by {$existing['applied_by']} at {$existing['applied_at']}, skipping."
        ];
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            "INSERT INTO schema_migrations (filename, applied_by, description) VALUES (:f, :by, :desc)"
        );
        $stmt->execute([':f' => $filename, ':by' => $appliedBy, ':desc' => $desc]);

        $callback($pdo);

        $pdo->commit();
        return [
            'status'  => 'applied',
            'message' => "Successfully applied by {$appliedBy}."
        ];
    } catch (\Throwable $e) {
        $pdo->rollBack();
        try {
            $pdo->prepare("DELETE FROM schema_migrations WHERE filename = :f")->execute([':f' => $filename]);
        } catch (\Throwable $ignore) {}

        throw new \RuntimeException("Migration [{$filename}] failed: " . $e->getMessage(), 0, $e);
    }
}

/**
 * 安全修改 trigger：檢查 ownership，非擁有者不能動
 *
 * @param PDO      $pdo          資料庫連線
 * @param string   $triggerName  Trigger 名稱
 * @param string   $owner        請求修改的擁有者標識
 * @param callable $callback     實際要執行的 trigger 變更邏輯
 * @param string   $eventTable   綁定的表名
 * @param string   $desc         此 trigger 的用途
 * @return array   ['status' => 'applied'|'blocked', 'message' => string]
 */
function safe_trigger(PDO $pdo, string $triggerName, string $owner, callable $callback, string $eventTable = '', string $desc = ''): array
{
    $stmt = $pdo->prepare("SELECT owner, description FROM trigger_registry WHERE trigger_name = :tn");
    $stmt->execute([':tn' => $triggerName]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($existing && $existing['owner'] !== $owner && $existing['owner'] !== 'system') {
        return [
            'status'  => 'blocked',
            'message' => "BLOCKED: trigger [{$triggerName}] is owned by {$existing['owner']} ({$existing['description']}). You ({$owner}) cannot modify it."
        ];
    }

    $callback($pdo);

    $stmt = $pdo->prepare(
        "INSERT INTO trigger_registry (trigger_name, event_table, owner, description)
         VALUES (:tn, :et, :ow, :desc)
         ON DUPLICATE KEY UPDATE owner = VALUES(owner), description = VALUES(description)"
    );
    $stmt->execute([':tn' => $triggerName, ':et' => $eventTable, ':ow' => $owner, ':desc' => $desc]);

    return [
        'status'  => 'applied',
        'message' => "Trigger [{$triggerName}] updated, owner = {$owner}."
    ];
}
