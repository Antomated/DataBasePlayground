// COMPETENCY 2 – Generates dummy database data for testing and development purposes
//
// DESCRIPTION
//
// Setting up an effective staging environment necessitates data similar to that of the production environment. This task can be challenging if the necessary
// data hasn't been collected yet or if it's too sensitive to use. Therefore, the generation of dummy data for development and testing becomes crucial. The
// automation of this dummy data creation not only boosts the quality of the product but also improves the efficiency of the entire development process.
//
// DEMO 2 — Insert 50 random games (Data Manipulation Language)
// Shows how to populate tables with random or simulated data using Data Manipulation Language

import Foundation
import SQLite3

@MainActor
public func demoDummyData() {
    let count = 50
    // One transaction is faster than 50 autocommits
    GameStoreDatabase.shared.begin()
    GameStoreDatabase.shared.prepare("INSERT INTO Game(id,title,genre,price) VALUES (?,?,?,?)") { statement in
        for id in 1...count {
            let (gameID, title, genre, price) = Dummy.game(id: id)
            sqlite3_bind_int(statement, 1, Int32(gameID))
            title.withCString { sqlite3_bind_text(statement, 2, $0, -1, GameStoreDatabase.transientSQLite) }
            genre.withCString { sqlite3_bind_text(statement, 3, $0, -1, GameStoreDatabase.transientSQLite) }
            sqlite3_bind_double(statement, 4, price)
            sqlite3_step(statement)
            sqlite3_reset(statement)
        }
    }
    GameStoreDatabase.shared.commit()
    Assert.ok(GameStoreDatabase.shared.scalarInt("SELECT COUNT(*) FROM Game") == count,
              "Inserted \(count) dummy games")
}


// DEMO 2b — Fill the new releaseDate column with random past dates
@MainActor
public func demoReleaseDates() {
    // UPDATE each row with a different past date
    GameStoreDatabase.shared.begin()
    for id in 1...50 {
        let daysAgo = Int.random(in: 100...2000)
        GameStoreDatabase.shared.execute("UPDATE Game SET releaseDate = date('now', '-\(daysAgo) days') WHERE id = \(id);")
    }
    GameStoreDatabase.shared.commit()

    // Quick sanity check
    if let span = GameStoreDatabase.shared.query("SELECT MIN(releaseDate) AS oldest, MAX(releaseDate) AS newest FROM Game;").first {
        print("Release dates between \(span["oldest"] ?? "?") and \(span["newest"] ?? "?")")
    }
}
