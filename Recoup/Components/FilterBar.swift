import SwiftUI
import SwiftData

enum DateRangePreset: String, CaseIterable, Identifiable {
    case thisMonth = "This Month"
    case lastMonth = "Last Month"
    case yearToDate = "YTD"
    case all = "All"

    var id: String { rawValue }

    /// nil means no date restriction.
    var dateInterval: DateInterval? {
        let calendar = Calendar.current
        let now = Date()
        switch self {
        case .thisMonth:
            return calendar.dateInterval(of: .month, for: now)
        case .lastMonth:
            guard let thisMonth = calendar.dateInterval(of: .month, for: now),
                  let lastMonthDate = calendar.date(byAdding: .month, value: -1, to: thisMonth.start)
            else { return nil }
            return calendar.dateInterval(of: .month, for: lastMonthDate)
        case .yearToDate:
            return calendar.dateInterval(of: .year, for: now)
        case .all:
            return nil
        }
    }

    func contains(_ date: Date) -> Bool {
        guard let interval = dateInterval else { return true }
        return interval.contains(date)
    }
}

struct EntryFilter: Equatable {
    var client: Client?
    var project: Project?
    var datePreset: DateRangePreset = .all

    var isActive: Bool {
        client != nil || project != nil || datePreset != .all
    }

    func matches(date: Date, client: Client?, project: Project?) -> Bool {
        if let filterClient = self.client, filterClient !== client { return false }
        if let filterProject = self.project, filterProject !== project { return false }
        return datePreset.contains(date)
    }
}

/// Shared client / project / date-range filter row for the three entry lists.
struct FilterBar: View {
    @Binding var filter: EntryFilter
    @Query(sort: \Client.name) private var allClients: [Client]
    @Query(sort: \Project.name) private var allProjects: [Project]

    private var clients: [Client] {
        allClients.filter { !$0.isArchived }
    }

    private var projects: [Project] {
        guard let client = filter.client else { return [] }
        return allProjects.filter { $0.client === client && !$0.isArchived }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Menu {
                    Button("All Clients") {
                        filter.client = nil
                        filter.project = nil
                    }
                    ForEach(clients) { client in
                        Button(client.name) {
                            filter.client = client
                            filter.project = nil
                        }
                    }
                } label: {
                    chip(filter.client?.name ?? "All Clients", isActive: filter.client != nil)
                }

                Menu {
                    Button("All Projects") {
                        filter.project = nil
                    }
                    ForEach(projects) { project in
                        Button(project.name) {
                            filter.project = project
                        }
                    }
                } label: {
                    chip(filter.project?.name ?? "All Projects", isActive: filter.project != nil)
                }
                .disabled(filter.client == nil)

                Menu {
                    ForEach(DateRangePreset.allCases) { preset in
                        Button(preset.rawValue) {
                            filter.datePreset = preset
                        }
                    }
                } label: {
                    chip(filter.datePreset.rawValue, isActive: filter.datePreset != .all)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }

    private func chip(_ text: String, isActive: Bool) -> some View {
        HStack(spacing: 4) {
            Text(text)
            Image(systemName: "chevron.down")
                .font(.caption2)
        }
        .font(.callout)
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isActive ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12),
            in: Capsule()
        )
        .foregroundStyle(isActive ? Color.accentColor : Color.primary)
    }
}
