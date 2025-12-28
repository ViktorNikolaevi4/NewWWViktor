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
    @Published private(set) var remainingTimeMinutes: Int?
    @Published private(set) var remainingTimeProgress: Double?

    private enum Constants {
        static let refreshInterval: TimeInterval = 60
    }

    private var lastRefreshDate: Date?
    private var observers: [NSObjectProtocol] = []
    private var baselineRemainingMinutes: Int?
    private var lastIsCharging: Bool?

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
        let remainingInfo = fetchRemainingTimeInfo()
        remainingTimeMinutes = remainingInfo.minutes
        remainingTimeProgress = updateRemainingProgress(minutes: remainingInfo.minutes,
                                                        isCharging: remainingInfo.isCharging,
                                                        batteryLevel: batteryLevel)
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

    private func fetchRemainingTimeInfo() -> (minutes: Int?, isCharging: Bool?) {
#if os(macOS)
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return (nil, nil)
        }

        let isCharging = (description[kIOPSIsChargingKey] as? Bool) ?? false
        let timeKey = isCharging ? kIOPSTimeToFullChargeKey : kIOPSTimeToEmptyKey
        guard let minutes = description[timeKey] as? Int, minutes > 0 else {
            return (nil, isCharging)
        }
        return (minutes, isCharging)
#else
        return (nil, nil)
#endif
    }

    private func updateRemainingProgress(minutes: Int?, isCharging: Bool?, batteryLevel: Int?) -> Double? {
        guard let minutes else {
            baselineRemainingMinutes = nil
            lastIsCharging = nil
            return nil
        }
        guard let batteryLevel else { return nil }

        if let isCharging {
            if lastIsCharging == nil || lastIsCharging != isCharging || baselineRemainingMinutes == nil {
                baselineRemainingMinutes = minutes
            }
            lastIsCharging = isCharging
        } else if baselineRemainingMinutes == nil {
            baselineRemainingMinutes = minutes
        }

        let level = Double(max(0, min(100, batteryLevel)))
        if isCharging == true {
            let remainingPercent = (100.0 - level) / 100.0
            return min(1, max(0, remainingPercent))
        } else {
            let remainingPercent = level / 100.0
            return min(1, max(0, remainingPercent))
        }
    }
}
