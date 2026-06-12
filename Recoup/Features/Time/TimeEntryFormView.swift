import SwiftUI
import SwiftData

struct TimeEntryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let entry: TimeEntry?

    @State private var date: Date
    @State private var hours: Double
    @State private var rate: Decimal
    @State private var billable: Bool
    @State private var details: String
    @State private var client: Client?
    @State private var project: Project?

    /// Once the user touches the rate, client/project changes stop refreshing it.
    /// Editing an existing entry starts locked — the saved rate is never recomputed.
    @State private var rateManuallySet: Bool
    @State private var didPrefill = false

    @Query private var timeEntries: [TimeEntry]
    @Query private var expenses: [Expense]
    @Query private var mileageEntries: [MileageEntry]

    init(entry: TimeEntry?) {
        self.entry = entry
        _date = State(initialValue: entry?.date ?? Date())
        _hours = State(initialValue: entry?.hours ?? 0)
        _rate = State(initialValue: entry?.rate ?? 0)
        _billable = State(initialValue: entry?.billable ?? true)
        _details = State(initialValue: entry?.details ?? "")
        _client = State(initialValue: entry?.client)
        _project = State(initialValue: entry?.project)
        _rateManuallySet = State(initialValue: entry != nil)
    }

    private var canSave: Bool {
        hours > 0
    }

    private var liveTotal: Decimal {
        Decimal(hours) * rate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    RecentPairChips(client: $client, project: $project)
                    ClientPicker(selection: $client)
                    ProjectPicker(client: client, selection: $project)
                }

                Section("Hours") {
                    HoursPresetPicker(hours: $hours)
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Billable", isOn: $billable)
                }

                Section("Rate") {
                    TextField("Rate", value: $rate, format: .number)
                        .decimalKeyboard()
                    if billable {
                        Text("\(Formatters.currencyString(rate))/hr × \(Formatters.hoursString(hours)) = \(Formatters.currencyString(liveTotal)) — locked on save")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Description") {
                    TextField("What did you work on?", text: $details, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(entry == nil ? "Log Time" : "Edit Time")
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
            .onAppear { prefillIfNeeded() }
            .onChange(of: client) { _, _ in refreshRate() }
            .onChange(of: project) { _, _ in refreshRate() }
            .onChange(of: rate) { _, newRate in
                // A programmatic refresh always lands on the resolved rate;
                // anything else means the user typed a custom rate.
                if newRate != RateResolver.resolvedRate(client: client, project: project) {
                    rateManuallySet = true
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 540)
        #endif
    }

    private func prefillIfNeeded() {
        guard entry == nil, !didPrefill else { return }
        didPrefill = true
        if let pair = Recents.lastUsedPair(timeEntries: timeEntries, expenses: expenses, mileageEntries: mileageEntries) {
            client = pair.client
            project = pair.project
        }
        rate = RateResolver.resolvedRate(client: client, project: project)
    }

    private func refreshRate() {
        guard !rateManuallySet else { return }
        rate = RateResolver.resolvedRate(client: client, project: project)
    }

    private func save() {
        if let entry {
            entry.date = date
            entry.hours = hours
            entry.rate = rate
            entry.billable = billable
            entry.details = details
            entry.client = client
            entry.project = project
        } else {
            context.insert(TimeEntry(
                date: date,
                hours: hours,
                rate: rate,
                billable: billable,
                details: details,
                client: client,
                project: project
            ))
        }
        dismiss()
    }
}
