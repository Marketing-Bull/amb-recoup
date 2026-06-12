import SwiftUI
import SwiftData

/// One-tap recent client+project chips shown at the top of entry forms.
struct RecentPairChips: View {
    @Binding var client: Client?
    @Binding var project: Project?

    @Query private var timeEntries: [TimeEntry]
    @Query private var expenses: [Expense]
    @Query private var mileageEntries: [MileageEntry]

    private var pairs: [ClientProjectPair] {
        Recents.recentPairs(timeEntries: timeEntries, expenses: expenses, mileageEntries: mileageEntries)
    }

    var body: some View {
        if !pairs.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(pairs, id: \.self) { pair in
                        Button {
                            client = pair.client
                            project = pair.project
                        } label: {
                            Text(pair.label)
                                .font(.callout)
                                .lineLimit(1)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    isSelected(pair) ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12),
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func isSelected(_ pair: ClientProjectPair) -> Bool {
        pair.client === client && pair.project === project
    }
}
