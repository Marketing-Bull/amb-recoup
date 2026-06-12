import SwiftUI
import SwiftData

/// Client-scoped project picker: disabled until a client is chosen,
/// resets the selection when the client changes.
struct ProjectPicker: View {
    let client: Client?
    @Binding var selection: Project?
    @Query(sort: \Project.name) private var allProjects: [Project]

    private var projects: [Project] {
        guard let client else { return [] }
        return allProjects.filter { $0.client === client && !$0.isArchived }
    }

    var body: some View {
        Picker("Project", selection: $selection) {
            Text("None").tag(nil as Project?)
            ForEach(projects) { project in
                Text(project.name).tag(project as Project?)
            }
        }
        .disabled(client == nil)
        .onChange(of: client) { _, newClient in
            // Keep the selection when it already belongs to the new client
            // (e.g. a recent-pair chip set both at once).
            if selection?.client !== newClient {
                selection = nil
            }
        }
    }
}
