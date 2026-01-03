import SwiftUI

struct SystemMetricsWidgetView: View {
    let widget: WidgetInstance
    @ObservedObject var metrics: SystemMetricsProvider
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        let layout = SystemMetricsLayout(sizeOption: widget.sizeOption)
        let cpuPercent = metrics.cpuUsage
        let ramPercent = usagePercent(used: metrics.memoryUsed, total: metrics.memoryTotal)
        let diskPercent = usagePercent(used: metrics.diskUsed, total: metrics.diskTotal)
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
                                    detail: usageDetail(used: metrics.memoryUsed, total: metrics.memoryTotal),
                                    color: Color(hex: 0x5CD0FF),
                                    layout: layout,
                                    alignment: .leading)
                SystemUsageLabelRow(title: localization.text(.widgetSystemDisk),
                                    percent: diskPercent,
                                    detail: usageDetail(used: metrics.diskUsed, total: metrics.diskTotal),
                                    color: Color(hex: 0xA78BFA),
                                    layout: layout,
                                    alignment: .leading)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 4)
    }

    private func usagePercent(used: UInt64?, total: UInt64?) -> Double? {
        guard let used, let total, total > 0 else { return nil }
        return Double(used) / Double(total)
    }

    private func usageDetail(used: UInt64?, total: UInt64?) -> String? {
        guard let used, let total else { return nil }
        return "\(formatBytes(used))/\(formatBytes(total))"
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB]
        formatter.countStyle = .decimal
        formatter.includesUnit = true
        return formatter.string(fromByteCount: Int64(bytes))
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
    let rowPadding: CGFloat

    init(sizeOption: WidgetSizeOption) {
        switch sizeOption {
        case .small:
            ringClusterSize = 58
            ringLineWidth = 4
            valueFontSize = 12
            titleFontSize = 11
            detailFontSize = 9
            rowSpacing = 10
            labelSpacing = 3
            rowPadding = 6
        case .medium:
            ringClusterSize = 70
            ringLineWidth = 4
            valueFontSize = 13
            titleFontSize = 12
            detailFontSize = 10
            rowSpacing = 12
            labelSpacing = 4
            rowPadding = 8
        case .large, .extraLarge:
            ringClusterSize = 82
            ringLineWidth = 5
            valueFontSize = 14
            titleFontSize = 12
            detailFontSize = 10
            rowSpacing = 12
            labelSpacing = 5
            rowPadding = 8
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
        VStack(alignment: alignment, spacing: 2) {
            HStack(spacing: 6) {
                Text(percentText)
                    .font(.system(size: layout.valueFontSize, weight: .bold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: layout.titleFontSize, weight: .semibold))
                    .foregroundStyle(.primary)
            }

            if let detail {
                Text(detail)
                    .font(.system(size: layout.detailFontSize, weight: .medium))
                    .foregroundStyle(.secondary)
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
