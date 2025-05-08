// COMPETENCY 3 – Orders and groups data from a database using the query language
//
// DESCRIPTION
//
// To streamline operations on the information within the database, the query language offers capabilities to group, order, or sort data based on specific use
// cases. The use of ordering operators enables the fetching of data in either ascending or descending sequence, while grouping serves to streamline the
// consolidation of data with identical values into summarized structures.
//
// DEMO 3 — GROUP BY and ORDER BY demo — count titles per genre
// Demonstrates use of GROUP BY and ORDER BY clauses to organize and sort query results.

import Foundation
import SQLite3

@MainActor
public func demoGroupingOrdering() {
    // GROUP BY genre then ORDER BY the count
    let rows = GameStoreDatabase.shared.query("""
        SELECT genre, COUNT(*) AS titles
        FROM Game
        GROUP BY genre
        ORDER BY titles DESC;
        """)
    let max = rows.map { $0["titles"] as! Int }.max() ?? 1
    rows.forEach { printBar(label: $0["genre"] as! String,
                            value: $0["titles"] as! Int,
                            max: max) }
}
