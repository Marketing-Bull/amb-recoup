import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Query(sort: \Project.name) private var allProjects: [Project]
    @State private var showArchived = false
    @State private var showingNewProject = false
    @State private var editingProject: Project?

    private var projects: [Project] {
        allProjects.filter { showArchived || !$0.isArchived }
    }

    var body: some View {
        Group {
            if projects.isEmpty {
                EmptyStateView(
                    title: "No Projects",
                    systemImage: "folder",
                    message: "Projects group your entries under a client and can override the client's hourly rate.",
                    actionTitle: "Add Project",
                    action: { showingNewProject = true }
                )
            } else {
                List {
                    ForEach(projects) { project in
                        Button {
                            editingProject = project
                        } label: {
                            ProjectRow(project: project)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(project.isArchived ? "Unarchive" : "Archive") {
                                project.isArchived.toggle()
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button(project.isArchived ? "Unarchive" : "Archive") {
                                project.isArchived.toggle()
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewProject = true
                } label: {
                    Label("Add Project", systemImage: "plus")
                }
            }
            ToolbarItem {
                Menu {
                    Toggle("Show Archived", isOn: $showArchived)
                } label: {
                    Label("Options", systemImage: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            ProjectFormView(project: nil)
        }
        .sheet(item: $editingProject) { project in
            ProjectFormView(project: project)
        }
    }
}

struct ProjectRow: View {
    let project: Project

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(project.name)
                        .fontWeight(.medium)
                    if project.isArchived {
                        Text("Archived")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                HStack(spacing: 6) {
                    Text(project.client?.name ?? "No client")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if project.status != .active {
                        Text(project.status.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.12), in: Capsule())
                            .foregroundStyle(.blue)
                    }
                }
            }
            Spacer()
            if let rate = project.hourlyRateOverride {
                Text("\(Formatters.currencyString(rate))/hr")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .contentShape(Rectangle())
    }
}
