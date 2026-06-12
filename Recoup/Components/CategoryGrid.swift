import SwiftUI

/// Tappable icon grid for the fixed expense categories.
struct CategoryGrid: View {
    @Binding var selection: ExpenseCategory

    private let columns = [GridItem(.adaptive(minimum: 84), spacing: 10)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 10) {
            ForEach(ExpenseCategory.allCases) { category in
                Button {
                    selection = category
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: category.systemImage)
                            .font(.title3)
                        Text(category.displayName)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        selection == category ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.1),
                        in: RoundedRectangle(cornerRadius: 10)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(selection == category ? Color.accentColor : .clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}
