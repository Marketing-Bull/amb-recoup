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
            // iCloud unavailable (no account, no entitlement, signing disabled) —
            // fall back to a local-only store so the app always launches.
            do {
                let localConfig = ModelConfiguration(schema: schema, cloudKitDatabase: .none)
                container = try ModelContainer(for: schema, configurations: [localConfig])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(container)
    }
}
