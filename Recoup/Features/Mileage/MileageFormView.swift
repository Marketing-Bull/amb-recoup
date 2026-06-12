import SwiftUI
import SwiftData

struct MileageFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(AppSettings.mileageRateKey) private var mileageRate = AppSettings.defaultMileageRate

    let entry: MileageEntry?

    @State private var date: Date
    @State private var startAddress: String
    @State private var endAddress: String
    @State private var purpose: String
    @State private var miles: Double?
    @State private var roundTrip: Bool
    @State private var billable: Bool
    @State private var client: Client?
    @State private var project: Project?
    @State private var didPrefill = false

    @Query private var timeEntries: [TimeEntry]
    @Query private var expenses: [Expense]
    @Query private var mileageEntries: [MileageEntry]

    init(entry: MileageEntry?) {
        self.entry = entry
        _date = State(initialValue: entry?.date ?? Date())
        _startAddress = State(initialValue: entry?.startAddress ?? "")
        _endAddress = State(initialValue: entry?.endAddress ?? "")
        _purpose = State(initialValue: entry?.purpose ?? "")
        _miles = State(initialValue: entry.map(\.miles))
        _roundTrip = State(initialValue: entry?.roundTrip ?? false)
        _billable = State(initialValue: entry?.billable ?? false)
        _client = State(initialValue: entry?.client)
        _project = State(initialValue: entry?.project)
    }

    private var totalMiles: Double {
        let base = miles ?? 0
        return roundTrip ? base * 2 : base
    }

    /// Billable mileage requires a client.
    private var canSave: Bool {
        (miles ?? 0) > 0 && (!billable || client != nil)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    RecentTripPicker { trip in
                        startAddress = trip.startAddress
                        endAddress = trip.endAddress
                        purpose = trip.purpose
                        miles = trip.miles
                        roundTrip = trip.roundTrip
                        client = trip.client
                        project = trip.project
                    }
                    RecentPairChips(client: $client, project: $project)
                    ClientPicker(selection: $client)
                    ProjectPicker(client: client, selection: $project)
                }

                Section("Trip") {
                    TextField("Start Address", text: $startAddress)
                    TextField("End Address", text: $endAddress)
                    TextField("Purpose", text: $purpose)
                }

                Section {
                    TextField("Miles", value: $miles, format: .number, prompt: Text("Miles (one way)"))
                        .decimalKeyboard()
                    Toggle("Round Trip", isOn: $roundTrip)
                    Text("\(Formatters.milesString(totalMiles)) ≈ \(Formatters.currencyString(totalMiles * mileageRate)) @ \(Formatters.currencyString(mileageRate))/mi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    Toggle("Billable", isOn: $billable)
                } footer: {
                    if billable && client == nil {
                        Text("Billable mileage needs a client.")
                            .foregroundStyle(.orange)
                    }
                }
            }
            .formStyle(.grouped)
            .navigationTitle(entry == nil ? "Log Trip" : "Edit Trip")
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
        }
        #if os(macOS)
        .frame(minWidth: 460, minHeight: 560)
        #endif
    }

    private func prefillIfNeeded() {
        guard entry == nil, !didPrefill else { return }
        didPrefill = true
        if let pair = Recents.lastUsedPair(timeEntries: timeEntries, expenses: expenses, mileageEntries: mileageEntries) {
            client = pair.client
            project = pair.project
        }
    }

    private func save() {
        let milesValue = miles ?? 0
        if let entry {
            entry.date = date
            entry.startAddress = startAddress
            entry.endAddress = endAddress
            entry.purpose = purpose
            entry.miles = milesValue
            entry.roundTrip = roundTrip
            entry.billable = billable
            entry.client = client
            entry.project = project
            entry.recalculateTotalMiles()
        } else {
            context.insert(MileageEntry(
                date: date,
                startAddress: startAddress,
                endAddress: endAddress,
                purpose: purpose,
                miles: milesValue,
                roundTrip: roundTrip,
                billable: billable,
                client: client,
                project: project
            ))
        }
        dismiss()
    }
}
