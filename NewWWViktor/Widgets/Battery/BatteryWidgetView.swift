import SwiftUI

struct BatteryWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager
    private var metrics: BatteryWidgetMetrics { BatteryWidgetMetrics(sizeOption: widget.sizeOption) }

    var body: some View {
        Group {
            if widget.sizeOption == .extraLarge {
                extraLargeLayout
            } else if widget.sizeOption == .large {
                largeLayout
            } else if widget.sizeOption == .medium {
                mediumLayout
            } else {
                smallLayout
            }
        }
        .onAppear {
            manager.batteryProvider.refresh()
        }
        .onChange(of: manager.sharedDate) { _, _ in
            manager.batteryProvider.refresh()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var smallLayout: some View {
        batteryRing
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(8)
    }

    private var mediumLayout: some View {
        HStack(spacing: 25) {
            batteryRing
            remainingRing
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var largeLayout: some View {
        VStack(spacing: metrics.layoutSpacingLarge) {
            HStack(spacing: 26) {
                batteryRing
                remainingRing
            }

            Spacer(minLength: 0)

            BatteryHistoryChartView(samples: manager.batteryProvider.minuteHistory,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    valueColor: secondaryColor,
                                    cornerRadius: metrics.chartCornerRadius)
                .frame(maxWidth: .infinity)
                .frame(height: metrics.chartHeightLarge)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(metrics.paddingLarge)
    }

    private var extraLargeLayout: some View {
        VStack(spacing: metrics.layoutSpacingExtraLarge) {
            HStack(spacing: 26) {
                batteryRing
                remainingRing
            }

            Spacer(minLength: 0)

            BatteryHistoryChartView(samples: manager.batteryProvider.minuteHistory,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    valueColor: secondaryColor,
                                    cornerRadius: metrics.chartCornerRadius)
                .frame(maxWidth: .infinity)
                .frame(height: metrics.chartHeightExtraLarge)

            BatteryDetailsView(items: detailItems,
                               secondaryColor: secondaryColor)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(metrics.paddingExtraLarge)
    }

    private var batteryRing: some View {
        BatteryRingView(title: localization.text(.widgetBatteryLabel).uppercased(),
                        valueText: batteryPercentText,
                        valueColor: secondaryColor,
                        progress: batteryProgress,
                        ringColor: primaryColor,
                        titleParts: nil,
                        showsChargingIndicator: isCharging,
                        metrics: metrics,
                        secondaryColor: secondaryColor)
    }

    private var remainingRing: some View {
        BatteryRingView(title: remainingTitleText,
                        valueText: remainingValueText,
                        valueColor: secondaryColor,
                        progress: secondaryRingProgress,
                        ringColor: primaryColor,
                        titleParts: remainingTitleParts,
                        showsChargingIndicator: isCharging,
                        metrics: metrics,
                        secondaryColor: secondaryColor)
    }

    private var detailItems: [BatteryDetailItem] {
        [
            BatteryDetailItem(title: localization.text(.widgetBatteryMaximumCapacity),
                              value: maximumCapacityText),
            BatteryDetailItem(title: localization.text(.widgetBatteryDesignCapacity),
                              value: designCapacityText),
            BatteryDetailItem(title: localization.text(.widgetBatteryHealth),
                              value: batteryHealthText),
            BatteryDetailItem(title: localization.text(.widgetBatteryCurrentCapacity),
                              value: currentCapacityText)
        ]
    }

    private var batteryProgress: Double {
        guard let level = manager.batteryProvider.batteryLevel else { return 0 }
        return min(1, max(0, Double(level) / 100.0))
    }

    private var batteryPercentText: String {
        guard let level = manager.batteryProvider.batteryLevel else {
            return localization.text(.widgetPlaceholderDash)
        }
        return "\(level)%"
    }

    private var remainingTitleParts: [String] {
        let text: String
        if manager.batteryProvider.remainingTimeMinutes == nil {
            text = localization.text(.widgetBatteryEstimateUnavailable)
        } else if isCharging {
            text = localization.text(.widgetBatteryTimeToFull)
        } else {
            text = localization.text(.widgetBatteryRemainingLabel)
        }
        let parts = text.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        if parts.count >= 2 {
            return parts.map(String.init)
        }
        return [text]
    }

    private var remainingTitleText: String {
        remainingTitleParts.joined(separator: " ")
    }

    private var remainingValueText: String {
        guard let minutes = manager.batteryProvider.remainingTimeMinutes else {
            return localization.text(.widgetPlaceholderDash)
        }
        let hours = Double(minutes) / 60.0
        return String(format: "%.1fч", hours)
    }

    private var remainingProgress: Double {
        manager.batteryProvider.remainingTimeProgress ?? 0
    }

    private var secondaryRingProgress: Double {
        isCharging ? batteryProgress : remainingProgress
    }

    private var maximumCapacityText: String {
        guard let percent = manager.batteryProvider.maximumCapacityPercent else {
            return localization.text(.widgetBatteryEstimateUnavailable)
        }
        return "\(percent)%"
    }

    private var currentCapacityText: String {
        guard let current = manager.batteryProvider.currentCapacityMah,
              let maxCapacity = manager.batteryProvider.maxCapacityMah else {
            return localization.text(.widgetBatteryEstimateUnavailable)
        }
        return "\(formatMah(current)) / \(formatMah(maxCapacity)) mAh"
    }

    private var designCapacityText: String {
        guard let design = manager.batteryProvider.designCapacityMah else {
            return localization.text(.widgetBatteryEstimateUnavailable)
        }
        return "\(formatMah(design)) mAh"
    }

    private var batteryHealthText: String {
        guard let percent = manager.batteryProvider.maximumCapacityPercent else {
            return localization.text(.widgetBatteryHealthUnknown)
        }
        return "\(percent)%"
    }

    private func formatMah(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = " "
        formatter.usesGroupingSeparator = true
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private var isCharging: Bool {
        manager.batteryProvider.isCharging == true
    }

    private var accessibilityLabel: String {
        if widget.sizeOption == .medium {
            let remainingTitle = remainingTitleParts.joined(separator: " ")
            return "\(batteryPercentText), \(remainingTitle): \(remainingValueText)"
        }
        return "\(batteryPercentText), \(localization.text(.widgetBatteryLabel))"
    }

    private var primaryColor: Color {
        let name = widget.mainColorName ?? manager.globalPrimaryColorName
        let intensity = widget.mainColorName == nil ? manager.globalPrimaryIntensity : widget.mainColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: highlightColor)
    }

    private var secondaryColor: Color {
        let name = widget.secondaryColorName ?? manager.globalSecondaryColorName
        let intensity = widget.secondaryColorName == nil ? manager.globalSecondaryIntensity : widget.secondaryColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: .secondary)
    }

    private var highlightColor: Color {
        Color(red: 0.36, green: 0.86, blue: 0.36)
    }

    private var ringSize: CGFloat {
        switch widget.sizeOption {
        case .small:
            return 102
        case .medium:
            return 108
        case .large:
            return 120
        case .extraLarge:
            return 120
        }
    }

    private var ringLineWidth: CGFloat {
        switch widget.sizeOption {
        case .small:
            return 10
        case .medium:
            return 11
        case .large:
            return 12
        case .extraLarge:
            return 12
        }
    }

    private var valueFontSize: CGFloat {
        switch widget.sizeOption {
        case .small:
            return 26
        case .medium:
            return 22
        case .large:
            return 24
        case .extraLarge:
            return 24
        }
    }

    private var titleFontSize: CGFloat {
        switch widget.sizeOption {
        case .small:
            return 11
        case .medium:
            return 10
        case .large:
            return 10
        case .extraLarge:
            return 10
        }
    }
}
