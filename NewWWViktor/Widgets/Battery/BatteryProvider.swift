import Foundation
import Combine
#if os(macOS)
import IOKit.ps
import Combine
#elseif os(iOS)
import UIKit
#endif

final class BatteryProvider: ObservableObject {
    @Published private(set) var batteryLevel: Int?

    private enum Constants {
        static let refreshInterval: TimeInterval = 60
    }

    private var lastRefreshDate: Date?
    private var observers: [NSObjectProtocol] = []

    init() {
#if os(iOS)
        UIDevice.current.isBatteryMonitoringEnabled = true
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: UIDevice.batteryLevelDidChangeNotification,
                                            object: nil,
                                            queue: .main) { [weak self] _ in
            self?.refresh(force: true)
        })
        observers.append(center.addObserver(forName: UIDevice.batteryStateDidChangeNotification,
                                            object: nil,
                                            queue: .main) { [weak self] _ in
            self?.refresh(force: true)
        })
#endif
        refresh(force: true)
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    func refresh() {
        refresh(force: false)
    }

    private func refresh(force: Bool) {
        let now = Date()
        if !force, let lastRefreshDate, now.timeIntervalSince(lastRefreshDate) < Constants.refreshInterval {
            return
        }
        lastRefreshDate = now
        batteryLevel = fetchBatteryLevel()
    }

    private func fetchBatteryLevel() -> Int? {
#if os(macOS)
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any],
              let current = description[kIOPSCurrentCapacityKey] as? Int,
              let maxCapacity = description[kIOPSMaxCapacityKey] as? Int,
              maxCapacity > 0 else {
            return nil
        }
        let percent = Int((Double(current) / Double(maxCapacity) * 100).rounded())
        return max(0, min(100, percent))
#elseif os(iOS)
        let level = UIDevice.current.batteryLevel
        guard level >= 0 else { return nil }
        let percent = Int((level * 100).rounded())
        return max(0, min(100, percent))
#else
        return nil
#endif
    }
}
