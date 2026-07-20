import SwiftUI
import SwiftData

@main
struct RecoupApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([
            Client.self,
            Project.self,
            TimeEntry.self,
            Expense.self,
            MileageEntry.self,
        ])
        do {
            let cloudConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // Do not silently open a separate local-only configuration here. A
            // fallback store can make successful edits appear to sync while they
            // are actually stranded on one device. The automatic configuration
            // already supports offline use and uploads when iCloud is available.
            fatalError("Could not create the CloudKit-backed ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
