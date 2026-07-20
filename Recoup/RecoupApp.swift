import SwiftUI
import SwiftData

@main
struct RecoupApp: App {
    @StateObject private var persistence = PersistenceController()
    @StateObject private var settings = MileageRateStore()

    var body: some Scene {
        WindowGroup {
            if let container = persistence.container {
                RootView()
                    .modelContainer(container)
                    .environmentObject(settings)
            } else {
                PersistenceErrorView(
                    message: persistence.errorMessage,
                    retry: persistence.load
                )
            }
        }
    }
}

@MainActor
final class PersistenceController: ObservableObject {
    @Published private(set) var container: ModelContainer?
    @Published private(set) var errorMessage: String?

    init() {
        load()
    }

    func load() {
        errorMessage = nil
        do {
            let schema = Schema([
                Client.self,
                Project.self,
                TimeEntry.self,
                Expense.self,
                MileageEntry.self,
            ])
            let configuration = ModelConfiguration(schema: schema, cloudKitDatabase: .automatic)
            container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            // Never substitute a different local store: that would allow edits
            // which look successful but cannot reach the user's other devices.
            container = nil
            errorMessage = error.localizedDescription
        }
    }
}

private struct PersistenceErrorView: View {
    let message: String?
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Unable to Open Recoup", systemImage: "icloud.slash")
        } description: {
            Text("Recoup couldn't open its synchronized database. Check iCloud and your network connection, then try again.")
            if let message {
                Text(message)
                    .font(.caption)
                    .textSelection(.enabled)
            }
        } actions: {
            Button("Try Again", action: retry)
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}
