import Foundation
import SwiftData

@Model
final class Project {
    var name: String = ""
    var hourlyRateOverride: Decimal?
    private var statusRaw: String = ProjectStatus.active.rawValue
    var notes: String = ""
    var isArchived: Bool = false
    var createdAt: Date = Date()

    var client: Client?

    @Relationship(deleteRule: .nullify, inverse: \TimeEntry.project)
    var timeEntries: [TimeEntry]?

    @Relationship(deleteRule: .nullify, inverse: \Expense.project)
    var expenses: [Expense]?

    @Relationship(deleteRule: .nullify, inverse: \MileageEntry.project)
    var mileageEntries: [MileageEntry]?

    var status: ProjectStatus {
        get { ProjectStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    init(
        name: String = "",
        client: Client? = nil,
        hourlyRateOverride: Decimal? = nil,
        status: ProjectStatus = .active,
        notes: String = "",
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.client = client
        self.hourlyRateOverride = hourlyRateOverride
        self.statusRaw = status.rawValue
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
