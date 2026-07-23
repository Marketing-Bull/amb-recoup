import SwiftUI
import SwiftData

struct SettingsView: View {
    @EnvironmentObject private var settings: MileageRateStore
    @Environment(\.modelContext) private var context

    @Query(sort: \Client.name) private var allClients: [Client]
    @Query(sort: \Project.name) private var allProjects: [Project]
    @Query(sort: \TimeEntry.date, order: .reverse) private var allTimeEntries: [TimeEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \MileageEntry.date, order: .reverse) private var allMileageEntries: [MileageEntry]

    @State private var showingDeleteConfirmation = false
    @State private var deleteErrorMessage: String?

    /// Same header/row builders the per-list Export CSV buttons use, so a client, time,
    /// mileage, or expense CSV reads identically whether exported from here or from its
    /// own list — this just covers every record instead of the list's current filter.
    private var csvExportFiles: [CSVFile] {
        let suffix = Formatters.csvDateString(Date())
        return [
            CSVFile(filename: "recoup-clients-\(suffix).csv", header: CSVExporter.clientHeader, rows: CSVExporter.clientRows(allClients)),
            CSVFile(filename: "recoup-projects-\(suffix).csv", header: CSVExporter.projectHeader, rows: CSVExporter.projectRows(allProjects)),
            CSVFile(filename: "recoup-time-\(suffix).csv", header: CSVExporter.timeHeader, rows: CSVExporter.timeRows(allTimeEntries)),
            CSVFile(filename: "recoup-expenses-\(suffix).csv", header: CSVExporter.expenseHeader, rows: CSVExporter.expenseRows(allExpenses)),
            CSVFile(filename: "recoup-mileage-\(suffix).csv", header: CSVExporter.mileageHeader, rows: CSVExporter.mileageRows(allMileageEntries, rate: settings.mileageRate)),
        ]
    }

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
                Button {
                    SampleData.insert(into: context)
                    try? context.save()
                } label: {
                    Label("Import Sample Data", systemImage: "square.and.arrow.down")
                }

                ShareLink(items: csvExportFiles) { file in
                    // Filename is dynamic (model + date), not a localization key;
                    // wrap in LocalizedStringResource so SwiftUI renders it verbatim.
                    SharePreview(LocalizedStringResource(stringLiteral: file.filename), image: Image(systemName: "tablecells"))
                } label: {
                    Label("Export to CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(csvExportFiles.allSatisfy { $0.rows.isEmpty })

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Reset Data", systemImage: "trash")
                }
            } header: {
                Text("Data")
            } footer: {
                Text("Import Sample Data fills in example clients, projects, time, mileage, and expenses. Export to CSV shares a backup of everything as separate spreadsheets. Reset Data permanently removes everything and can't be undone.")
            }
        }
        .formStyle(.grouped)
        .confirmationDialog(
            "Reset Data?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset Data", role: .destructive) {
                deleteAllData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes every client, project, time entry, mileage trip, and expense. This can't be undone.")
        }
        .alert(
            "Couldn't Reset Data",
            isPresented: Binding(
                get: { deleteErrorMessage != nil },
                set: { if !$0 { deleteErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(deleteErrorMessage ?? "")
        }
    }

    /// Stops at the first failure and skips the final save, so a partial
    /// failure never persists a half-deleted database — either everything
    /// is removed, or nothing is.
    private func deleteAllData() {
        do {
            try context.delete(model: TimeEntry.self)
            try context.delete(model: Expense.self)
            try context.delete(model: MileageEntry.self)
            try context.delete(model: Project.self)
            try context.delete(model: Client.self)
            try context.save()
        } catch {
            deleteErrorMessage = error.localizedDescription
        }
    }
}
