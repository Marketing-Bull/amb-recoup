import SwiftUI
import SwiftData

struct ProjectFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let project: Project?

    @State private var name: String
    @State private var client: Client?
    @State private var hourlyRateOverride: Decimal?
    @State private var status: ProjectStatus
    @State private var notes: String

    init(project: Project?) {
        self.project = project
        _name = State(initialValue: project?.name ?? "")
        _client = State(initialValue: project?.client)
        _hourlyRateOverride = State(initialValue: project?.hourlyRateOverride)
        _status = State(initialValue: project?.status ?? .active)
        _notes = State(initialValue: project?.notes ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Project") {
                    TextField("Name", text: $name)
                    ClientPicker(selection: $client)
                    TextField("Rate Override", value: $hourlyRateOverride, format: .number, prompt: Text("Uses client rate when empty"))
                        .decimalKeyboard()
                }
                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ProjectStatus.allCases) { status in
                            Text(status.rawValue).tag(status)
                        }
                    }
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(project == nil ? "New Project" : "Edit Project")
            .inlineNavigationTitle()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 440, minHeight: 420)
        #endif
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let project {
            project.name = trimmedName
            project.client = client
            project.hourlyRateOverride = hourlyRateOverride
            project.status = status
            project.notes = notes
        } else {
            context.insert(Project(
                name: trimmedName,
                client: client,
                hourlyRateOverride: hourlyRateOverride,
                status: status,
                notes: notes
            ))
        }
        dismiss()
    }
}
