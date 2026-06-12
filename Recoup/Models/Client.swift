import Foundation
import SwiftData

@Model
final class Client {
    var name: String = ""
    var hourlyRate: Decimal?
    var contactName: String = ""
    var contactEmail: String = ""
    var contactPhone: String = ""
    var notes: String = ""
    var isArchived: Bool = false
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \Project.client)
    var projects: [Project]?

    @Relationship(deleteRule: .nullify, inverse: \TimeEntry.client)
    var timeEntries: [TimeEntry]?

    @Relationship(deleteRule: .nullify, inverse: \Expense.client)
    var expenses: [Expense]?

    @Relationship(deleteRule: .nullify, inverse: \MileageEntry.client)
    var mileageEntries: [MileageEntry]?

    init(
        name: String = "",
        hourlyRate: Decimal? = nil,
        contactName: String = "",
        contactEmail: String = "",
        contactPhone: String = "",
        notes: String = "",
        isArchived: Bool = false,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.hourlyRate = hourlyRate
        self.contactName = contactName
        self.contactEmail = contactEmail
        self.contactPhone = contactPhone
        self.notes = notes
        self.isArchived = isArchived
        self.createdAt = createdAt
    }
}
