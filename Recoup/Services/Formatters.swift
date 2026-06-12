import Foundation

enum Formatters {
    // MARK: - Currency

    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()

    static func currencyString(_ value: Decimal) -> String {
        currency.string(from: NSDecimalNumber(decimal: value)) ?? "$0.00"
    }

    static func currencyString(_ value: Double) -> String {
        currency.string(from: NSNumber(value: value)) ?? "$0.00"
    }

    // MARK: - Hours & miles

    /// "2.50h"
    static func hoursString(_ hours: Double) -> String {
        String(format: "%.2fh", hours)
    }

    /// Short chip label: "0.25h", "0.5h", "1h", "2h"
    static func hoursChipLabel(_ hours: Double) -> String {
        plainDouble(hours) + "h"
    }

    /// "12.4 mi"
    static func milesString(_ miles: Double) -> String {
        plainDouble(miles) + " mi"
    }

    // MARK: - Dates

    static let listDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    static func dateString(_ date: Date) -> String {
        listDate.string(from: date)
    }

    static let csvDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()

    static func csvDateString(_ date: Date) -> String {
        csvDate.string(from: date)
    }

    // MARK: - Plain numbers (CSV-safe, no grouping or symbols)

    /// Trims trailing zeros: 12.40 → "12.4", 12.00 → "12", 0.25 → "0.25"
    static func plainDouble(_ value: Double) -> String {
        let formatted = String(format: "%.2f", value)
        guard formatted.contains(".") else { return formatted }
        return formatted.replacingOccurrences(of: #"\.?0+$"#, with: "", options: .regularExpression)
    }

    static func plainDecimal(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}
