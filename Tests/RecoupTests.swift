import XCTest
@testable import Recoup

final class RecoupTests: XCTestCase {
    func testRateResolutionPrefersProjectOverride() {
        let client = Client(name: "Client", hourlyRate: 100)
        let project = Project(name: "Project", client: client, hourlyRateOverride: 150)

        XCTAssertEqual(RateResolver.resolvedRate(client: client, project: project), 150)
        XCTAssertEqual(RateResolver.resolvedRate(client: client, project: nil), 100)
        XCTAssertEqual(RateResolver.resolvedRate(client: nil, project: nil), 0)
    }

    func testMileageCalculatesAndRecalculatesRoundTripTotal() {
        let entry = MileageEntry(miles: 12.5, roundTrip: true)
        XCTAssertEqual(entry.totalMiles, 25)

        entry.roundTrip = false
        entry.recalculateTotalMiles()
        XCTAssertEqual(entry.totalMiles, 12.5)
    }

    func testRecurringExpenseAnnualizesAmount() {
        XCTAssertEqual(
            Expense(amount: 10, recurring: .weekly).annualizedAmount,
            520
        )
        XCTAssertEqual(
            Expense(amount: 10, recurring: .monthly).annualizedAmount,
            120
        )
        XCTAssertNil(Expense(amount: 10).annualizedAmount)
    }

    func testCSVExporterEscapesSpecialCharacters() {
        let csv = CSVExporter.makeCSV(
            header: ["name", "notes"],
            rows: [["Acme, Inc.", "Said \"hello\"\nagain"]]
        )

        XCTAssertEqual(csv, "name,notes\r\n\"Acme, Inc.\",\"Said \"\"hello\"\"\nagain\"")
    }

    @MainActor
    func testMileageRateNormalizationRejectsInvalidValues() {
        XCTAssertEqual(MileageRateStore.normalized(-1), 0)
        XCTAssertEqual(MileageRateStore.normalized(9), 5)
        XCTAssertEqual(MileageRateStore.normalized(.infinity), AppSettings.defaultMileageRate)
        XCTAssertEqual(MileageRateStore.normalized(.nan), AppSettings.defaultMileageRate)
        XCTAssertEqual(MileageRateStore.normalized(0.7), 0.7)
    }
}
