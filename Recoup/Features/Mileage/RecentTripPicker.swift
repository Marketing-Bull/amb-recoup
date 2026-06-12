import SwiftUI
import SwiftData

/// One-tap "repeat a trip" menu: distinct recent trips that autofill the form.
struct RecentTripPicker: View {
    let onSelect: (MileageEntry) -> Void

    @Query(sort: \MileageEntry.createdAt, order: .reverse) private var allEntries: [MileageEntry]

    private var trips: [MileageEntry] {
        Recents.recentTrips(allEntries)
    }

    var body: some View {
        if !trips.isEmpty {
            Menu {
                ForEach(trips) { trip in
                    Button(label(for: trip)) {
                        onSelect(trip)
                    }
                }
            } label: {
                Label("Repeat a Recent Trip", systemImage: "arrow.counterclockwise")
            }
        }
    }

    private func label(for trip: MileageEntry) -> String {
        var parts: [String] = []
        let route = [trip.startAddress, trip.endAddress].filter { !$0.isEmpty }.joined(separator: " → ")
        parts.append(route.isEmpty ? "Unnamed trip" : route)
        parts.append(Formatters.milesString(trip.miles))
        if trip.roundTrip { parts.append("RT") }
        if let client = trip.client { parts.append(client.name) }
        return parts.joined(separator: " · ")
    }
}
