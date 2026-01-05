import SwiftUI

struct SystemMetricsWidgetView: View {
    let widget: WidgetInstance
    @ObservedObject var metrics: SystemMetricsProvider
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        let layout = SystemMetricsLayout(sizeOption: widget.sizeOption)
        let compactDetail = widget.sizeOption == .small || widget.sizeOption == .medium
        let cpuPercent = metrics.cpuUsage
        let ramPercent = usagePercent(used: metrics.memoryUsed, total: metrics.memoryTotal)
        let diskPercent = usagePercent(used: metrics.diskUsed, total: metrics.diskTotal)
        Group {
            if widget.sizeOption == .medium {
                HStack(alignment: .top, spacing: layout.clusterSpacing) {
                    SystemUsageRingCluster(cpu: cpuPercent ?? 0,
                                           ram: ramPercent ?? 0,
                                           disk: diskPercent ?? 0,
                                           layout: layout)

                    VStack(alignment: .leading, spacing: layout.labelSpacing) {
                        SystemUsageLabelRow(title: localization.text(.widgetSystemCPU),
                                            percent: cpuPercent,
                                            detail: nil,
                                            color: Color(hex: 0xF7B731),
                                            layout: layout,
                                            alignment: .leading)
                        SystemUsageLabelRow(title: localization.text(.widgetSystemRAM),
                                            percent: ramPercent,
                                            detail: usageDetail(used: metrics.memoryUsed,
                                                                total: metrics.memoryTotal,
                                                                compact: compactDetail),
                                            color: Color(hex: 0x5CD0FF),
                                            layout: layout,
                                            alignment: .leading)
                        SystemUsageLabelRow(title: localization.text(.widgetSystemDisk),
                                            percent: diskPercent,
                                            detail: usageDetail(used: metrics.diskUsed,
                                                                total: metrics.diskTotal,
                                                                compact: compactDetail),
                                            color: Color(hex: 0xA78BFA),
                                            layout: layout,
                                            alignment: .leading)
                    }
                    Spacer(minLength: 0)
                }
            } else {
                VStack(alignment: .leading, spacing: layout.rowSpacing) {
                    SystemUsageRingCluster(cpu: cpuPercent ?? 0,
                                           ram: ramPercent ?? 0,
                                           disk: diskPercent ?? 0,
                                           layout: layout)

                    VStack(alignment: .leading, spacing: layout.labelSpacing) {
                        SystemUsageLabelRow(title: localization.text(.widgetSystemCPU),
                                            percent: cpuPercent,
                                            detail: nil,
                                            color: Color(hex: 0xF7B731),
                                            layout: layout,
                                            alignment: .leading)
                        SystemUsageLabelRow(title: localization.text(.widgetSystemRAM),
                                            percent: ramPercent,
                                            detail: usageDetail(used: metrics.memoryUsed,
                                                                total: metrics.memoryTotal,
                                                                compact: compactDetail),
                                            color: Color(hex: 0x5CD0FF),
                                            layout: layout,
                                            alignment: .leading)
                        SystemUsageLabelRow(title: localization.text(.widgetSystemDisk),
                                            percent: diskPercent,
                                            detail: usageDetail(used: metrics.diskUsed,
                                                                total: metrics.diskTotal,
                                                                compact: compactDetail),
                                            color: Color(hex: 0xA78BFA),
                                            layout: layout,
                                            alignment: .leading)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, layout.topPadding)
    }

    private func usagePercent(used: UInt64?, total: UInt64?) -> Double? {
        guard let used, let total, total > 0 else { return nil }
        return Double(used) / Double(total)
    }

    private func usageDetail(used: UInt64?, total: UInt64?, compact: Bool) -> String? {
        guard let used, let total else { return nil }
        if compact {
            return "\(formatBytesCompact(used))/\(formatBytesCompact(total))"
        }
        return "\(formatBytes(used))/\(formatBytes(total))"
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
    }

    private func formatBytesCompact(_ bytes: UInt64) -> String {
        let unitFormatter = ByteCountFormatter()
        unitFormatter.allowedUnits = [.useGB]
        unitFormatter.countStyle = .decimal
        unitFormatter.includesCount = false
        unitFormatter.includesUnit = true
        let unit = unitFormatter.string(fromByteCount: 1_000_000_000).trimmingCharacters(in: .whitespacesAndNewlines)

        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale.current
        numberFormatter.minimumFractionDigits = 0
        numberFormatter.maximumFractionDigits = 1
        let value = Double(bytes) / 1_000_000_000
        let number = numberFormatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
        return "\(number)\(unit)"
    }
}

private struct SystemMetricsLayout {
    let ringClusterSize: CGFloat
    let ringLineWidth: CGFloat
    let valueFontSize: CGFloat
    let titleFontSize: CGFloat
    let detailFontSize: CGFloat
    let rowSpacing: CGFloat
    let labelSpacing: CGFloat
    let clusterSpacing: CGFloat
    let rowPadding: CGFloat
    let topPadding: CGFloat
    let detailRightAligned: Bool
    let detailMinimumScale: CGFloat

    init(sizeOption: WidgetSizeOption) {
        switch sizeOption {
        case .small:
            ringClusterSize = 58
            ringLineWidth = 5.2
            valueFontSize = 15.6
            titleFontSize = 14.3
            detailFontSize = 9
            rowSpacing = 10
            labelSpacing = 3
            clusterSpacing = 12
            rowPadding = 6
            topPadding = 8
            detailRightAligned = true
            detailMinimumScale = 0.7
        default:
            ringClusterSize = 86
            ringLineWidth = 6.5
            valueFontSize = 19.5
            titleFontSize = 16.9
            detailFontSize = 11
            rowSpacing = 12
            labelSpacing = 6
            clusterSpacing = 16
            rowPadding = 8
            topPadding = 24
            detailRightAligned = false
            detailMinimumScale = 1.0
        }
    }
}

private struct SystemUsageLabelRow: View {
    let title: String
    let percent: Double?
    let detail: String?
    let color: Color
    let layout: SystemMetricsLayout
    let alignment: HorizontalAlignment

    var body: some View {
        HStack(spacing: 6) {
            Text(percentText)
                .font(.system(size: layout.valueFontSize, weight: .heavy))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: layout.titleFontSize, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 6)
            if let detail {
                Text(detail)
                    .font(.system(size: layout.detailFontSize, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(layout.detailMinimumScale)
                    .allowsTightening(true)
            }
        }
    }

    private var percentText: String {
        guard let percent else { return "—" }
        return "\(Int((percent * 100).rounded()))%"
    }
}

private struct SystemUsageRingCluster: View {
    let cpu: Double
    let ram: Double
    let disk: Double
    let layout: SystemMetricsLayout

    var body: some View {
        let outer = layout.ringClusterSize
        let middle = outer * 0.72
        let inner = outer * 0.48
        ZStack {
            SystemUsageRing(progress: disk,
                            color: Color(hex: 0xA78BFA),
                            size: outer,
                            lineWidth: layout.ringLineWidth)
            SystemUsageRing(progress: ram,
                            color: Color(hex: 0x5CD0FF),
                            size: middle,
                            lineWidth: layout.ringLineWidth)
            SystemUsageRing(progress: cpu,
                            color: Color(hex: 0xF7B731),
                            size: inner,
                            lineWidth: layout.ringLineWidth)
        }
        .frame(width: outer, height: outer)
    }
}

private struct SystemUsageRing: View {
    let progress: Double
    let color: Color
    let size: CGFloat
    let lineWidth: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.18), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(max(0, min(1, progress))))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: size, height: size)
    }
}

private extension Color {
    init(hex: UInt) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: 1.0)
    }
}
