import Foundation
import GRDB

/// On-device local-first store — the **source of truth** for the user. Cloud (BrickBack
/// user project) is only a premium sync mirror. Direct port of `app_database.dart`
/// (Drift schemaVersion 3), minus the `step_qty` column (00-architecture §5): the per-part
/// counting step is in-memory session state (S3), never persisted.
///
/// All writes funnel through `writer` (a serial GRDB queue) so the UI and the later sync
/// engine never fight over the connection (S1 risk note).
public final class AppDatabase: Sendable {
    /// Serial write queue. Package-internal: the app never touches GRDB directly — it goes
    /// through the repositories, which expose GRDB-free async APIs.
    let writer: any DatabaseWriter

    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// The on-disk store at `Application Support/brickback.sqlite`.
    public static func live() throws -> AppDatabase {
        let fm = FileManager.default
        let dir = try fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let url = dir.appendingPathComponent("brickback.sqlite")
        var config = Configuration()
        config.foreignKeysEnabled = false // parity with Drift (no FKs declared; parents pushed first)
        let queue = try DatabaseQueue(path: url.path, configuration: config)
        return try AppDatabase(queue)
    }

    /// In-memory store for tests (mirrors `AppDatabase.forTesting`).
    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(try DatabaseQueue())
    }

    // MARK: - Migrations

    /// Named migrations reproducing the Drift history (00-architecture §5):
    /// - v1: rebuild_sets, rebuild_parts (no category_name), rebuild_minifigs, verifications
    /// - v2: + rebuild_parts.category_name; create rebuild_extra_parts
    /// - v3: + rebuild_sets.images_cached_at (S9 offline image cache; device-local, not synced).
    ///   This is **not** the Drift v3 `step_qty` column — that stays dropped (00-architecture §5).
    static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("v1") { db in
            try db.create(table: "rebuild_sets") { t in
                t.column("id", .text).primaryKey()
                t.column("set_item_id", .integer).notNull()
                t.column("name", .text).notNull().defaults(to: "")
                t.column("theme", .text)
                t.column("year", .integer)
                t.column("image_url", .text)
                t.column("total_parts", .integer).notNull().defaults(to: 0)
                t.column("verified_at", .datetime)
                t.column("created_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("dirty", .boolean).notNull().defaults(to: true)
                t.column("deleted", .boolean).notNull().defaults(to: false)
            }

            try db.create(table: "rebuild_parts") { t in
                t.column("rebuild_set_id", .text).notNull()
                t.column("part_item_id", .integer).notNull()
                t.column("color_id", .integer).notNull()
                t.column("needed_qty", .integer).notNull().defaults(to: 0)
                t.column("have_qty", .integer).notNull().defaults(to: 0)
                t.column("part_name", .text).notNull().defaults(to: "")
                t.column("part_num", .text)
                t.column("part_cat_id", .integer)
                // category_name added in v2
                t.column("color_name", .text)
                t.column("color_rgb", .text)
                t.column("image_url", .text)
                t.column("bl_part_id", .text)
                t.column("bl_color_id", .integer)
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("dirty", .boolean).notNull().defaults(to: true)
                t.column("deleted", .boolean).notNull().defaults(to: false)
                t.primaryKey(["rebuild_set_id", "part_item_id", "color_id"])
            }

            try db.create(table: "rebuild_minifigs") { t in
                t.column("rebuild_set_id", .text).notNull()
                t.column("minifig_item_id", .integer).notNull()
                t.column("needed_qty", .integer).notNull().defaults(to: 0)
                t.column("have_qty", .integer).notNull().defaults(to: 0)
                t.column("name", .text).notNull().defaults(to: "")
                t.column("image_url", .text)
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("dirty", .boolean).notNull().defaults(to: true)
                t.column("deleted", .boolean).notNull().defaults(to: false)
                t.primaryKey(["rebuild_set_id", "minifig_item_id"])
            }

            try db.create(table: "verifications") { t in
                t.column("id", .text).primaryKey()
                t.column("rebuild_set_id", .text).notNull()
                t.column("set_item_id", .integer).notNull()
                t.column("completion_pct", .double).notNull().defaults(to: 0)
                t.column("parts_needed", .integer)
                t.column("parts_found", .integer)
                t.column("minifigs_needed", .integer)
                t.column("minifigs_found", .integer)
                t.column("flags", .text).notNull().defaults(to: "{}")
                t.column("notes", .text)
                t.column("verified_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("updated_at", .datetime).notNull().defaults(sql: "CURRENT_TIMESTAMP")
                t.column("dirty", .boolean).notNull().defaults(to: true)
                t.column("deleted", .boolean).notNull().defaults(to: false)
            }
        }

        migrator.registerMigration("v2") { db in
            // v1 -> v2: "group by type" (category_name) + the extras (spares) list.
            try db.alter(table: "rebuild_parts") { t in
                t.add(column: "category_name", .text)
            }
            try db.create(table: "rebuild_extra_parts") { t in
                t.column("rebuild_set_id", .text).notNull()
                t.column("part_item_id", .integer).notNull()
                t.column("color_id", .integer).notNull()
                t.column("needed_qty", .integer).notNull().defaults(to: 0)
                t.column("have_qty", .integer).notNull().defaults(to: 0)
                t.column("part_name", .text).notNull().defaults(to: "")
                t.column("part_num", .text)
                t.column("part_cat_id", .integer)
                t.column("category_name", .text)
                t.column("color_name", .text)
                t.column("color_rgb", .text)
                t.column("image_url", .text)
                t.primaryKey(["rebuild_set_id", "part_item_id", "color_id"])
            }
        }

        migrator.registerMigration("v3") { db in
            // Offline mode (S9): a device-local marker per set — stamped once every one of the
            // set's image URLs is cached on disk. NULL ⇒ prefetch incomplete ⇒ resume when next
            // online. Never synced (no dirty/deleted); the cloud schema is unchanged.
            try db.alter(table: "rebuild_sets") { t in
                t.add(column: "images_cached_at", .datetime)
            }
        }

        return migrator
    }
}
