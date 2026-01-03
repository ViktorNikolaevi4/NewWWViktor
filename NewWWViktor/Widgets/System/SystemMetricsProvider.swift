import Foundation
#if os(macOS)
import Combine
import Darwin
#else
import Combine
#endif

final class SystemMetricsProvider: ObservableObject {
    @Published private(set) var cpuUsage: Double?
    @Published private(set) var memoryUsed: UInt64?
    @Published private(set) var memoryTotal: UInt64?
    @Published private(set) var diskUsed: UInt64?
    @Published private(set) var diskTotal: UInt64?

    private var timer: Timer?
    private var previousTotalTicks: UInt64?
    private var previousIdleTicks: UInt64?

    init(preview: Bool = false) {
        if preview {
            cpuUsage = 0.42
            memoryTotal = 16_000_000_000
            memoryUsed = 9_800_000_000
            diskTotal = 512_000_000_000
            diskUsed = 314_000_000_000
        } else {
            refresh()
            scheduleTimer()
        }
    }

    deinit {
        timer?.invalidate()
    }

    private func scheduleTimer() {
        timer?.invalidate()
        let interval: TimeInterval = 2
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        timer?.tolerance = interval * 0.1
    }

    private func refresh() {
#if os(macOS)
        let cpu = fetchCPUUsage()
        let memory = fetchMemoryUsage()
        let disk = fetchDiskUsage()
        DispatchQueue.main.async {
            self.cpuUsage = cpu
            self.memoryUsed = memory.used
            self.memoryTotal = memory.total
            self.diskUsed = disk.used
            self.diskTotal = disk.total
        }
#else
        DispatchQueue.main.async {
            self.cpuUsage = nil
            self.memoryUsed = nil
            self.memoryTotal = nil
            self.diskUsed = nil
            self.diskTotal = nil
        }
#endif
    }

#if os(macOS)
    private func fetchCPUUsage() -> Double? {
        var cpuCount: natural_t = 0
        var infoCount: mach_msg_type_number_t = 0
        var cpuInfo: processor_info_array_t?
        let result = host_processor_info(mach_host_self(),
                                         PROCESSOR_CPU_LOAD_INFO,
                                         &cpuCount,
                                         &cpuInfo,
                                         &infoCount)
        guard result == KERN_SUCCESS, let cpuInfo else { return nil }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: cpuInfo), vm_size_t(infoCount))
        }

        let cpuInfoPointer = cpuInfo.withMemoryRebound(to: integer_t.self, capacity: Int(infoCount)) { $0 }
        var totalTicks: UInt64 = 0
        var idleTicks: UInt64 = 0
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * Int(CPU_STATE_MAX)
            let user = UInt64(cpuInfoPointer[base + Int(CPU_STATE_USER)])
            let system = UInt64(cpuInfoPointer[base + Int(CPU_STATE_SYSTEM)])
            let idle = UInt64(cpuInfoPointer[base + Int(CPU_STATE_IDLE)])
            let nice = UInt64(cpuInfoPointer[base + Int(CPU_STATE_NICE)])
            totalTicks += user + system + idle + nice
            idleTicks += idle
        }

        guard let previousTotalTicks, let previousIdleTicks else {
            self.previousTotalTicks = totalTicks
            self.previousIdleTicks = idleTicks
            return nil
        }

        let deltaTotal = totalTicks - previousTotalTicks
        let deltaIdle = idleTicks - previousIdleTicks
        self.previousTotalTicks = totalTicks
        self.previousIdleTicks = idleTicks
        guard deltaTotal > 0 else { return nil }
        let usage = Double(deltaTotal - deltaIdle) / Double(deltaTotal)
        return max(0, min(1, usage))
    }

    private func fetchMemoryUsage() -> (used: UInt64?, total: UInt64?) {
        var pageSize: vm_size_t = 0
        let host = mach_host_self()
        host_page_size(host, &pageSize)

        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(host, HOST_VM_INFO64, $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return (nil, nil) }

        let usedPages = UInt64(stats.active_count + stats.wire_count + stats.compressor_page_count)
        let usedBytes = usedPages * UInt64(pageSize)
        let totalBytes = ProcessInfo.processInfo.physicalMemory
        return (usedBytes, totalBytes)
    }

    private func fetchDiskUsage() -> (used: UInt64?, total: UInt64?) {
        let url = URL(fileURLWithPath: "/")
        let keys: Set<URLResourceKey> = [
            .volumeTotalCapacityKey,
            .volumeAvailableCapacityForImportantUsageKey
        ]
        guard let values = try? url.resourceValues(forKeys: keys),
              let total = values.volumeTotalCapacity,
              let available = values.volumeAvailableCapacityForImportantUsage else {
            return (nil, nil)
        }
        let totalBytes = UInt64(total)
        let availableBytes = UInt64(available)
        let usedBytes = totalBytes > availableBytes ? totalBytes - availableBytes : 0
        return (usedBytes, totalBytes)
    }
#endif
}
