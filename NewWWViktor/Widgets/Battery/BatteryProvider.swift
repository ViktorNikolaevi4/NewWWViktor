import Foundation
import Combine
#if os(macOS)
import IOKit
import IOKit.ps
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
    @Published private(set) var maximumCapacityPercent: Int?
    @Published private(set) var currentCapacityMah: Int?
    @Published private(set) var maxCapacityMah: Int?
    @Published private(set) var designCapacityMah: Int?
    @Published private(set) var optimizedChargingEnabled: Bool?

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
        #if os(macOS)
        let description = fetchPowerSourceDescription()
        let smartBattery = fetchSmartBatteryInfo()
        batteryLevel = fetchBatteryLevel(description: description)
        let remainingInfo = fetchRemainingTimeInfo(description: description)
        let capacityInfo = fetchCapacityInfo(description: description, smartBattery: smartBattery)
        maximumCapacityPercent = capacityInfo.maximumCapacityPercent
        currentCapacityMah = capacityInfo.currentCapacityMah
        maxCapacityMah = capacityInfo.maxCapacityMah
        designCapacityMah = capacityInfo.designCapacityMah
        optimizedChargingEnabled = capacityInfo.optimizedChargingEnabled
        #elseif os(iOS)
        batteryLevel = fetchBatteryLevel(description: nil)
        let remainingInfo = fetchRemainingTimeInfo(description: nil)
        maximumCapacityPercent = nil
        currentCapacityMah = nil
        maxCapacityMah = nil
        optimizedChargingEnabled = nil
        #else
        batteryLevel = nil
        let remainingInfo = (minutes: nil, isCharging: nil)
        maximumCapacityPercent = nil
        currentCapacityMah = nil
        maxCapacityMah = nil
        optimizedChargingEnabled = nil
        #endif
        remainingTimeMinutes = remainingInfo.minutes
        isCharging = remainingInfo.isCharging
        remainingTimeProgress = updateRemainingProgress(minutes: remainingInfo.minutes,
                                                        isCharging: remainingInfo.isCharging,
                                                        batteryLevel: batteryLevel)
        recordMinuteSample(now: now,
                           level: batteryLevel,
                           isCharging: remainingInfo.isCharging)
    }

    private func fetchBatteryLevel(description: [String: Any]?) -> Int? {
#if os(macOS)
        guard let description,
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

    private func fetchRemainingTimeInfo(description: [String: Any]?) -> (minutes: Int?, isCharging: Bool?) {
#if os(macOS)
        guard let description else { return (nil, nil) }
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

    private func fetchPowerSourceDescription() -> [String: Any]? {
#if os(macOS)
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef],
              let source = sources.first,
              let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] else {
            return nil
        }
        return description
#else
        return nil
#endif
    }

    private func fetchCapacityInfo(description: [String: Any]?,
                                   smartBattery: [String: Any]?) -> (maximumCapacityPercent: Int?, currentCapacityMah: Int?, maxCapacityMah: Int?, designCapacityMah: Int?, optimizedChargingEnabled: Bool?) {
#if os(macOS)
        let current = intValue(from: smartBattery, keys: ["AppleRawCurrentCapacity", "CurrentCapacity", "ChargeCapacity"])
        let maxCapacity = intValue(from: smartBattery, keys: ["AppleRawMaxCapacity", "MaxCapacity"])
        let nominalCapacity = intValue(from: smartBattery, keys: ["NominalChargeCapacity"])
        let designCapacity = intValue(from: smartBattery, keys: ["DesignCapacity", "AppleRawDesignCapacity"])

        let maxMah = firstCapacityMah(nominalCapacity, maxCapacity)
        var currentMah = firstCapacityMah(current)
        if currentMah == nil, let maxMah, let percent = batteryLevel {
            currentMah = Int((Double(maxMah) * Double(percent) / 100.0).rounded())
        }
        let designMah = firstCapacityMah(designCapacity)

        let reportedPercent = intValue(from: smartBattery,
                                       keys: ["MaximumCapacityPercent", "MaxCapacityPercent", "BatteryHealthPercent"])

        let percent: Int?
        if let reportedPercent, (1...100).contains(reportedPercent) {
            percent = reportedPercent
        } else if let maxMah, let designMah {
            percent = Int((Double(maxMah) / Double(designMah) * 100).rounded())
        } else if let maxCapacity, maxCapacity <= 100 {
            percent = maxCapacity
        } else if let maxCapacity, let designCapacity, designCapacity > 0 {
            percent = Int((Double(maxCapacity) / Double(designCapacity) * 100).rounded())
        } else {
            percent = nil
        }

        let optimized = optimizedChargingFlag(from: smartBattery ?? description ?? [:])
        return (percent, currentMah, maxMah, designMah, optimized)
#else
        return (nil, nil, nil, nil, nil)
#endif
    }

#if os(macOS)
    private func fetchSmartBatteryInfo() -> [String: Any]? {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        guard service != 0 else { return nil }
        defer { IOObjectRelease(service) }
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS,
              let dict = properties?.takeRetainedValue() as? [String: Any] else {
            return nil
        }
        return dict
    }

    private func intValue(from dict: [String: Any]?, keys: [String]) -> Int? {
        guard let dict else { return nil }
        for key in keys {
            if let value = dict[key] as? Int {
                return value
            }
            if let value = dict[key] as? NSNumber {
                return value.intValue
            }
            if let value = dict[key] as? String, let intValue = Int(value) {
                return intValue
            }
        }
        return nil
    }

    private func firstCapacityMah(_ values: Int?...) -> Int? {
        for value in values {
            if let value, value >= 500 {
                return value
            }
        }
        return nil
    }

    private func optimizedChargingFlag(from description: [String: Any]) -> Bool? {
        let keys = [
            "Optimized Battery Charging Engaged",
            "Optimized Battery Charging",
            "Battery Charging Optimization",
            "OptimizedBatteryChargingEngaged",
            "OptimizedBatteryChargingEnabled"
        ]
        for key in keys {
            if let value = description[key] as? Bool {
                return value
            }
            if let value = description[key] as? Int {
                return value != 0
            }
            if let value = description[key] as? String {
                let lower = value.lowercased()
                if lower == "on" || lower == "yes" || lower == "true" {
                    return true
                }
                if lower == "off" || lower == "no" || lower == "false" {
                    return false
                }
            }
        }
        return pmsetOptimizedChargingFlag()
    }

    private func pmsetOptimizedChargingFlag() -> Bool? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-g"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
        } catch {
            return nil
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else { return nil }
        for line in output.split(separator: "\n") {
            if line.lowercased().contains("optimized battery charging") {
                if line.lowercased().contains("on") {
                    return true
                }
                if line.lowercased().contains("off") {
                    return false
                }
            }
        }
        return nil
    }
#endif

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
