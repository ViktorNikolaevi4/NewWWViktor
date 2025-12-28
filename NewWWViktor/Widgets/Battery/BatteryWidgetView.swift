import SwiftUI

struct BatteryWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        ringView
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding(8)
        .onAppear {
            manager.batteryProvider.refresh()
        }
        .onChange(of: manager.sharedDate) { _, _ in
            manager.batteryProvider.refresh()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(batteryPercentText), \(localization.text(.widgetBatteryLabel))")
    }

    private var ringView: some View {
        ZStack {
            Circle()
                .stroke(secondaryColor.opacity(0.25), lineWidth: ringLineWidth)

            Circle()
                .trim(from: 0, to: batteryProgress)
                .stroke(primaryColor, style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(batteryPercentText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(secondaryColor)
                    .monospacedDigit()

                Text(localization.text(.widgetBatteryLabel).uppercased())
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
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
        102
    }

    private var ringLineWidth: CGFloat {
        10
    }
}
