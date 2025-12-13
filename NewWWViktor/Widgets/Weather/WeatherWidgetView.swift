import SwiftUI

struct WeatherWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: isSmallWidget ? 10 : 14) {
            header

            HStack(alignment: .firstTextBaseline, spacing: isSmallWidget ? 6 : 8) {
                Text("23°")
                    .font(temperatureFont)
                    .fontWeight(.semibold)
                    .foregroundStyle(primaryColor)
                    .contentTransition(.numericText())
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .id(manager.globalColorsVersion) // refresh when palette changes
    }
}

private extension WeatherWidgetView {
    var isSmallWidget: Bool {
        widget.sizeOption == .small
    }

    var contentPadding: EdgeInsets {
        EdgeInsets(top: isSmallWidget ? 4 : 8,
                   leading: isSmallWidget ? 6 : 10,
                   bottom: 8,
                   trailing: 8)
    }

    var temperatureFont: Font {
        isSmallWidget
        ? .system(size: 23, weight: .medium, design: .rounded)
        : .system(size: 28, weight: .medium, design: .rounded)
    }

    var primaryColor: Color {
        let name = widget.mainColorName ?? manager.globalPrimaryColorName
        let intensity = widget.mainColorName == nil ? manager.globalPrimaryIntensity : widget.mainColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: Color(red: 1.0, green: 0.84, blue: 0.25))
    }

    var secondaryColor: Color {
        let name = widget.secondaryColorName ?? manager.globalSecondaryColorName
        let intensity = widget.secondaryColorName == nil ? manager.globalSecondaryIntensity : widget.secondaryColorIntensity
        _ = manager.globalColorsVersion
        return WidgetPaletteColor.color(named: name,
                                        intensity: intensity,
                                        fallback: .secondary)
    }

    var header: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [primaryColor, primaryColor.opacity(0.65)],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing))
                    .frame(width: isSmallWidget ? 34 : 40, height: isSmallWidget ? 34 : 40)
                    .shadow(color: primaryColor.opacity(0.28), radius: 10, x: 0, y: 8)

                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: isSmallWidget ? 16 : 18, weight: .semibold))
                    .foregroundStyle(.black.opacity(0.85))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(localization.text(.widgetWeatherDetailTitle))
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(localization.text(.widgetCategoryLabel))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(secondaryColor.opacity(0.9))
            }

            Spacer(minLength: 0)
        }
    }
}
