import SwiftUI

struct BatteryWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

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
        ringView(title: localization.text(.widgetBatteryLabel).uppercased(),
                 valueText: batteryPercentText,
                 valueColor: secondaryColor,
                 showsChargingIndicator: isCharging)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(8)
    }

    private var mediumLayout: some View {
        HStack(spacing: 25) {
            ringView(title: localization.text(.widgetBatteryLabel).uppercased(),
                     valueText: batteryPercentText,
                     valueColor: secondaryColor,
                     showsChargingIndicator: isCharging)

            ringView(title: remainingTitleText,
                     valueText: remainingValueText,
                     valueColor: secondaryColor,
                     progress: secondaryRingProgress,
                     ringColor: primaryColor,
                     titleParts: remainingTitleParts,
                     showsChargingIndicator: isCharging)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private var largeLayout: some View {
        VStack(spacing: 16) {
            HStack(spacing: 26) {
                ringView(title: localization.text(.widgetBatteryLabel).uppercased(),
                         valueText: batteryPercentText,
                         valueColor: secondaryColor,
                         showsChargingIndicator: isCharging)

                ringView(title: remainingTitleText,
                         valueText: remainingValueText,
                         valueColor: secondaryColor,
                         progress: secondaryRingProgress,
                         ringColor: primaryColor,
                         titleParts: remainingTitleParts,
                         showsChargingIndicator: isCharging)
            }

            Spacer(minLength: 0)

            BatteryHistoryChartView(samples: manager.batteryProvider.minuteHistory,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    valueColor: secondaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 110)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 10)
        .padding(.vertical, 12)
    }

    private var extraLargeLayout: some View {
        VStack(spacing: 14) {
            HStack(spacing: 26) {
                ringView(title: localization.text(.widgetBatteryLabel).uppercased(),
                         valueText: batteryPercentText,
                         valueColor: secondaryColor,
                         showsChargingIndicator: isCharging)

                ringView(title: remainingTitleText,
                         valueText: remainingValueText,
                         valueColor: secondaryColor,
                         progress: secondaryRingProgress,
                         ringColor: primaryColor,
                         titleParts: remainingTitleParts,
                         showsChargingIndicator: isCharging)
            }

            Spacer(minLength: 0)

            BatteryHistoryChartView(samples: manager.batteryProvider.minuteHistory,
                                    primaryColor: primaryColor,
                                    secondaryColor: secondaryColor,
                                    valueColor: secondaryColor)
                .frame(maxWidth: .infinity)
                .frame(height: 120)

            BatteryDetailsView(
                maximumCapacityText: maximumCapacityText,
                designCapacityText: designCapacityText,
                batteryHealthText: batteryHealthText,
                optimizationText: optimizationText,
                currentCapacityText: currentCapacityText,
                localization: localization,
                secondaryColor: secondaryColor
            )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }

    private func ringView(title: String,
                          valueText: String,
                          valueColor: Color,
                          progress: Double? = nil,
                          ringColor: Color? = nil,
                          titleParts: [String]? = nil,
                          showsChargingIndicator: Bool = false) -> some View {
        ZStack {
            Circle()
                .stroke(secondaryColor.opacity(0.25), lineWidth: ringLineWidth)

            Circle()
                .trim(from: 0, to: progress ?? batteryProgress)
                .stroke((ringColor ?? primaryColor),
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(valueText)
                    .font(.system(size: valueFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()

                if let titleParts, titleParts.count >= 2 {
                    Text(titleParts[0].uppercased())
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(titleParts[1].uppercased())
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text(title.uppercased())
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .overlay(alignment: .top) {
            if showsChargingIndicator {
                Image(systemName: "bolt.fill")
                    .font(.system(size: ringSize * 0.14, weight: .bold))
                    .foregroundStyle(valueColor)
                    .padding(.top, 4)
            }
        }
        .frame(width: ringSize, height: ringSize)
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

    private var optimizationText: String {
        guard let enabled = manager.batteryProvider.optimizedChargingEnabled else {
            return localization.text(.widgetBatteryEstimateUnavailable)
        }
        return localization.text(enabled ? .widgetBatteryStatusOn : .widgetBatteryStatusOff)
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

private struct BatteryHistoryChartView: View {
    let samples: [BatteryProvider.BatteryMinuteSample]
    let primaryColor: Color
    let secondaryColor: Color
    let valueColor: Color

    @State private var isHovering = false
    @State private var hoverIndex: Int?
    @State private var tooltipSize: CGSize = CGSize(width: 140, height: 40)

    var body: some View {
        GeometryReader { proxy in
            let barWidth: CGFloat = 4
            let barSpacing: CGFloat = 1
            let step = barWidth + barSpacing
            let maxBars = max(1, Int(proxy.size.width / step))
            let windowMinutes = maxBars
            let now = Date()
            let baseMinute = floor(now.timeIntervalSince1970 / 60) * 60
            let stepSeconds: TimeInterval = 60
            let windowDuration: TimeInterval = Double(max(0, windowMinutes - 1)) * stepSeconds
            let startTime = baseMinute - windowDuration
            let visible = minuteWindowSamples(from: startTime,
                                              count: windowMinutes,
                                              stepSeconds: stepSeconds,
                                              samples: samples)

            let base = ZStack(alignment: .topLeading) {
                HStack(alignment: .bottom, spacing: barSpacing) {
                    ForEach(Array(visible.enumerated()), id: \.offset) { index, sample in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(barColor(for: sample))
                            .frame(width: barWidth, height: barHeight(sample: sample, in: proxy.size.height))
                            .overlay {
                                if isHovering, hoverIndex == index {
                                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                                        .stroke(valueColor.opacity(0.6), lineWidth: 1)
                                }
                            }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)

                if let hoverIndex, hoverIndex < visible.count, let sample = visible[hoverIndex] {
                    BatteryHistoryTooltip(sample: sample,
                                          valueColor: valueColor)
                        .background(
                            GeometryReader { tooltipProxy in
                                Color.clear
                                    .preference(key: BatteryTooltipSizeKey.self,
                                                value: tooltipProxy.size)
                            }
                        )
                        .position(x: tooltipPositionX(for: hoverIndex,
                                                      step: step,
                                                      maxWidth: proxy.size.width,
                                                      tooltipWidth: tooltipSize.width),
                                  y: tooltipSize.height / 2 + 6)
                }
            }

#if os(macOS)
            if #available(macOS 13.0, *) {
                base
                    .contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            isHovering = true
                            let index = Int(location.x / step)
                            hoverIndex = clamp(index, min: 0, max: max(0, visible.count - 1))
                        case .ended:
                            isHovering = false
                            hoverIndex = nil
                        }
                    }
            } else {
                base
                    .contentShape(Rectangle())
                    .onHover { hovering in
                        isHovering = hovering
                        if !hovering {
                            hoverIndex = nil
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let index = Int(value.location.x / step)
                                hoverIndex = clamp(index, min: 0, max: max(0, visible.count - 1))
                            }
                            .onEnded { _ in
                                if !isHovering {
                                    hoverIndex = nil
                                }
                            }
                    )
            }
#else
            base
#endif
        }
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.12))
        )
        .onPreferenceChange(BatteryTooltipSizeKey.self) { size in
            if size.width > 0 && size.height > 0 {
                tooltipSize = size
            }
        }
    }

    private func barHeight(sample: BatteryProvider.BatteryMinuteSample, in availableHeight: CGFloat) -> CGFloat {
        let normalized = max(0, min(1, CGFloat(sample.level) / 100))
        return max(4, normalized * (availableHeight - 8))
    }

    private func barHeight(sample: BatteryProvider.BatteryMinuteSample?, in availableHeight: CGFloat) -> CGFloat {
        guard let sample else {
            let placeholder = max(4, (availableHeight - 8) * 0.25)
            return placeholder
        }
        return barHeight(sample: sample, in: availableHeight)
    }

    private func barColor(for sample: BatteryProvider.BatteryMinuteSample?) -> Color {
        guard let sample else { return secondaryColor.opacity(0.25) }
        return sample.isCharging ? primaryColor : secondaryColor.opacity(0.65)
    }

    private func minuteWindowSamples(from startTime: TimeInterval,
                                     count: Int,
                                     stepSeconds: TimeInterval,
                                     samples: [BatteryProvider.BatteryMinuteSample]) -> [BatteryProvider.BatteryMinuteSample?] {
        var lookup: [Int: BatteryProvider.BatteryMinuteSample] = [:]
        for sample in samples {
            let key = Int(sample.date.timeIntervalSince1970)
            lookup[key] = sample
        }
        let sortedMinutes = lookup.keys.sorted()
        var result: [BatteryProvider.BatteryMinuteSample?] = []
        result.reserveCapacity(count)

        for i in 0..<count {
            let time = startTime + (Double(i) * stepSeconds)
            let minute = Int(floor(time / 60) * 60)
            if let sample = lookup[minute], abs(sample.date.timeIntervalSince1970 - time) < 30 {
                result.append(sample)
                continue
            }

            let prev = previousSample(atOrBefore: time, in: sortedMinutes, lookup: lookup)
            let next = nextSample(atOrAfter: time, in: sortedMinutes, lookup: lookup)
            if let prev, let next {
                result.append(interpolatedSample(at: time, previous: prev, next: next))
            } else {
                result.append(nil)
            }
        }
        return result
    }

    private func previousSample(atOrBefore time: TimeInterval,
                                in sortedMinutes: [Int],
                                lookup: [Int: BatteryProvider.BatteryMinuteSample]) -> BatteryProvider.BatteryMinuteSample? {
        let target = Int(floor(time))
        guard let prevMinute = sortedMinutes.last(where: { $0 <= target }) else {
            return nil
        }
        return lookup[prevMinute]
    }

    private func nextSample(atOrAfter time: TimeInterval,
                            in sortedMinutes: [Int],
                            lookup: [Int: BatteryProvider.BatteryMinuteSample]) -> BatteryProvider.BatteryMinuteSample? {
        let target = Int(ceil(time))
        guard let nextMinute = sortedMinutes.first(where: { $0 >= target }) else {
            return nil
        }
        return lookup[nextMinute]
    }

    private func interpolatedSample(at time: TimeInterval,
                                    previous: BatteryProvider.BatteryMinuteSample,
                                    next: BatteryProvider.BatteryMinuteSample) -> BatteryProvider.BatteryMinuteSample {
        let prevTime = previous.date.timeIntervalSince1970
        let nextTime = next.date.timeIntervalSince1970
        let span = max(1, nextTime - prevTime)
        let t = max(0, min(1, (time - prevTime) / span))
        let level = Int((Double(previous.level) + (Double(next.level - previous.level) * t)).rounded())
        let charging: Bool
        if previous.isCharging == next.isCharging {
            charging = previous.isCharging
        } else {
            charging = t < 0.5 ? previous.isCharging : next.isCharging
        }
        return BatteryProvider.BatteryMinuteSample(date: Date(timeIntervalSince1970: time),
                                                   level: level,
                                                   isCharging: charging)
    }

    private func tooltipPositionX(for index: Int,
                                step: CGFloat,
                                maxWidth: CGFloat,
                                tooltipWidth: CGFloat) -> CGFloat {
        let barCenter = CGFloat(index) * step + (step * 0.5)
        let half = tooltipWidth * 0.5
        return min(max(half, barCenter), maxWidth - half)
    }

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        if value < min { return min }
        if value > max { return max }
        return value
    }
}

private struct BatteryHistoryTooltip: View {
    let sample: BatteryProvider.BatteryMinuteSample
    let valueColor: Color

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(Self.formatter.string(from: sample.date))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
            HStack(spacing: 6) {
                Image(systemName: sample.isCharging ? "bolt.fill" : "battery.100")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(valueColor)
                Text("\(sample.level)%")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.6))
        )
    }
}

private struct BatteryDetailsView: View {
    let maximumCapacityText: String
    let designCapacityText: String
    let batteryHealthText: String
    let optimizationText: String
    let currentCapacityText: String
    let localization: LocalizationManager
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            BatteryDetailRow(title: localization.text(.widgetBatteryMaximumCapacity),
                             value: maximumCapacityText,
                             color: secondaryColor)
            BatteryDetailRow(title: localization.text(.widgetBatteryDesignCapacity),
                             value: designCapacityText,
                             color: secondaryColor)
            BatteryDetailRow(title: localization.text(.widgetBatteryHealth),
                             value: batteryHealthText,
                             color: secondaryColor)
            BatteryDetailRow(title: localization.text(.widgetBatteryCurrentCapacity),
                             value: currentCapacityText,
                             color: secondaryColor)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(secondaryColor.opacity(0.9))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BatteryDetailRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundStyle(color.opacity(0.75))
            Spacer()
            Text(value)
                .foregroundStyle(color)
        }
    }
}

private struct BatteryTooltipSizeKey: PreferenceKey {
    static var defaultValue: CGSize = CGSize(width: 140, height: 40)

    static func reduce(value: inout CGSize, nextValue: () -> CGSize) {
        let next = nextValue()
        value = CGSize(width: max(value.width, next.width),
                       height: max(value.height, next.height))
    }
}
