import SwiftUI
import SwiftData

struct ClientListView: View {
    @Query(sort: \Client.name) private var allClients: [Client]
    @State private var showArchived = false
    @State private var showingNewClient = false
    @State private var editingClient: Client?

    private var clients: [Client] {
        allClients.filter { showArchived || !$0.isArchived }
    }

    var body: some View {
        Group {
            if clients.isEmpty {
                EmptyStateView(
                    title: "No Clients",
                    systemImage: "person.2",
                    message: "Add your first client to start tracking time, expenses, and mileage.",
                    actionTitle: "Add Client",
                    action: { showingNewClient = true }
                )
            } else {
                List {
                    ForEach(clients) { client in
                        Button {
                            editingClient = client
                        } label: {
                            ClientRow(client: client)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing) {
                            Button(client.isArchived ? "Unarchive" : "Archive") {
                                client.isArchived.toggle()
                            }
                            .tint(.orange)
                        }
                        .contextMenu {
                            Button(client.isArchived ? "Unarchive" : "Archive") {
                                client.isArchived.toggle()
                            }
                        }
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewClient = true
                } label: {
                    Label("Add Client", systemImage: "plus")
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
        .sheet(isPresented: $showingNewClient) {
            ClientFormView(client: nil)
        }
        .sheet(item: $editingClient) { client in
            ClientFormView(client: client)
        }
    }
}

struct ClientRow: View {
    let client: Client

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(client.name)
                        .fontWeight(.medium)
                    if client.isArchived {
                        Text("Archived")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.2), in: Capsule())
                            .foregroundStyle(.secondary)
                    }
                }
                if !client.contactName.isEmpty {
                    Text(client.contactName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let rate = client.hourlyRate {
                Text("\(Formatters.currencyString(rate))/hr")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
        .contentShape(Rectangle())
    }
}
