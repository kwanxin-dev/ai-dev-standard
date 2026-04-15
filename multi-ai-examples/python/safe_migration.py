"""
Safe Migration Helper (Python / MySQL Connector or PyMySQL)

Prevents duplicate migration execution and silent trigger overwrites
when multiple AIs collaborate on the same database.

Requires: scripts/db-safety-init.sql executed first.

Usage:
    import mysql.connector
    from safe_migration import safe_migrate, safe_trigger

    conn = mysql.connector.connect(...)

    result = safe_migrate(conn, 'add_email_column.sql', 'claude', lambda cur: (
        cur.execute('ALTER TABLE customers ADD COLUMN email VARCHAR(255)')
    ), 'Add email column to customers')
    print(result['message'])

    result = safe_trigger(conn, 'after_order_insert', 'claude', lambda cur: (
        cur.execute('DROP TRIGGER IF EXISTS after_order_insert'),
        cur.execute('CREATE TRIGGER after_order_insert ...')
    ), 'orders', 'Update stats after order insert')
"""

from typing import Callable, Optional


def safe_migrate(
    conn,
    filename: str,
    applied_by: str,
    callback: Callable,
    desc: str = "",
) -> dict:
    """
    Safely execute a migration: check if already applied, skip if so.

    Args:
        conn: MySQL connection object
        filename: Migration identifier (unique key)
        applied_by: Who is running this (claude / codex / gemini)
        callback: Function receiving a cursor to execute the migration
        desc: Description of what the migration does

    Returns:
        dict with 'status' ('applied' or 'skipped') and 'message'
    """
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT id, applied_by, applied_at FROM schema_migrations WHERE filename = %s",
        (filename,),
    )
    existing = cursor.fetchone()

    if existing:
        cursor.close()
        return {
            "status": "skipped",
            "message": f"Already applied by {existing['applied_by']} at {existing['applied_at']}, skipping.",
        }

    try:
        cursor.execute(
            "INSERT INTO schema_migrations (filename, applied_by, description) VALUES (%s, %s, %s)",
            (filename, applied_by, desc),
        )

        callback(cursor)

        conn.commit()
        cursor.close()
        return {
            "status": "applied",
            "message": f"Successfully applied by {applied_by}.",
        }
    except Exception as e:
        conn.rollback()
        try:
            cursor.execute(
                "DELETE FROM schema_migrations WHERE filename = %s", (filename,)
            )
            conn.commit()
        except Exception:
            pass
        cursor.close()
        raise RuntimeError(f"Migration [{filename}] failed: {e}") from e


def safe_trigger(
    conn,
    trigger_name: str,
    owner: str,
    callback: Callable,
    event_table: str = "",
    desc: str = "",
) -> dict:
    """
    Safely modify a trigger: check ownership, block if owned by someone else.

    Args:
        conn: MySQL connection object
        trigger_name: Name of the trigger
        owner: Who is requesting the change
        callback: Function receiving a cursor to execute the trigger change
        event_table: Table the trigger is bound to
        desc: Description of the trigger's purpose

    Returns:
        dict with 'status' ('applied' or 'blocked') and 'message'
    """
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT owner, description FROM trigger_registry WHERE trigger_name = %s",
        (trigger_name,),
    )
    existing = cursor.fetchone()

    if existing and existing["owner"] != owner and existing["owner"] != "system":
        cursor.close()
        return {
            "status": "blocked",
            "message": (
                f"BLOCKED: trigger [{trigger_name}] is owned by {existing['owner']} "
                f"({existing['description']}). You ({owner}) cannot modify it."
            ),
        }

    callback(cursor)

    cursor.execute(
        """INSERT INTO trigger_registry (trigger_name, event_table, owner, description)
           VALUES (%s, %s, %s, %s)
           ON DUPLICATE KEY UPDATE owner = VALUES(owner), description = VALUES(description)""",
        (trigger_name, event_table, owner, desc),
    )
    conn.commit()
    cursor.close()

    return {
        "status": "applied",
        "message": f"Trigger [{trigger_name}] updated, owner = {owner}.",
    }
