// COMPETENCY 4 – Uses database data aggregation techniques to optimise data analysis
//
// DESCRIPTION
//
// The aggregation function is critical in facilitating and improving certain database operations. Often used alongside other queries, aggregation is key to
// producing efficient outcomes. For example, it might be employed during data grouping processes to create reports expediently or derive insights from the
// database in the most optimal way.
//
// DEMO 4 — Aggregation demo — MIN, MAX and AVG prices per genre
// Shows use of SQL aggregation functions such as MIN, MAX, and AVG for summarizing data. */

import Foundation
import SQLite3

@MainActor
public func demoAggregation() {
    // One query gives count, min, max, avg price
    let rows = GameStoreDatabase.shared.query("""
        SELECT genre,
               COUNT(*)            AS titles,
               MIN(price)          AS cheap,
               MAX(price)          AS pricey,
               ROUND(AVG(price),1) AS avg
        FROM Game
        GROUP BY genre
        ORDER BY avg DESC;
        """)
    Assert.ok(!rows.isEmpty, "Aggregation succeeded")
    rows.forEach { print($0) }
}
