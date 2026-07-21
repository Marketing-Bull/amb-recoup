import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: MileageRateStore
    @Environment(\.modelContext) private var context

    @State private var showingDeleteConfirmation = false

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Rate per Mile")
                    Spacer()
                    TextField("Rate", value: $settings.mileageRate, format: .number)
                        .decimalKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                Stepper(
                    "\(Formatters.currencyString(settings.mileageRate))/mi",
                    value: $settings.mileageRate,
                    in: 0...5,
                    step: 0.005
                )
                .monospacedDigit()
            } header: {
                Text("Mileage")
            } footer: {
                Text("Applied to all mileage entries for deductible and billable amounts. This setting syncs through iCloud across your devices.")
            }

            Section {
                HStack {
                    Text("Sample Data")
                    Spacer()
                    Button("Insert Sample") {
                        SampleData.insert(into: context)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                Button("Delete All Data", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Insert Sample fills in example clients, projects, time, mileage, and expenses. Delete All Data permanently removes everything and can't be undone.")
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Delete All Data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Everything", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every client, project, time entry, mileage trip, and expense. This can't be undone.")
        }
    }

    private func deleteAllData() {
        try? context.delete(model: TimeEntry.self)
        try? context.delete(model: Expense.self)
        try? context.delete(model: MileageEntry.self)
        try? context.delete(model: Project.self)
        try? context.delete(model: Client.self)
    }
}
