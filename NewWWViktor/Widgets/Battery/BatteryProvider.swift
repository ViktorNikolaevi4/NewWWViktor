import Foundation
import Combine
#if os(macOS)
import IOKit.ps
import Combine
#elseif os(iOS)
import UIKit
#endif

final class BatteryProvider: ObservableObject {
    struct BatteryMinuteSample: Identifiable, Equatable, Codable {
        let date: Date
        let level: Int
        let isCharging: Bool

        var id: Date { date }
    }

    @Published private(set) var batteryLevel: Int?
    @Published private(set) var remainingTimeMinutes: Int?
    @Published private(set) var remainingTimeProgress: Double?
    @Published private(set) var isCharging: Bool?
    @Published private(set) var minuteHistory: [BatteryMinuteSample] = []

    private enum Constants {
        static let refreshInterval: TimeInterval = 5
    }

    private var lastRefreshDate: Date?
    private var observers: [NSObjectProtocol] = []
    private var baselineRemainingMinutes: Int?
    private var lastIsCharging: Bool?
    private var lastSampleMinute: Date?
    private var historyURL: URL? {
        let fm = FileManager.default
        guard let base = try? fm.url(for: .applicationSupportDirectory,
                                     in: .userDomainMask,
                                     appropriateFor: nil,
                                     create: true) else {
            return nil
        }
        let dir = base.appendingPathComponent("NewWWViktor", isDirectory: true)
        if !fm.fileExists(atPath: dir.path) {
            try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("battery-history.json")
    }

    init() {
        loadHistoryFromDisk()
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
        isCharging = remainingInfo.isCharging
        remainingTimeProgress = updateRemainingProgress(minutes: remainingInfo.minutes,
                                                        isCharging: remainingInfo.isCharging,
                                                        batteryLevel: batteryLevel)
        recordMinuteSample(now: now,
                           level: batteryLevel,
                           isCharging: remainingInfo.isCharging)
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
#elseif os(iOS)
        let state = UIDevice.current.batteryState
        let charging = state == .charging || state == .full
        return (nil, charging)
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

    private func recordMinuteSample(now: Date, level: Int?, isCharging: Bool?) {
        guard let level else { return }
        let minute = floor(now.timeIntervalSince1970 / 60) * 60
        let sampleDate = Date(timeIntervalSince1970: minute)
        let sample = BatteryMinuteSample(date: sampleDate,
                                         level: level,
                                         isCharging: isCharging ?? false)

        if lastSampleMinute == sampleDate {
            if let lastIndex = minuteHistory.indices.last {
                minuteHistory[lastIndex] = sample
            } else {
                minuteHistory = [sample]
            }
            return
        }

        lastSampleMinute = sampleDate
        minuteHistory.append(sample)

        let maxSamples = 120
        if minuteHistory.count > maxSamples {
            minuteHistory.removeFirst(minuteHistory.count - maxSamples)
        }
        persistHistoryToDisk()
    }

    private func persistHistoryToDisk() {
        guard let historyURL else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(minuteHistory) {
            try? data.write(to: historyURL, options: [.atomic])
        }
    }

    private func loadHistoryFromDisk() {
        guard let historyURL,
              let data = try? Data(contentsOf: historyURL) else { return }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        guard let history = try? decoder.decode([BatteryMinuteSample].self, from: data) else { return }
        minuteHistory = pruneHistory(history)
    }

    private func pruneHistory(_ history: [BatteryMinuteSample]) -> [BatteryMinuteSample] {
        let cutoff = Date().addingTimeInterval(-6 * 60 * 60)
        let filtered = history.filter { $0.date >= cutoff }
        let maxSamples = 360
        if filtered.count > maxSamples {
            return Array(filtered.suffix(maxSamples))
        }
        return filtered
    }
}
