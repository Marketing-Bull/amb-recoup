import Foundation
import Combine

enum AppSettings {
    static let mileageRateKey = "mileageRate"
    static let defaultMileageRate = 0.67
}

/// Keeps the mileage rate in iCloud key-value storage so the setting follows the
/// user's SwiftData records between iPhone, iPad, and Mac.
final class MileageRateStore: ObservableObject {
    @Published var mileageRate: Double {
        didSet {
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
            mileageRate = cloudStore.double(forKey: AppSettings.mileageRateKey)
        } else if localStore.object(forKey: AppSettings.mileageRateKey) != nil {
            mileageRate = localStore.double(forKey: AppSettings.mileageRateKey)
        } else {
            mileageRate = AppSettings.defaultMileageRate
        }

        cloudObserver = NotificationCenter.default.addObserver(
            forName: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: cloudStore,
            queue: .main
        ) { [weak self] notification in
            self?.applyCloudChange(notification)
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
            reason != NSUbiquitousKeyValueStoreQuotaViolationChange,
            cloudStore.object(forKey: AppSettings.mileageRateKey) != nil
        else { return }

        let cloudRate = cloudStore.double(forKey: AppSettings.mileageRateKey)
        if mileageRate != cloudRate {
            mileageRate = cloudRate
        }
    }
}
