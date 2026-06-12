import SwiftUI

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case time
    case mileage
    case expenses
    case clients
    case projects
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: "Dashboard"
        case .time: "Time"
        case .mileage: "Mileage"
        case .expenses: "Expenses"
        case .clients: "Clients"
        case .projects: "Projects"
        case .settings: "Settings"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard: "chart.bar.fill"
        case .time: "clock.fill"
        case .mileage: "car.fill"
        case .expenses: "creditcard.fill"
        case .clients: "person.2.fill"
        case .projects: "folder.fill"
        case .settings: "gearshape.fill"
        }
    }
}

/// Placeholder destination until each feature lands; replaced module by module.
struct SectionPlaceholderView: View {
    let section: AppSection

    var body: some View {
        ContentUnavailableView(
            section.title,
            systemImage: section.systemImage,
            description: Text("Coming soon")
        )
        .navigationTitle(section.title)
    }
}

struct RootView: View {
    var body: some View {
        #if os(macOS)
        MacRootView()
        #else
        IOSRootView()
        #endif
    }
}

/// Resolves a section to its feature view; placeholders shrink as modules land.
struct SectionDestinationView: View {
    let section: AppSection

    var body: some View {
        switch section {
        case .clients:
            ClientListView()
                .navigationTitle("Clients")
        case .projects:
            ProjectListView()
                .navigationTitle("Projects")
        default:
            SectionPlaceholderView(section: section)
        }
    }
}

#if os(iOS)
struct IOSRootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                SectionDestinationView(section: .dashboard)
            }
            .tabItem { Label(AppSection.dashboard.title, systemImage: AppSection.dashboard.systemImage) }

            NavigationStack {
                SectionDestinationView(section: .time)
            }
            .tabItem { Label(AppSection.time.title, systemImage: AppSection.time.systemImage) }

            NavigationStack {
                SectionDestinationView(section: .mileage)
            }
            .tabItem { Label(AppSection.mileage.title, systemImage: AppSection.mileage.systemImage) }

            NavigationStack {
                SectionDestinationView(section: .expenses)
            }
            .tabItem { Label(AppSection.expenses.title, systemImage: AppSection.expenses.systemImage) }

            NavigationStack {
                ClientsAndProjectsView()
            }
            .tabItem { Label(AppSection.clients.title, systemImage: AppSection.clients.systemImage) }
        }
    }
}

/// Clients tab with a Clients/Projects segmented control.
struct ClientsAndProjectsView: View {
    @State private var showingProjects = false

    var body: some View {
        VStack(spacing: 0) {
            Picker("Section", selection: $showingProjects) {
                Text("Clients").tag(false)
                Text("Projects").tag(true)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            if showingProjects {
                ProjectListView()
            } else {
                ClientListView()
            }
        }
        .navigationTitle(showingProjects ? "Projects" : "Clients")
        .inlineNavigationTitle()
    }
}
#endif

#if os(macOS)
struct MacRootView: View {
    @State private var selection: AppSection? = .dashboard

    var body: some View {
        NavigationSplitView {
            List(AppSection.allCases, selection: $selection) { section in
                Label(section.title, systemImage: section.systemImage)
                    .tag(section)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
        } detail: {
            SectionDestinationView(section: selection ?? .dashboard)
        }
    }
}
#endif

#Preview {
    RootView()
        .modelContainer(PreviewSampleData.container)
}
