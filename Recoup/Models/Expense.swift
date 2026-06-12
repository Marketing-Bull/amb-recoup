import Foundation
import SwiftData

@Model
final class Expense {
    var date: Date = Date()
    var amount: Decimal = 0
    private var categoryRaw: String = ExpenseCategory.other.rawValue
    var vendor: String = ""
    var details: String = ""
    var billable: Bool = false
    private var recurringRaw: String = RecurringType.none.rawValue
    @Attribute(.externalStorage) var receiptData: Data?
    var createdAt: Date = Date()

    var client: Client?
    var project: Project?

    var category: ExpenseCategory {
        get { ExpenseCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var recurring: RecurringType {
        get { RecurringType(rawValue: recurringRaw) ?? .none }
        set { recurringRaw = newValue.rawValue }
    }

    var isRecurring: Bool { recurring != .none }

    /// Amount projected over a year for recurring expenses; nil when not recurring.
    var annualizedAmount: Decimal? {
        recurring.annualMultiplier.map { amount * $0 }
    }

    init(
        date: Date = Date(),
        amount: Decimal = 0,
        category: ExpenseCategory = .other,
        vendor: String = "",
        details: String = "",
        billable: Bool = false,
        recurring: RecurringType = .none,
        receiptData: Data? = nil,
        client: Client? = nil,
        project: Project? = nil,
        createdAt: Date = Date()
    ) {
        self.date = date
        self.amount = amount
        self.categoryRaw = category.rawValue
        self.vendor = vendor
        self.details = details
        self.billable = billable
        self.recurringRaw = recurring.rawValue
        self.receiptData = receiptData
        self.client = client
        self.project = project
        self.createdAt = createdAt
    }

    /// Copy dated today, without the receipt image, not yet inserted into a context.
    func duplicate() -> Expense {
        Expense(
            date: Date(),
            amount: amount,
            category: category,
            vendor: vendor,
            details: details,
            billable: billable,
            recurring: recurring,
            client: client,
            project: project
        )
    }
}
