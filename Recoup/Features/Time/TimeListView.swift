import SwiftUI
import SwiftData

struct TimeListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \TimeEntry.date, order: .reverse) private var allEntries: [TimeEntry]
    @State private var filter = EntryFilter()
    @State private var showingNewEntry = false
    @State private var editingEntry: TimeEntry?

    private var entries: [TimeEntry] {
        allEntries.filter { filter.matches(date: $0.date, client: $0.client, project: $0.project) }
    }

    private var totalHours: Double {
        entries.reduce(0) { $0 + $1.hours }
    }

    private var billableTotal: Decimal {
        entries.filter(\.billable).reduce(Decimal(0)) { $0 + $1.total }
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterBar(filter: $filter)
            if entries.isEmpty {
                EmptyStateView(
                    title: "No Time Entries",
                    systemImage: "clock",
                    message: filter.isActive
                        ? "No entries match the current filters."
                        : "Log your first hours — the rate is locked in when you save.",
                    actionTitle: "Log Time",
                    action: { showingNewEntry = true }
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            TimeEntryRow(entry: entry)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button("Delete", role: .destructive) {
                                context.delete(entry)
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button("Duplicate") {
                                context.insert(entry.duplicate())
                            }
                            .tint(.blue)
                        }
                        .contextMenu {
                            Button("Duplicate") {
                                context.insert(entry.duplicate())
                            }
                            Button("Delete", role: .destructive) {
                                context.delete(entry)
                            }
                        }
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if !entries.isEmpty {
                HStack {
                    Text("\(entries.count) \(entries.count == 1 ? "entry" : "entries")")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Formatters.hoursString(totalHours))
                        .fontWeight(.medium)
                        .monospacedDigit()
                    Text("·")
                        .foregroundStyle(.secondary)
                    Text("\(Formatters.currencyString(billableTotal)) billable")
                        .fontWeight(.medium)
                        .monospacedDigit()
                }
                .font(.callout)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(.bar)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewEntry = true
                } label: {
                    Label("Log Time", systemImage: "plus")
                }
            }
            ToolbarItem {
                ExportButton(
                    filename: "recoup-time.csv",
                    header: CSVExporter.timeHeader,
                    rows: CSVExporter.timeRows(entries)
                )
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            TimeEntryFormView(entry: nil)
        }
        .sheet(item: $editingEntry) { entry in
            TimeEntryFormView(entry: entry)
        }
    }
}

struct TimeEntryRow: View {
    let entry: TimeEntry

    private var pairLabel: String {
        let clientName = entry.client?.name ?? "No client"
        if let project = entry.project {
            return "\(clientName) · \(project.name)"
        }
        return clientName
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(pairLabel)
                    .fontWeight(.medium)
                    .lineLimit(1)
                if !entry.details.isEmpty {
                    Text(entry.details)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Text(Formatters.dateString(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.hoursString(entry.hours))
                    .fontWeight(.medium)
                    .monospacedDigit()
                if entry.billable {
                    Text(Formatters.currencyString(entry.total))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                } else {
                    Text("Non-billable")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contentShape(Rectangle())
    }
}
