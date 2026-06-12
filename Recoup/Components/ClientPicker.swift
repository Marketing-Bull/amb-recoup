import SwiftUI
import SwiftData

struct ClientPicker: View {
    @Binding var selection: Client?
    @Query(sort: \Client.name) private var allClients: [Client]

    private var clients: [Client] {
        allClients.filter { !$0.isArchived }
    }

    var body: some View {
        Picker("Client", selection: $selection) {
            Text("None").tag(nil as Client?)
            ForEach(clients) { client in
                Text(client.name).tag(client as Client?)
            }
        }
    }
}
