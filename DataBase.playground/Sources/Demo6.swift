// COMPETENCY 6 – Wraps queries into transactions to ensure data consistency and integrity
//
// DESCRIPTION
//
// A transaction is a unit of work within a database that conducts single or multiple activities, potentially resulting in one or more modifications to the database
// - such as creating, updating, or deleting a record from a table. The primary purpose of transactions is to maintain data integrity and manage database errors.
// Should any errors transpire during the transaction execution, all modifications would be reverted, ensuring the prevention of database corruption.
//
// DEMO 6 — Migration demo — new Purchase table (version 2.0)
// Shows schema migration and use of transactions for reliable updates.

import Foundation
import SQLite3

@MainActor
public func demoMigration() {
    // New table connects to Game via FOREIGN KEY
    GameStoreDatabase.shared.execute("""
        CREATE TABLE IF NOT EXISTS Purchase(
          id       INTEGER PRIMARY KEY,
          gameID   INTEGER NOT NULL,
          platform TEXT    NOT NULL,
          boughtAt DATE    NOT NULL,
          FOREIGN KEY(gameID) REFERENCES Game(id)
        );
        """)
    // Index speeds up JOINs & lookups by gameID
    GameStoreDatabase.shared.execute("CREATE INDEX IF NOT EXISTS idx_purchase_game ON Purchase(gameID);")

    let count = 200
    // Again, bulk‑insert inside a single transaction
    GameStoreDatabase.shared.begin()
    GameStoreDatabase.shared.prepare("INSERT INTO Purchase(id,gameID,platform,boughtAt) VALUES (?,?,?,?)") { statement in
        for id in 1...count {
            let game = Int.random(in: 1...50)
            let (purchaseID, gameID, platform, date) = Dummy.purchase(id: id, game: game)
            sqlite3_bind_int(statement, 1, Int32(purchaseID))
            sqlite3_bind_int(statement, 2, Int32(gameID))
            platform.withCString { sqlite3_bind_text(statement, 3, $0, -1, GameStoreDatabase.transientSQLite) }
            sqlite3_bind_int(statement, 4, Int32(date.timeIntervalSince1970))
            sqlite3_step(statement)
            sqlite3_reset(statement)
        }
    }
    GameStoreDatabase.shared.commit()

    Assert.ok(GameStoreDatabase.shared.scalarInt("SELECT COUNT(*) FROM Purchase") == count,
              "Migration & \(count) purchases ok")
}
