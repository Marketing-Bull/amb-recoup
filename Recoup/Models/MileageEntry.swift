import Foundation
import SwiftData

@Model
final class MileageEntry {
    var date: Date = Date()
    var startAddress: String = ""
    var endAddress: String = ""
    var purpose: String = ""
    var miles: Double = 0
    var roundTrip: Bool = false
    /// Stored at save: miles × 2 when round trip, else miles.
    var totalMiles: Double = 0
    var billable: Bool = false
    var createdAt: Date = Date()

    var client: Client?
    var project: Project?

    init(
        date: Date = Date(),
        startAddress: String = "",
        endAddress: String = "",
        purpose: String = "",
        miles: Double = 0,
        roundTrip: Bool = false,
        billable: Bool = false,
        client: Client? = nil,
        project: Project? = nil,
        createdAt: Date = Date()
    ) {
        self.date = date
        self.startAddress = startAddress
        self.endAddress = endAddress
        self.purpose = purpose
        self.miles = miles
        self.roundTrip = roundTrip
        self.totalMiles = roundTrip ? miles * 2 : miles
        self.billable = billable
        self.client = client
        self.project = project
        self.createdAt = createdAt
    }

    func recalculateTotalMiles() {
        totalMiles = roundTrip ? miles * 2 : miles
    }

    /// Exact copy dated today, not yet inserted into a context.
    func duplicate() -> MileageEntry {
        MileageEntry(
            date: Date(),
            startAddress: startAddress,
            endAddress: endAddress,
            purpose: purpose,
            miles: miles,
            roundTrip: roundTrip,
            billable: billable,
            client: client,
            project: project
        )
    }
}
