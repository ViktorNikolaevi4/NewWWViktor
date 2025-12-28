import SwiftUI

struct BatteryWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Group {
            if widget.sizeOption == .medium {
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
                 valueColor: secondaryColor)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(8)
    }

    private var mediumLayout: some View {
        HStack(spacing: 25) {
            ringView(title: localization.text(.widgetBatteryLabel).uppercased(),
                     valueText: batteryPercentText,
                     valueColor: secondaryColor)

            ringView(title: remainingTitleText,
                     valueText: remainingValueText,
                     valueColor: secondaryColor,
                     progress: remainingProgress,
                     ringColor: primaryColor,
                     titleParts: remainingTitleParts)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
    }

    private func ringView(title: String,
                          valueText: String,
                          valueColor: Color,
                          progress: Double? = nil,
                          ringColor: Color? = nil,
                          titleParts: [String]? = nil) -> some View {
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
        widget.sizeOption == .medium ? 108 : 102
    }

    private var ringLineWidth: CGFloat {
        widget.sizeOption == .medium ? 11 : 10
    }

    private var valueFontSize: CGFloat {
        widget.sizeOption == .medium ? 22 : 26
    }

    private var titleFontSize: CGFloat {
        widget.sizeOption == .medium ? 10 : 11
    }
}
