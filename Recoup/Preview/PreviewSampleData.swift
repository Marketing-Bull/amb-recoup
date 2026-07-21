import Foundation
import SwiftData

/// In-memory container with sample rows for Xcode previews.
@MainActor
enum PreviewSampleData {
    static let container: ModelContainer = {
        let schema = Schema([
            Client.self,
            Project.self,
            TimeEntry.self,
            Expense.self,
            MileageEntry.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container: ModelContainer
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create preview container: \(error)")
        }

        SampleData.insert(into: container.mainContext)

        return container
    }()
}
