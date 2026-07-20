import SwiftUI
import SwiftData

struct MileageListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \MileageEntry.date, order: .reverse) private var allEntries: [MileageEntry]
    @EnvironmentObject private var settings: MileageRateStore

    private var mileageRate: Double { settings.mileageRate }
    @State private var filter = EntryFilter()
    @State private var showingNewEntry = false
    @State private var editingEntry: MileageEntry?

    private var entries: [MileageEntry] {
        allEntries.filter { filter.matches(date: $0.date, client: $0.client, project: $0.project) }
    }

    private var totalMiles: Double {
        entries.reduce(0) { $0 + $1.totalMiles }
    }

    private var billableMiles: Double {
        entries.filter(\.billable).reduce(0) { $0 + $1.totalMiles }
    }

    var body: some View {
        VStack(spacing: 0) {
            FilterBar(filter: $filter)
            statsBar
            if entries.isEmpty {
                EmptyStateView(
                    title: "No Trips",
                    systemImage: "car",
                    message: filter.isActive
                        ? "No trips match the current filters."
                        : "Log your first trip — repeat it later with one tap.",
                    actionTitle: "Log Trip",
                    action: { showingNewEntry = true }
                )
            } else {
                List {
                    ForEach(entries) { entry in
                        Button {
                            editingEntry = entry
                        } label: {
                            MileageRow(entry: entry, rate: mileageRate)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewEntry = true
                } label: {
                    Label("Log Trip", systemImage: "plus")
                }
            }
            ToolbarItem {
                ExportButton(
                    filename: "recoup-mileage.csv",
                    header: CSVExporter.mileageHeader,
                    rows: CSVExporter.mileageRows(entries, rate: mileageRate)
                )
            }
        }
        .sheet(isPresented: $showingNewEntry) {
            MileageFormView(entry: nil)
        }
        .sheet(item: $editingEntry) { entry in
            MileageFormView(entry: entry)
        }
    }

    private var statsBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                StatCard(title: "Trips", value: "\(entries.count)", systemImage: "car")
                    .frame(width: 130)
                StatCard(title: "Total Miles", value: Formatters.milesString(totalMiles), systemImage: "road.lanes")
                    .frame(width: 130)
                StatCard(title: "Deductible", value: Formatters.currencyString(totalMiles * mileageRate), systemImage: "percent")
                    .frame(width: 130)
                StatCard(title: "Billable", value: Formatters.currencyString(billableMiles * mileageRate), systemImage: "dollarsign.circle")
                    .frame(width: 130)
            }
            .padding(.horizontal)
            .padding(.bottom, 6)
        }
    }
}

struct MileageRow: View {
    let entry: MileageEntry
    let rate: Double

    private var route: String {
        let parts = [entry.startAddress, entry.endAddress].filter { !$0.isEmpty }
        return parts.isEmpty ? "Unnamed trip" : parts.joined(separator: " → ")
    }

    private var subtitle: String {
        var parts: [String] = []
        if !entry.purpose.isEmpty { parts.append(entry.purpose) }
        if let client = entry.client {
            if let project = entry.project {
                parts.append("\(client.name) · \(project.name)")
            } else {
                parts.append(client.name)
            }
        }
        return parts.joined(separator: " — ")
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(route)
                        .fontWeight(.medium)
                        .lineLimit(1)
                    if entry.roundTrip {
                        Text("RT")
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(Formatters.dateString(entry.date))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(Formatters.milesString(entry.totalMiles))
                    .fontWeight(.medium)
                    .monospacedDigit()
                Text(Formatters.currencyString(entry.totalMiles * rate))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .contentShape(Rectangle())
    }
}
