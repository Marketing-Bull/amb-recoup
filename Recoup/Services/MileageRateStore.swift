import Foundation
import Combine

enum AppSettings {
    static let mileageRateKey = "mileageRate"
    static let defaultMileageRate = 0.67
}

/// Keeps the mileage rate in iCloud key-value storage so the setting follows the
/// user's SwiftData records between iPhone, iPad, and Mac.
@MainActor
final class MileageRateStore: ObservableObject {
    @Published var mileageRate: Double {
        didSet {
            let normalized = Self.normalized(mileageRate)
            guard normalized == mileageRate else {
                mileageRate = normalized
                return
            }
            guard mileageRate != oldValue else { return }
            persist(mileageRate)
        }
    }

    private let localStore: UserDefaults
    private let cloudStore: NSUbiquitousKeyValueStore
    private var cloudObserver: NSObjectProtocol?

    init(
        localStore: UserDefaults = .standard,
        cloudStore: NSUbiquitousKeyValueStore = .default
    ) {
        self.localStore = localStore
        self.cloudStore = cloudStore

        if cloudStore.object(forKey: AppSettings.mileageRateKey) != nil {
            mileageRate = Self.normalized(cloudStore.double(forKey: AppSettings.mileageRateKey))
        } else if localStore.object(forKey: AppSettings.mileageRateKey) != nil {
            mileageRate = Self.normalized(localStore.double(forKey: AppSettings.mileageRateKey))
        } else {
            mileageRate = AppSettings.defaultMileageRate
        }

        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] notification in
            Task { @MainActor in
                self?.applyCloudChange(notification)
            }
        }

        // Pull changes made while the app was not running, then seed iCloud on
        // first launch for users upgrading from the local-only setting.
        cloudStore.synchronize()
        if cloudStore.object(forKey: AppSettings.mileageRateKey) == nil {
            persist(mileageRate)
        } else {
            localStore.set(mileageRate, forKey: AppSettings.mileageRateKey)
        }
    }

    deinit {
        if let cloudObserver {
            NotificationCenter.default.removeObserver(cloudObserver)
        }
    }

    private func persist(_ value: Double) {
        localStore.set(value, forKey: AppSettings.mileageRateKey)
        cloudStore.set(value, forKey: AppSettings.mileageRateKey)
    }

    private func applyCloudChange(_ notification: Notification) {
        guard
            let reason = notification.userInfo?[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int,
            reason != NSUbiquitousKeyValueStoreQuotaViolationChange
        else { return }

        guard cloudStore.object(forKey: AppSettings.mileageRateKey) != nil else {
            // A newly selected iCloud account may not have this setting yet.
            // Seed it from the device cache rather than retaining it only locally.
            if reason == NSUbiquitousKeyValueStoreAccountChange {
                persist(mileageRate)
            }
            return
        }

        let cloudRate = Self.normalized(cloudStore.double(forKey: AppSettings.mileageRateKey))
        if mileageRate != cloudRate {
            mileageRate = cloudRate
        }
    }

    static func normalized(_ value: Double) -> Double {
        guard value.isFinite else { return AppSettings.defaultMileageRate }
        return min(max(value, 0), 5)
    }
}
