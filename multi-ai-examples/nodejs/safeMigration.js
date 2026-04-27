/**
 * Safe Migration Helper (Node.js / mysql2)
 *
 * Prevents duplicate migration execution and silent trigger overwrites
 * when multiple AIs collaborate on the same database.
 *
 * Requires: scripts/db-safety-init.sql executed first.
 *
 * Usage:
 *   const { safeMigrate, safeTrigger } = require('./safeMigration');
 *
 *   await safeMigrate(pool, 'add_email_column.sql', 'claude', async (conn) => {
 *     await conn.execute('ALTER TABLE customers ADD COLUMN email VARCHAR(255)');
 *   }, 'Add email column to customers');
 *
 *   await safeTrigger(pool, 'after_order_insert', 'claude', async (conn) => {
 *     await conn.execute('DROP TRIGGER IF EXISTS after_order_insert');
 *     await conn.execute('CREATE TRIGGER after_order_insert ...');
 *   }, 'orders', 'Update stats after order insert');
 */

/**
 * Safely execute a migration: check if already applied, skip if so.
 *
 * @param {import('mysql2/promise').Pool} pool
 * @param {string} filename   - Migration identifier (unique key)
 * @param {string} appliedBy  - Who is running this (claude / codex / gemini)
 * @param {Function} callback - Async function receiving a connection
 * @param {string} [desc]     - Description of what the migration does
 * @returns {Promise<{status: 'applied'|'skipped', message: string}>}
 */
async function safeMigrate(pool, filename, appliedBy, callback, desc = '') {
  const [rows] = await pool.execute(
    'SELECT id, applied_by, applied_at FROM schema_migrations WHERE filename = ?',
    [filename]
  );

  if (rows.length > 0) {
    const { applied_by, applied_at } = rows[0];
    return {
      status: 'skipped',
      message: `Already applied by ${applied_by} at ${applied_at}, skipping.`,
    };
  }

  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    await conn.execute(
      'INSERT INTO schema_migrations (filename, applied_by, description) VALUES (?, ?, ?)',
      [filename, appliedBy, desc]
    );

    await callback(conn);

    await conn.commit();
    return { status: 'applied', message: `Successfully applied by ${appliedBy}.` };
  } catch (err) {
    await conn.rollback();
    try {
      await pool.execute('DELETE FROM schema_migrations WHERE filename = ?', [filename]);
    } catch (_) {}
    throw new Error(`Migration [${filename}] failed: ${err.message}`);
  } finally {
    conn.release();
  }
}

/**
 * Safely modify a trigger: check ownership, block if owned by someone else.
 *
 * @param {import('mysql2/promise').Pool} pool
 * @param {string} triggerName
 * @param {string} owner       - Who is requesting the change
 * @param {Function} callback  - Async function receiving a connection
 * @param {string} [eventTable]
 * @param {string} [desc]
 * @returns {Promise<{status: 'applied'|'blocked', message: string}>}
 */
async function safeTrigger(pool, triggerName, owner, callback, eventTable = '', desc = '') {
  const [rows] = await pool.execute(
    'SELECT owner, description FROM trigger_registry WHERE trigger_name = ?',
    [triggerName]
  );

  if (rows.length > 0 && rows[0].owner !== owner && rows[0].owner !== 'system') {
    return {
      status: 'blocked',
      message: `BLOCKED: trigger [${triggerName}] is owned by ${rows[0].owner} (${rows[0].description}). You (${owner}) cannot modify it.`,
    };
  }

  const conn = await pool.getConnection();
  try {
    await callback(conn);

    await conn.execute(
      `INSERT INTO trigger_registry (trigger_name, event_table, owner, description)
       VALUES (?, ?, ?, ?)
       ON DUPLICATE KEY UPDATE owner = VALUES(owner), description = VALUES(description)`,
      [triggerName, eventTable, owner, desc]
    );
  } finally {
    conn.release();
  }

  return { status: 'applied', message: `Trigger [${triggerName}] updated, owner = ${owner}.` };
}

module.exports = { safeMigrate, safeTrigger };
