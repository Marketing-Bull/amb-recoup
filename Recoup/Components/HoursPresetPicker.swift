import SwiftUI

/// Hours input without a keyboard: preset chips + a ±0.25 stepper.
struct HoursPresetPicker: View {
    @Binding var hours: Double

    private static let presets: [Double] = [0.25, 0.5, 1, 2]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                ForEach(Self.presets, id: \.self) { preset in
                    Button {
                        hours = preset
                    } label: {
                        Text(Formatters.hoursChipLabel(preset))
                            .font(.callout)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                hours == preset ? Color.accentColor.opacity(0.18) : Color.gray.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            Stepper(value: $hours, in: 0...24, step: 0.25) {
                Text(Formatters.hoursString(hours))
                    .monospacedDigit()
                    .fontWeight(.medium)
            }
        }
    }
}
