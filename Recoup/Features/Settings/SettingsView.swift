import SwiftUI

struct SettingsView: View {
    @StateObject private var settings = MileageRateStore()

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Rate per Mile")
                    Spacer()
                    TextField("Rate", value: $settings.mileageRate, format: .number)
                        .decimalKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                Stepper(
                    "\(Formatters.currencyString(settings.mileageRate))/mi",
                    value: $settings.mileageRate,
                    in: 0...5,
                    step: 0.005
                )
                .monospacedDigit()
            } header: {
                Text("Mileage")
            } footer: {
                Text("Applied to all mileage entries for deductible and billable amounts. This setting syncs through iCloud across your devices.")
            }
        }
        .formStyle(.grouped)
    }
}
