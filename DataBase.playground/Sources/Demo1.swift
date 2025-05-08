// COMPETENCY 1 – Creates and modifies database objects
//
// DESCRIPTION
//
// While operating with a database, businesses frequently require modifications to database objects. In the context of SQL databases, statements are primarily
// divided into two key categories: Data Definition Language (DDL) and Data Manipulation Language (DML). DDL statements are employed to construct and
// alter the structure of tables or other objects within a database, whereas DML statements are used to manipulate the data residing in these tables.
//
// DEMO 1 — Create table (version 1.0) and later add a column (version 1.1)
// Demonstrates creation and modification of tables using Data Definition Language (CREATE, ALTER)
// and manipulation of data using Data Manipulation Language.

import Foundation
import SQLite3

@MainActor
public func demoCreateAndAlterTables() {
    GameStoreDatabase.shared.execute("PRAGMA foreign_keys = OFF;") // Temporarily disable foreign‑key checks while dropping tables
    GameStoreDatabase.shared.execute("DROP TABLE IF EXISTS Purchase;")
    GameStoreDatabase.shared.execute("DROP TABLE IF EXISTS Game;")
    GameStoreDatabase.shared.execute("PRAGMA foreign_keys = ON;")  // Re‑enable foreign‑key enforcement

    GameStoreDatabase.shared.execute("""
        -- v1.0
        CREATE TABLE Game(
          id      INTEGER PRIMARY KEY,
          title   TEXT    NOT NULL,
          genre   TEXT    NOT NULL,
          price   REAL    NOT NULL
        );
        """)
    // Add releaseDate in schema v1.1
    GameStoreDatabase.shared.execute("ALTER TABLE Game ADD COLUMN releaseDate DATE; -- v1.1")

    Assert.ok(GameStoreDatabase.shared.columnExists(table: "Game", column: "releaseDate"),
              "Data Definition Language: CREATE + ALTER")
}
