import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @State private var filter = EntryFilter(datePreset: .thisMonth)
    @State private var showingNewExpense = false
    @State private var editingExpense: Expense?

    private var expenses: [Expense] {
        allExpenses.filter { filter.matches(date: $0.date, client: $0.client, project: $0.project) }
    }

    private var total: Decimal {
        expenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterBar(filter: $filter)
            HStack {
                Text("Total")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(Formatters.currencyString(total))
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }
            .font(.callout)
            .padding(.horizontal)
            .padding(.vertical, 6)

            if expenses.isEmpty {
                EmptyStateView(
                    title: "No Expenses",
                    systemImage: "creditcard",
                    message: filter.isActive
                        ? "No expenses match the current filters."
                        : "Capture your first expense — amount first, receipt optional.",
                    actionTitle: "Add Expense",
                    action: { showingNewExpense = true }
                )
            } else {
                List {
                    ForEach(expenses) { expense in
                        Button {
                            editingExpense = expense
                        } label: {
                            ExpenseRow(expense: expense)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                context.delete(expense)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Duplicate") {
                                context.insert(expense.duplicate())
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button("Duplicate") {
                                context.insert(expense.duplicate())
                            }
                            Button("Delete", role: .destructive) {
                                context.delete(expense)
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewExpense = true
                } label: {
                    Label("Add Expense", systemImage: "plus")
                }
            }
            ToolbarItem {
                ExportButton(
                    filename: "recoup-expenses.csv",
                    header: CSVExporter.expenseHeader,
                    rows: CSVExporter.expenseRows(expenses)
                )
            }
        }
        .sheet(isPresented: $showingNewExpense) {
            ExpenseFormView(expense: nil)
        }
        .sheet(item: $editingExpense) { expense in
            ExpenseFormView(expense: expense)
        }
    }
}

struct ExpenseRow: View {
    let expense: Expense

    private var title: String {
        expense.vendor.isEmpty ? expense.category.displayName : expense.vendor
    }

    private var subtitle: String {
        var parts: [String] = [expense.category.displayName]
        if let client = expense.client {
            if let project = expense.project {
                parts.append("\(client.name) · \(project.name)")
            } else {
                parts.append(client.name)
            }
        }
        return parts.joined(separator: " — ")
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            thumbnail
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(Formatters.dateString(expense.date))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    if expense.isRecurring, let annualized = expense.annualizedAmount {
                        Text("\(expense.recurring.rawValue) · \(Formatters.currencyString(annualized))/yr")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.purple.opacity(0.12), in: Capsule())
                            .foregroundStyle(.purple)
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.currencyString(expense.amount))
                    .fontWeight(.medium)
                    .monospacedDigit()
                if expense.billable {
                    Text("Billable")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var thumbnail: some View {
        if let data = expense.receiptData, let image = receiptThumbnail(from: data) {
            image
                .resizable()
                .scaledToFill()
                .frame(width: 40, height: 40)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            Image(systemName: expense.category.systemImage)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 40, height: 40)
                .background(Color.gray.opacity(0.12), in: RoundedRectangle(cornerRadius: 8))
        }
    }

    private func receiptThumbnail(from data: Data) -> Image? {
        #if os(iOS)
        guard let uiImage = UIImage(data: data) else { return nil }
        return Image(uiImage: uiImage)
        #else
        guard let nsImage = NSImage(data: data) else { return nil }
        return Image(nsImage: nsImage)
        #endif
    }
}
