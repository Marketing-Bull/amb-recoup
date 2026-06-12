import Foundation

enum ExpenseCategory: String, Codable, CaseIterable, Identifiable {
    case software = "Software"
    case meals = "Meals"
    case travel = "Travel"
    case advertising = "Advertising"
    case office = "Office"
    case contractors = "Contractors"
    case other = "Other"

    var id: String { rawValue }
    var displayName: String { rawValue }

    var systemImage: String {
        switch self {
        case .software: "laptopcomputer"
        case .meals: "fork.knife"
        case .travel: "airplane"
        case .advertising: "megaphone"
        case .office: "printer"
        case .contractors: "person.2"
        case .other: "tray"
        }
    }
}

enum RecurringType: String, Codable, CaseIterable, Identifiable {
    case none = "None"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case yearly = "Yearly"

    var id: String { rawValue }

    /// Multiplier to annualize a recurring amount; nil when not recurring.
    var annualMultiplier: Decimal? {
        switch self {
        case .none: nil
        case .weekly: 52
        case .monthly: 12
        case .yearly: 1
        }
    }
}

enum ProjectStatus: String, Codable, CaseIterable, Identifiable {
    case active = "Active"
    case onHold = "On Hold"
    case completed = "Completed"

    var id: String { rawValue }
}
