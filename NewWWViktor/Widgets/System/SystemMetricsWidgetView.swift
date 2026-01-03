import SwiftUI

struct SystemMetricsWidgetView: View {
    let widget: WidgetInstance
    @ObservedObject var metrics: SystemMetricsProvider
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        let layout = SystemMetricsLayout(sizeOption: widget.sizeOption)
        VStack(alignment: .leading, spacing: layout.rowSpacing) {
            SystemUsageRow(title: localization.text(.widgetSystemCPU),
                           percent: metrics.cpuUsage,
                           detail: nil,
                           color: Color(hex: 0xF7B731),
                           layout: layout)
            SystemUsageRow(title: localization.text(.widgetSystemRAM),
                           percent: usagePercent(used: metrics.memoryUsed, total: metrics.memoryTotal),
                           detail: usageDetail(used: metrics.memoryUsed, total: metrics.memoryTotal),
                           color: Color(hex: 0x5CD0FF),
                           layout: layout)
            SystemUsageRow(title: localization.text(.widgetSystemDisk),
                           percent: usagePercent(used: metrics.diskUsed, total: metrics.diskTotal),
                           detail: usageDetail(used: metrics.diskUsed, total: metrics.diskTotal),
                           color: Color(hex: 0xA78BFA),
                           layout: layout)
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
    let ringSize: CGFloat
    let ringLineWidth: CGFloat
    let valueFontSize: CGFloat
    let titleFontSize: CGFloat
    let detailFontSize: CGFloat
    let rowSpacing: CGFloat
    let rowPadding: CGFloat

    init(sizeOption: WidgetSizeOption) {
        switch sizeOption {
        case .small:
            ringSize = 26
            ringLineWidth = 4
            valueFontSize = 12
            titleFontSize = 11
            detailFontSize = 9
            rowSpacing = 10
            rowPadding = 6
        case .medium:
            ringSize = 30
            ringLineWidth = 4
            valueFontSize = 13
            titleFontSize = 12
            detailFontSize = 10
            rowSpacing = 12
            rowPadding = 8
        case .large, .extraLarge:
            ringSize = 34
            ringLineWidth = 5
            valueFontSize = 14
            titleFontSize = 12
            detailFontSize = 10
            rowSpacing = 12
            rowPadding = 8
        }
    }
}

private struct SystemUsageRow: View {
    let title: String
    let percent: Double?
    let detail: String?
    let color: Color
    let layout: SystemMetricsLayout

    var body: some View {
        HStack(spacing: 10) {
            SystemUsageRing(progress: percent ?? 0,
                            color: color,
                            size: layout.ringSize,
                            lineWidth: layout.ringLineWidth)

            VStack(alignment: .leading, spacing: 2) {
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
            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
    }

    private var percentText: String {
        guard let percent else { return "—" }
        return "\(Int((percent * 100).rounded()))%"
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
