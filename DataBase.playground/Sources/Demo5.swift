// COMPETENCY 5 – Implements and modifies database structure
// DESCRIPTION
//
// Database architecture is a crucial phase preceding the actual creation of a database. This step involves the design and planning of how various database
// components will interrelate. A well-constructed database should uphold data precision and integrity, optimize space utilization by eliminating redundant
// data, and ensure secure access to the data. For enhanced visual representation of a database, its structure, and relationships, developers often utilize
// schema diagrams and corresponding generation tools.
//
// DEMO 5 — Transaction demo — show automatic rollback on error
// Demonstrates structural changes and error handling using transactions.

import Foundation
import SQLite3

@MainActor
public func demoTransactions() {
    // Take snapshot of total before risky work
    let before = GameStoreDatabase.shared.scalarInt("SELECT ROUND(SUM(price)) FROM Game")
    GameStoreDatabase.shared.begin()
    GameStoreDatabase.shared.execute("UPDATE Game SET price = price * 1.10;")               // +10 %
    // Deliberately violate NOT NULL to trigger error
    GameStoreDatabase.shared.executeAllowingError("UPDATE Game SET title = NULL WHERE id = 1;") // violate NOT NULL
    GameStoreDatabase.shared.rollback()
    let after = GameStoreDatabase.shared.scalarInt("SELECT ROUND(SUM(price)) FROM Game")
    Assert.ok(before == after, "Rollback preserved totals")
}
