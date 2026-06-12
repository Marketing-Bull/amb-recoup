import Foundation

/// A client (+ optional project) combination derived from entry history.
struct ClientProjectPair: Hashable {
    let client: Client
    let project: Project?

    var label: String {
        if let project {
            "\(client.name) · \(project.name)"
        } else {
            client.name
        }
    }
}

/// Last-used and recent values derived entirely from entry history —
/// no extra schema, no stored IDs, survives CloudKit sync.
enum Recents {
    private struct Usage {
        let usedAt: Date
        let client: Client?
        let project: Project?
    }

    private static func usages(
        timeEntries: [TimeEntry],
        expenses: [Expense],
        mileageEntries: [MileageEntry]
    ) -> [Usage] {
        var all: [Usage] = []
        all.append(contentsOf: timeEntries.map { Usage(usedAt: $0.createdAt, client: $0.client, project: $0.project) })
        all.append(contentsOf: expenses.map { Usage(usedAt: $0.createdAt, client: $0.client, project: $0.project) })
        all.append(contentsOf: mileageEntries.map { Usage(usedAt: $0.createdAt, client: $0.client, project: $0.project) })
        return all.sorted { $0.usedAt > $1.usedAt }
    }

    /// Most recently used client/project pair across all entry types.
    static func lastUsedPair(
        timeEntries: [TimeEntry],
        expenses: [Expense],
        mileageEntries: [MileageEntry]
    ) -> ClientProjectPair? {
        recentPairs(timeEntries: timeEntries, expenses: expenses, mileageEntries: mileageEntries, limit: 1).first
    }

    /// Distinct recent client/project pairs, most recent first.
    /// Archived clients are skipped; archived projects fall back to a client-only pair.
    static func recentPairs(
        timeEntries: [TimeEntry],
        expenses: [Expense],
        mileageEntries: [MileageEntry],
        limit: Int = 4
    ) -> [ClientProjectPair] {
        var seen = Set<ClientProjectPair>()
        var result: [ClientProjectPair] = []
        for usage in usages(timeEntries: timeEntries, expenses: expenses, mileageEntries: mileageEntries) {
            guard let client = usage.client, !client.isArchived else { continue }
            let project = (usage.project?.isArchived == false) ? usage.project : nil
            let pair = ClientProjectPair(client: client, project: project)
            if seen.insert(pair).inserted {
                result.append(pair)
            }
            if result.count >= limit { break }
        }
        return result
    }

    static func lastUsedCategory(expenses: [Expense]) -> ExpenseCategory? {
        expenses.max(by: { $0.createdAt < $1.createdAt })?.category
    }

    /// Distinct recent trips (keyed by addresses + round-trip + miles), most recent first.
    static func recentTrips(_ entries: [MileageEntry], limit: Int = 8) -> [MileageEntry] {
        struct TripKey: Hashable {
            let start: String
            let end: String
            let roundTrip: Bool
            let miles: Double
        }
        var seen = Set<TripKey>()
        var result: [MileageEntry] = []
        for entry in entries.sorted(by: { $0.createdAt > $1.createdAt }) {
            let key = TripKey(start: entry.startAddress, end: entry.endAddress, roundTrip: entry.roundTrip, miles: entry.miles)
            if seen.insert(key).inserted {
                result.append(entry)
            }
            if result.count >= limit { break }
        }
        return result
    }
}
