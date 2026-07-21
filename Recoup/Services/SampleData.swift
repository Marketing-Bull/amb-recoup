import Foundation
import SwiftData

/// Sample rows shared by Xcode previews and the Settings "Insert Sample" action.
enum SampleData {
    @MainActor
    static func insert(into context: ModelContext) {
        let acme = Client(name: "Acme Co", hourlyRate: 150, contactName: "Jane Smith", contactEmail: "jane@acme.example")
        let globex = Client(name: "Globex", hourlyRate: 125, contactName: "Hank Scorpio")
        context.insert(acme)
        context.insert(globex)

        let website = Project(name: "Website Redesign", client: acme)
        let adCampaign = Project(name: "Q2 Ad Campaign", client: acme, hourlyRateOverride: 175)
        let audit = Project(name: "SEO Audit", client: globex)
        context.insert(website)
        context.insert(adCampaign)
        context.insert(audit)

        let calendar = Calendar.current
        let today = Date()
        func daysAgo(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: -days, to: today) ?? today
        }

        context.insert(TimeEntry(date: daysAgo(0), hours: 2.5, rate: 150, details: "Homepage wireframes", client: acme, project: website))
        context.insert(TimeEntry(date: daysAgo(1), hours: 1.0, rate: 175, details: "Ad copy review", client: acme, project: adCampaign))
        context.insert(TimeEntry(date: daysAgo(3), hours: 0.5, rate: 125, billable: false, details: "Kickoff call", client: globex, project: audit))

        context.insert(Expense(date: daysAgo(2), amount: 49.99, category: .software, vendor: "Figma", details: "Monthly seat", billable: true, recurring: .monthly, client: acme, project: website))
        context.insert(Expense(date: daysAgo(5), amount: 84.20, category: .meals, vendor: "Bistro 22", details: "Client lunch", client: acme))
        context.insert(Expense(date: daysAgo(8), amount: 300, category: .advertising, vendor: "Meta Ads", billable: true, client: acme, project: adCampaign))

        context.insert(MileageEntry(date: daysAgo(1), startAddress: "Office", endAddress: "Acme HQ", purpose: "Design review", miles: 12.4, roundTrip: true, billable: true, client: acme, project: website))
        context.insert(MileageEntry(date: daysAgo(6), startAddress: "Office", endAddress: "Globex Tower", purpose: "Audit kickoff", miles: 8.1, client: globex, project: audit))
    }
}
