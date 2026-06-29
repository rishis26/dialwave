import Foundation

/// Creates and migrates the SQLite database schema for DialWave.
///
/// Manages versioned schema migrations so the database evolves gracefully
/// across app updates. Each migration is idempotent (uses `IF NOT EXISTS`).
enum DatabaseSchema {

    /// Current schema version. Increment this when adding migrations.
    static let currentVersion = 1

    /// Creates all database tables if they don't exist.
    /// - Parameter db: The SQLite database instance.
    static func createTables(in db: SQLiteDatabase) {
        db.execute("""
            CREATE TABLE IF NOT EXISTS contacts (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                phone_numbers TEXT NOT NULL,
                email TEXT,
                avatar_data BLOB,
                synced_at REAL NOT NULL DEFAULT (strftime('%s', 'now'))
            )
        """)

        db.execute("""
            CREATE TABLE IF NOT EXISTS call_log (
                id TEXT PRIMARY KEY NOT NULL,
                contact_name TEXT,
                phone_number TEXT NOT NULL,
                type TEXT NOT NULL,
                duration REAL NOT NULL DEFAULT 0,
                timestamp REAL NOT NULL,
                is_read INTEGER NOT NULL DEFAULT 0
            )
        """)

        db.execute("""
            CREATE TABLE IF NOT EXISTS sms_messages (
                id TEXT PRIMARY KEY NOT NULL,
                thread_id TEXT NOT NULL,
                contact_name TEXT,
                phone_number TEXT NOT NULL,
                body TEXT NOT NULL,
                timestamp REAL NOT NULL,
                is_incoming INTEGER NOT NULL DEFAULT 1,
                is_read INTEGER NOT NULL DEFAULT 0
            )
        """)

        db.execute("""
            CREATE TABLE IF NOT EXISTS paired_devices (
                id TEXT PRIMARY KEY NOT NULL,
                name TEXT NOT NULL,
                model TEXT NOT NULL,
                android_version TEXT NOT NULL,
                ip_address TEXT NOT NULL,
                bluetooth_address TEXT NOT NULL,
                last_seen REAL NOT NULL,
                battery_level INTEGER
            )
        """)

        // Indices for common queries
        db.execute("CREATE INDEX IF NOT EXISTS idx_call_log_timestamp ON call_log(timestamp DESC)")
        db.execute("CREATE INDEX IF NOT EXISTS idx_sms_thread ON sms_messages(thread_id, timestamp DESC)")
        db.execute("CREATE INDEX IF NOT EXISTS idx_contacts_name ON contacts(name COLLATE NOCASE)")

        // Store schema version
        db.execute("""
            CREATE TABLE IF NOT EXISTS schema_version (
                version INTEGER PRIMARY KEY NOT NULL
            )
        """)
        db.executeUpdate("INSERT OR REPLACE INTO schema_version (version) VALUES (?)", values: [currentVersion])

        AppLogger.info("Database schema v\(currentVersion) created/verified", category: .storage)
    }

    /// Run any pending migrations to bring the schema up to date.
    /// - Parameter db: The SQLite database instance.
    static func migrateIfNeeded(in db: SQLiteDatabase) {
        let rows = db.executeQuery("SELECT version FROM schema_version LIMIT 1")
        let existingVersion = (rows.first?["version"] as? Int64).map { Int($0) } ?? 0

        if existingVersion < currentVersion {
            AppLogger.info("Migrating database from v\(existingVersion) to v\(currentVersion)", category: .storage)
            applyMigrations(from: existingVersion, in: db)
        }
    }

    /// Applies migrations incrementally from the old version to current.
    private static func applyMigrations(from oldVersion: Int, in db: SQLiteDatabase) {
        // Future migrations go here:
        // if oldVersion < 2 { migrateV1toV2(db) }
        // if oldVersion < 3 { migrateV2toV3(db) }

        db.executeUpdate("INSERT OR REPLACE INTO schema_version (version) VALUES (?)", values: [currentVersion])
        AppLogger.info("Migration complete — now at v\(currentVersion)", category: .storage)
    }
}
