import Foundation

enum RateResolver {
    /// Effective hourly rate for a client/project pair:
    /// project override → client rate → 0.
    /// Resolved once at save and locked on the entry; never recomputed.
    static func resolvedRate(client: Client?, project: Project?) -> Decimal {
        if let override = project?.hourlyRateOverride {
            return override
        }
        if let rate = client?.hourlyRate {
            return rate
        }
        return 0
    }
}
