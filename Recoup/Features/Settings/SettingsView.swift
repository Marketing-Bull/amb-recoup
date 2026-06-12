import SwiftUI

enum AppSettings {
    static let mileageRateKey = "mileageRate"
    static let defaultMileageRate = 0.67
}

struct SettingsView: View {
    @AppStorage(AppSettings.mileageRateKey) private var mileageRate = AppSettings.defaultMileageRate

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Rate per Mile")
                    Spacer()
                    TextField("Rate", value: $mileageRate, format: .number)
                        .decimalKeyboard()
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                }
                Stepper(
                    "\(Formatters.currencyString(mileageRate))/mi",
                    value: $mileageRate,
                    in: 0...5,
                    step: 0.005
                )
                .monospacedDigit()
            } header: {
                Text("Mileage")
            } footer: {
                Text("Applied to all mileage entries for deductible and billable amounts. The IRS standard rate for 2024–2025 is $0.67–$0.70/mi.")
            }
        }
        .formStyle(.grouped)
    }
}
