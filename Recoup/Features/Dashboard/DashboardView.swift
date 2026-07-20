import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query(sort: \TimeEntry.date, order: .reverse) private var allTimeEntries: [TimeEntry]
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query(sort: \MileageEntry.date, order: .reverse) private var allMileageEntries: [MileageEntry]
    @Query(sort: \Client.name) private var allClients: [Client]
    @Query(sort: \Project.name) private var allProjects: [Project]
    @StateObject private var settings = MileageRateStore()

    private var mileageRate: Double { settings.mileageRate }

    @State private var preset: DateRangePreset = .thisMonth
    @State private var groupByProject = false
    #if os(iOS)
    @State private var showingSettings = false
    #endif

    // MARK: - Filtered entries

    private var timeEntries: [TimeEntry] {
        allTimeEntries.filter { preset.contains($0.date) }
    }

    private var expenses: [Expense] {
        allExpenses.filter { preset.contains($0.date) }
    }

    private var mileageEntries: [MileageEntry] {
        allMileageEntries.filter { preset.contains($0.date) }
    }

    private var hasAnyData: Bool {
        !allTimeEntries.isEmpty || !allExpenses.isEmpty || !allMileageEntries.isEmpty
    }

    // MARK: - Card totals

    private var billableTimeValue: Decimal {
        timeEntries.filter(\.billable).reduce(Decimal(0)) { $0 + $1.total }
    }

    private var totalHours: Double {
        timeEntries.reduce(0) { $0 + $1.hours }
    }

    private var unbilledHours: Double {
        timeEntries.filter { !$0.billable }.reduce(0) { $0 + $1.hours }
    }

    private var totalMiles: Double {
        mileageEntries.reduce(0) { $0 + $1.totalMiles }
    }

    private var expenseTotal: Decimal {
        expenses.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private var billableExpenses: Decimal {
        expenses.filter(\.billable).reduce(Decimal(0)) { $0 + $1.amount }
    }

    var body: some View {
        Group {
            if hasAnyData {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Date Range", selection: $preset) {
                            ForEach(DateRangePreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.segmented)
                        .labelsHidden()

                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            StatCard(
                                title: "Billable Time",
                                value: Formatters.currencyString(billableTimeValue),
                                systemImage: "clock"
                            )
                            StatCard(
                                title: "Hours",
                                value: Formatters.hoursString(totalHours),
                                subtitle: unbilledHours > 0 ? "\(Formatters.hoursString(unbilledHours)) non-billable" : nil,
                                systemImage: "hourglass"
                            )
                            StatCard(
                                title: "Mileage Value",
                                value: Formatters.currencyString(totalMiles * mileageRate),
                                subtitle: "@ \(Formatters.currencyString(mileageRate))/mi",
                                systemImage: "car"
                            )
                            StatCard(
                                title: "Total Miles",
                                value: Formatters.milesString(totalMiles),
                                systemImage: "road.lanes"
                            )
                            StatCard(
                                title: "Expenses",
                                value: Formatters.currencyString(expenseTotal),
                                systemImage: "creditcard"
                            )
                            StatCard(
                                title: "Billable Expenses",
                                value: Formatters.currencyString(billableExpenses),
                                systemImage: "dollarsign.circle"
                            )
                        }

                        breakdownSection
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    title: "Nothing Tracked Yet",
                    systemImage: "chart.bar",
                    message: "Add a client, then log time, trips, and expenses — totals show up here."
                )
            }
        }
        #if os(iOS)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            NavigationStack {
                SettingsView()
                    .navigationTitle("Settings")
                    .inlineNavigationTitle()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingSettings = false }
                        }
                    }
            }
        }
        #endif
    }

    // MARK: - Breakdown

    private struct BreakdownRow: Identifiable {
        let id: String
        let name: String
        let timeValue: Decimal
        let mileageValue: Double
        let expenseValue: Decimal

        var combined: Decimal {
            timeValue + Decimal(mileageValue) + expenseValue
        }

        var isEmpty: Bool {
            timeValue == 0 && mileageValue == 0 && expenseValue == 0
        }
    }

    private var breakdownRows: [BreakdownRow] {
        var rows: [BreakdownRow]
        if groupByProject {
            rows = allProjects.map { project in
                makeRow(
                    id: "project-\(project.persistentModelID.hashValue)",
                    name: project.name,
                    matches: { $0 === project }
                )
            }
            rows = rows.filter { !$0.isEmpty }
            let unassigned = makeRow(id: "project-unassigned", name: "Unassigned", matches: { $0 == nil })
            if !unassigned.isEmpty { rows.append(unassigned) }
        } else {
            var clientRows: [BreakdownRow] = allClients.map { client in
                let timeValue = timeEntries
                    .filter { $0.billable && $0.client === client }
                    .reduce(Decimal(0)) { $0 + $1.total }
                let miles = mileageEntries
                    .filter { $0.client === client }
                    .reduce(0.0) { $0 + $1.totalMiles }
                let expenseValue = expenses
                    .filter { $0.client === client }
                    .reduce(Decimal(0)) { $0 + $1.amount }
                return BreakdownRow(
                    id: "client-\(client.persistentModelID.hashValue)",
                    name: client.name,
                    timeValue: timeValue,
                    mileageValue: miles * mileageRate,
                    expenseValue: expenseValue
                )
            }
            clientRows = clientRows.filter { !$0.isEmpty }
            let unassignedTime = timeEntries
                .filter { $0.billable && $0.client == nil }
                .reduce(Decimal(0)) { $0 + $1.total }
            let unassignedMiles = mileageEntries
                .filter { $0.client == nil }
                .reduce(0.0) { $0 + $1.totalMiles }
            let unassignedExpenses = expenses
                .filter { $0.client == nil }
                .reduce(Decimal(0)) { $0 + $1.amount }
            let unassigned = BreakdownRow(
                id: "client-unassigned",
                name: "Unassigned",
                timeValue: unassignedTime,
                mileageValue: unassignedMiles * mileageRate,
                expenseValue: unassignedExpenses
            )
            if !unassigned.isEmpty { clientRows.append(unassigned) }
            rows = clientRows
        }
        return rows.sorted { lhs, rhs in
            // Unassigned stays last; otherwise highest combined value first.
            if lhs.name == "Unassigned" { return false }
            if rhs.name == "Unassigned" { return true }
            return lhs.combined > rhs.combined
        }
    }

    private func makeRow(id: String, name: String, matches: (Project?) -> Bool) -> BreakdownRow {
        let timeValue = timeEntries
            .filter { $0.billable && matches($0.project) }
            .reduce(Decimal(0)) { $0 + $1.total }
        let miles = mileageEntries
            .filter { matches($0.project) }
            .reduce(0.0) { $0 + $1.totalMiles }
        let expenseValue = expenses
            .filter { matches($0.project) }
            .reduce(Decimal(0)) { $0 + $1.amount }
        return BreakdownRow(
            id: id,
            name: name,
            timeValue: timeValue,
            mileageValue: miles * mileageRate,
            expenseValue: expenseValue
        )
    }

    @ViewBuilder
    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Breakdown")
                    .font(.headline)
                Spacer()
                Picker("Group By", selection: $groupByProject) {
                    Text("Client").tag(false)
                    Text("Project").tag(true)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .frame(maxWidth: 220)
            }

            if breakdownRows.isEmpty {
                Text("No entries in this date range.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(breakdownRows) { row in
                        VStack(alignment: .leading, spacing: 3) {
                            HStack {
                                Text(row.name)
                                    .fontWeight(.medium)
                                    .lineLimit(1)
                                Spacer()
                                Text(Formatters.currencyString(row.combined))
                                    .fontWeight(.semibold)
                                    .monospacedDigit()
                            }
                            Text("Time \(Formatters.currencyString(row.timeValue)) · Mileage \(Formatters.currencyString(row.mileageValue)) · Expenses \(Formatters.currencyString(row.expenseValue))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }
                        .padding(.vertical, 8)
                        if row.id != breakdownRows.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal, 12)
                .background(Color.gray.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}
