import Foundation
import SQLite3

// SQLite wrapper — tiny convenience layer so we don’t write C every time

public final class GameStoreDatabase {
    @MainActor
    public static let shared = GameStoreDatabase()
    private let db: OpaquePointer!

    // Helper: tells SQLite to *copy* the text we bind, so Swift can free its memory.
    public static let transientSQLite = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    private init() {
        // Open (or create) a file‑based SQLite database in /tmp
        let path = FileManager.default.temporaryDirectory
            .appendingPathComponent("gamestore.sqlite").path
        var handle: OpaquePointer?
        guard sqlite3_open(path, &handle) == SQLITE_OK, let handle else {
            fatalError("Unable to open SQLite database")
        }
        db = handle
        execute("PRAGMA foreign_keys = ON;")
    }

    deinit { sqlite3_close(db) }

    @discardableResult
    /// Execute any SQL statement that should *not* return rows.
    /// Crashes if SQLite reports an error — fine for a teaching demo.
    public func execute(_ sql: String) -> Int32 {
        var errorPointer: UnsafeMutablePointer<Int8>?
        let returnCode = sqlite3_exec(db, sql, nil, nil, &errorPointer)
        guard returnCode == SQLITE_OK else {
            let errorMessage = errorPointer.map { String(cString: $0) } ?? "unknown error"
            fatalError("SQLite \(returnCode): \(errorMessage)\nSQL → \(sql)")
        }
        return returnCode
    }

    /// Same as `execute` but returns the returnCode for deliberate failures.
    @discardableResult
    public func executeAllowingError(_ sql: String) -> Int32 {
        var errorPointer: UnsafeMutablePointer<Int8>?
        let returnCode = sqlite3_exec(db, sql, nil, nil, &errorPointer)
        if returnCode != SQLITE_OK {
            let errorMessage = errorPointer.map { String(cString: $0) } ?? "unknown error"
            print("SQLite expected error (\(returnCode)): \(errorMessage)")
        }
        return returnCode
    }

    /// Run a SELECT and get each row back as [columnName: value].
    public func query(_ sql: String) -> [[String: Any]] {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK,
              let statement = statement else { fatalError("Bad SQL: \(sql)") }
        defer { sqlite3_finalize(statement) }

        var rows: [[String: Any]] = []
        while sqlite3_step(statement) == SQLITE_ROW {
            var row: [String: Any] = [:]
            for columnIndex in 0 ..< sqlite3_column_count(statement) {
                let key = String(cString: sqlite3_column_name(statement, columnIndex))
                switch sqlite3_column_type(statement, columnIndex) {
                case SQLITE_INTEGER: row[key] = Int(sqlite3_column_int64(statement, columnIndex))
                case SQLITE_FLOAT:   row[key] = sqlite3_column_double(statement, columnIndex)
                case SQLITE_TEXT:    row[key] = String(cString: sqlite3_column_text(statement, columnIndex))
                default:             row[key] = nil
                }
            }
            rows.append(row)
        }
        return rows
    }

    /// Convenience: return first column of first row as Int.
    public func scalarInt(_ sql: String) -> Int {
        (query(sql).first?.values.first as? Int) ?? 0
    }

    /// Use PRAGMA to inspect schema — handy for migrations.
    public func columnExists(table: String, column: String) -> Bool {
        query("PRAGMA table_info(\(table));")
            .contains { $0["name"] as? String == column }
    }

    /// Prepare once, execute many — we pass the prepared stmt to the closure.
    public func prepare(_ sql: String, body: (OpaquePointer) -> Void) {
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK,
              let statement = statement else { fatalError("Bad SQL: \(sql)") }
        defer { sqlite3_finalize(statement) }
        body(statement)
    }

    // Simple wrappers around BEGIN / COMMIT / ROLLBACK
    public func begin()    { execute("BEGIN;") }
    public func commit()   { execute("COMMIT;") }
    public func rollback() { execute("ROLLBACK;") }
}

// Tiny assertion helper: prints ✅ or 🛑 instead of crashing.
public enum Assert {
    public static func ok(_ condition: @autoclosure () -> Bool, _ msg: String) {
        if condition() {
            print("✅ \(msg)")
        } else {
            print("🛑 \(msg)")
        }
    }
}

// Random “fake” data so we can fill the tables without real game info.
public struct Dummy {
    // Pool of sample game titles
    static let titles   = ["SkyQuest", "Pixel Dungeon", "Cyber Drift",
                           "Mystic Valley", "Robot Rampage", "Star Traders"]
    // Five broad genre categories
    static let genres   = ["Action", "RPG", "Adventure", "Strategy", "Simulation"]
    // Where the game was bought / played
    static let platforms = ["PC", "Switch", "PS5", "Xbox", "Mobile"]

    public static func game(id: Int) -> (Int, String, String, Double) {
        (id,
         titles.randomElement()! + " \(Int.random(in: 1...9))",
         genres.randomElement()!,
         Double(Int.random(in: 10...60)))
    }

    public static func purchase(id: Int, game: Int) -> (Int, Int, String, Date) {
        (id, game,
         platforms.randomElement()!,
         Date(timeIntervalSinceNow: -Double.random(in: 0...86_400*365)))
    }
}

// Simple ASCII bar‑chart for the grouping demo (20 characters max).
public func printBar(label: String, value: Int, max: Int) {
    let width = Int(Double(value) / Double(max) * 20)
    print(label.padding(toLength: 15, withPad: " ", startingAt: 0),
          String(repeating: "█", count: width))
}
