import SwiftUI
import SwiftData

struct ClientFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let client: Client?

    @State private var name: String
    @State private var hourlyRate: Decimal?
    @State private var contactName: String
    @State private var contactEmail: String
    @State private var contactPhone: String
    @State private var notes: String

    init(client: Client?) {
        self.client = client
        _name = State(initialValue: client?.name ?? "")
        _hourlyRate = State(initialValue: client?.hourlyRate)
        _contactName = State(initialValue: client?.contactName ?? "")
        _contactEmail = State(initialValue: client?.contactEmail ?? "")
        _contactPhone = State(initialValue: client?.contactPhone ?? "")
        _notes = State(initialValue: client?.notes ?? "")
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Client") {
                    TextField("Name", text: $name)
                    TextField("Hourly Rate", value: $hourlyRate, format: .number, prompt: Text("Hourly rate (optional)"))
                        .decimalKeyboard()
                }
                Section("Contact") {
                    TextField("Contact Name", text: $contactName)
                    TextField("Email", text: $contactEmail)
                        .emailField()
                    TextField("Phone", text: $contactPhone)
                }
                Section("Notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(client == nil ? "New Client" : "Edit Client")
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
        .frame(minWidth: 440, minHeight: 480)
        #endif
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let client {
            client.name = trimmedName
            client.hourlyRate = hourlyRate
            client.contactName = contactName
            client.contactEmail = contactEmail
            client.contactPhone = contactPhone
            client.notes = notes
        } else {
            context.insert(Client(
                name: trimmedName,
                hourlyRate: hourlyRate,
                contactName: contactName,
                contactEmail: contactEmail,
                contactPhone: contactPhone,
                notes: notes
            ))
        }
        dismiss()
    }
}
