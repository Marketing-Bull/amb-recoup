import Foundation

enum CSVExporter {
    static func escape(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") || field.contains("\r") {
            return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return field
    }

    static func makeCSV(header: [String], rows: [[String]]) -> String {
        ([header] + rows)
            .map { $0.map(escape).joined(separator: ",") }
            .joined(separator: "\r\n")
    }

    /// Writes the CSV to a temp file and returns its URL for sharing.
    static func writeTempFile(named filename: String, header: [String], rows: [[String]]) throws -> URL {
        let csv = makeCSV(header: header, rows: rows)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try Data(csv.utf8).write(to: url, options: .atomic)
        return url
    }
}

// MARK: - Per-module rows

extension CSVExporter {
    static let timeHeader = ["date", "client", "project", "description", "hours", "rate", "billable", "total"]

    static func timeRows(_ entries: [TimeEntry]) -> [[String]] {
        entries.map { entry in
            [
                Formatters.csvDateString(entry.date),
                entry.client?.name ?? "",
                entry.project?.name ?? "",
                entry.details,
                Formatters.plainDouble(entry.hours),
                Formatters.plainDecimal(entry.rate),
                entry.billable ? "true" : "false",
                Formatters.plainDecimal(entry.total),
            ]
        }
    }

    static let mileageHeader = [
        "date", "start_address", "end_address", "purpose", "client", "project",
        "miles", "round_trip", "total_miles", "rate", "amount", "billable",
    ]

    static func mileageRows(_ entries: [MileageEntry], rate: Double) -> [[String]] {
        entries.map { entry in
            [
                Formatters.csvDateString(entry.date),
                entry.startAddress,
                entry.endAddress,
                entry.purpose,
                entry.client?.name ?? "",
                entry.project?.name ?? "",
                Formatters.plainDouble(entry.miles),
                entry.roundTrip ? "true" : "false",
                Formatters.plainDouble(entry.totalMiles),
                Formatters.plainDouble(rate),
                String(format: "%.2f", entry.totalMiles * rate),
                entry.billable ? "true" : "false",
            ]
        }
    }

    static let expenseHeader = [
        "date", "vendor", "description", "category", "client", "project",
        "amount", "billable", "recurring_type", "has_receipt",
    ]

    static func expenseRows(_ expenses: [Expense]) -> [[String]] {
        expenses.map { expense in
            [
                Formatters.csvDateString(expense.date),
                expense.vendor,
                expense.details,
                expense.category.rawValue,
                expense.client?.name ?? "",
                expense.project?.name ?? "",
                Formatters.plainDecimal(expense.amount),
                expense.billable ? "true" : "false",
                expense.recurring.rawValue,
                expense.receiptData != nil ? "true" : "false",
            ]
        }
    }
}
