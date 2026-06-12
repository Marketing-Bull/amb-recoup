import SwiftUI
import SwiftData

struct ExpenseFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let expense: Expense?

    @State private var date: Date
    @State private var amount: Decimal?
    @State private var category: ExpenseCategory
    @State private var vendor: String
    @State private var details: String
    @State private var billable: Bool
    @State private var recurring: RecurringType
    @State private var receiptData: Data?
    @State private var client: Client?
    @State private var project: Project?
    @State private var didPrefill = false

    @FocusState private var amountFocused: Bool

    @Query private var timeEntries: [TimeEntry]
    @Query private var expenses: [Expense]
    @Query private var mileageEntries: [MileageEntry]

    init(expense: Expense?) {
        self.expense = expense
        _date = State(initialValue: expense?.date ?? Date())
        _amount = State(initialValue: expense.map(\.amount))
        _category = State(initialValue: expense?.category ?? .other)
        _vendor = State(initialValue: expense?.vendor ?? "")
        _details = State(initialValue: expense?.details ?? "")
        _billable = State(initialValue: expense?.billable ?? false)
        _recurring = State(initialValue: expense?.recurring ?? .none)
        _receiptData = State(initialValue: expense?.receiptData)
        _client = State(initialValue: expense?.client)
        _project = State(initialValue: expense?.project)
    }

    private var canSave: Bool {
        (amount ?? 0) > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Amount") {
                    TextField("Amount", value: $amount, format: .number, prompt: Text("0.00"))
                        .decimalKeyboard()
                        .focused($amountFocused)
                        .font(.title3.weight(.semibold))
                        .monospacedDigit()
                }

                Section("Category") {
                    CategoryGrid(selection: $category)
                }

                Section {
                    TextField("Vendor", text: $vendor)
                    TextField("Description", text: $details, axis: .vertical)
                        .lineLimit(2...4)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }

                Section {
                    RecentPairChips(client: $client, project: $project)
                    ClientPicker(selection: $client)
                    ProjectPicker(client: client, selection: $project)
                }

                Section {
                    Toggle("Billable", isOn: $billable)
                    Picker("Recurring", selection: $recurring) {
                        ForEach(RecurringType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    if recurring != .none, let amount, amount > 0,
                       let multiplier = recurring.annualMultiplier {
                        Text("≈ \(Formatters.currencyString(amount * multiplier))/yr")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }

                Section("Receipt") {
                    ReceiptPicker(receiptData: $receiptData)
                }
            }
            .formStyle(.grouped)
            .navigationTitle(expense == nil ? "New Expense" : "Edit Expense")
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
        .frame(minWidth: 480, minHeight: 620)
        #endif
    }

    private func prefillIfNeeded() {
        guard expense == nil, !didPrefill else { return }
        didPrefill = true
        if let pair = Recents.lastUsedPair(timeEntries: timeEntries, expenses: expenses, mileageEntries: mileageEntries) {
            client = pair.client
            project = pair.project
        }
        if let lastCategory = Recents.lastUsedCategory(expenses: expenses) {
            category = lastCategory
        }
        amountFocused = true
    }

    private func save() {
        let amountValue = amount ?? 0
        if let expense {
            expense.date = date
            expense.amount = amountValue
            expense.category = category
            expense.vendor = vendor
            expense.details = details
            expense.billable = billable
            expense.recurring = recurring
            expense.receiptData = receiptData
            expense.client = client
            expense.project = project
        } else {
            context.insert(Expense(
                date: date,
                amount: amountValue,
                category: category,
                vendor: vendor,
                details: details,
                billable: billable,
                recurring: recurring,
                receiptData: receiptData,
                client: client,
                project: project
            ))
        }
        dismiss()
    }
}
