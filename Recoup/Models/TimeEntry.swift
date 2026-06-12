import Foundation
import SwiftData

@Model
final class TimeEntry {
    var date: Date = Date()
    var hours: Double = 0
    /// Resolved once at save (entry → project → client) and locked; never recomputed.
    var rate: Decimal = 0
    var billable: Bool = true
    var details: String = ""
    var createdAt: Date = Date()

    var client: Client?
    var project: Project?

    var total: Decimal { Decimal(hours) * rate }

    init(
        date: Date = Date(),
        hours: Double = 0,
        rate: Decimal = 0,
        billable: Bool = true,
        details: String = "",
        client: Client? = nil,
        project: Project? = nil,
        createdAt: Date = Date()
    ) {
        self.date = date
        self.hours = hours
        self.rate = rate
        self.billable = billable
        self.details = details
        self.client = client
        self.project = project
        self.createdAt = createdAt
    }

    /// Exact copy dated today, not yet inserted into a context.
    func duplicate() -> TimeEntry {
        TimeEntry(
            date: Date(),
            hours: hours,
            rate: rate,
            billable: billable,
            details: details,
            client: client,
            project: project
        )
    }
}
