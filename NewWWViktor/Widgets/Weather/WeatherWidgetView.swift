import SwiftUI

struct WeatherWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Group {
            if isSmallWidget {
                smallLayout
            } else {
                mediumLayout
            }
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .id(manager.globalColorsVersion) // refresh when palette changes
        .task {
            manager.refreshWeather(for: widget)
        }
        .onReceive(manager.locationProvider.$currentCoordinate) { coord in
            guard coord != nil else { return }
            guard widget.location.mode == .current else { return }
            manager.refreshWeather(for: widget)
        }
    }
}

private extension WeatherWidgetView {
    var isSmallWidget: Bool {
        widget.sizeOption == .small
    }

    var weather: WeatherSnapshot {
        manager.weatherSnapshot(for: widget)
    }

    func displayTemperatureNumber(from celsius: Int?) -> String {
        guard let celsius else { return "--" }
        if widget.prefersCelsius {
            return "\(celsius)"
        }
        let fahrenheit = Int((Double(celsius) * 9.0 / 5.0 + 32.0).rounded())
        return "\(fahrenheit)"
    }

    func displayTemperature(from celsius: Int?) -> String {
        "\(displayTemperatureNumber(from: celsius))°"
    }

    var temperatureText: String {
        displayTemperature(from: weather.temperatureCelsius)
    }

    var conditionText: String {
        weather.conditionDescription ?? localization.text(.widgetWeatherPlaceholderCondition)
    }

    var highLowText: String {
        if let high = weather.highCelsius, let low = weather.lowCelsius {
            return "H: \(displayTemperatureValue(from: high))° · L: \(displayTemperatureValue(from: low))°"
        }
        return localization.text(.widgetWeatherPlaceholderHiLow)
    }

    func displayTemperatureValue(from celsius: Int) -> Int {
        if widget.prefersCelsius {
            return celsius
        }
        return Int((Double(celsius) * 9.0 / 5.0 + 32.0).rounded())
    }

    var contentPadding: EdgeInsets {
        if isSmallWidget {
            return EdgeInsets(top: 6,
                              leading: 8,
                              bottom: 6,
                              trailing: 6)
        }
        return EdgeInsets(top: 6,
                          leading: 10,
                          bottom: 6,
                          trailing: 8)
    }

    var temperatureFont: Font {
        .system(size: 26, weight: .medium, design: .rounded)
    }

    var conditionFont: Font {
        .system(size: 14, weight: .semibold, design: .rounded)
    }

    var highLowFont: Font {
        .system(size: 12, weight: .medium)
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

    var weatherSymbolName: String {
        weather.symbolName ?? "cloud.sun.fill"
    }

    var hourlyItems: [HourlyWeatherSnapshot] {
        weather.hourly
    }

    var header: some View {
        Text(cityTitle)
            .font(cityFont)
            .foregroundStyle(.primary)
            .lineLimit(1)
            .truncationMode(.tail)
    }

    var cityFont: Font {
        .system(size: 18, weight: .semibold, design: .rounded)
    }

    var cityTitle: String {
        let weatherCity = manager.weatherSnapshot(for: widget).city
        if !weatherCity.isEmpty {
            return weatherCity
        }
        if let currentCity = manager.locationProvider.cityName, !currentCity.isEmpty {
            return currentCity
        }
        return localization.text(.widgetWeatherDetailTitle)
    }

    var hourlyForecast: some View {
        ScrollView(.horizontal, showsIndicators: false) {

            HStack(spacing: 14) {
                ForEach(Array(hourlyItems.prefix(6)).enumerated(), id: \.offset) { item in
                    let entry = item.element

                    VStack(spacing: 4) {
                        Text(formattedHour(entry.date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        stylizedWeatherIcon(systemName: entry.symbolName ?? "cloud.fill",
                                            size: 16,
                                            background: 28)
                        Text(displayTemperature(from: entry.temperatureCelsius))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(secondaryColor)
                    }
                    .frame(width: 38, alignment: .center)
                }
            }
            .padding(.top, 2)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    func stylizedWeatherIcon(systemName: String, size: CGFloat, background: CGFloat) -> some View {
        Image(systemName: systemName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(primaryColor, Color.white.opacity(0.9))
            .font(.system(size: size, weight: .semibold))
            .accessibilityHidden(true)
    }

    func formattedHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = localization.selectedLanguage.locale
        formatter.timeZone = effectiveTimeZone
        if widget.prefersTwelveHour {
            formatter.setLocalizedDateFormatFromTemplate("ha")
            return formatter.string(from: date).lowercased()
        } else {
            formatter.setLocalizedDateFormatFromTemplate("H")
            return formatter.string(from: date)
        }
    }

    var effectiveTimeZone: TimeZone {
        switch widget.location.mode {
        case .custom:
            return widget.location.timeZone
        case .current:
            return manager.locationProvider.currentTimeZone ?? .current
        }
    }

    var smallLayout: some View {
        VStack(alignment: .leading, spacing: 1) {
            header

            TemperatureValueView(valueText: displayTemperatureNumber(from: weather.temperatureCelsius),
                                 baseSize: 26,
                                 digitWeight: .regular,
                                 design: .rounded,
                                 digitColor: primaryColor)

            stylizedWeatherIcon(systemName: weatherSymbolName,
                                size: 18,
                                background: 30)

            VStack(alignment: .leading, spacing: 0) {
                Text(conditionText)
                    .font(conditionFont)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text(highLowText)
                    .font(highLowFont)
                    .foregroundStyle(secondaryColor)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }

    var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    header
                    TemperatureValueView(valueText: displayTemperatureNumber(from: weather.temperatureCelsius),
                                         baseSize: 26,
                                         digitWeight: .regular,
                                         design: .rounded,
                                         digitColor: primaryColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    stylizedWeatherIcon(systemName: weatherSymbolName,
                                        size: 20,
                                        background: 34)
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(conditionText)
                            .font(conditionFont)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                            .truncationMode(.tail)

                        Text(highLowText)
                            .font(highLowFont)
                            .foregroundStyle(secondaryColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }

            hourlyForecast
        }
    }
}

private struct TemperatureValueView: View {
    let valueText: String
    let baseSize: CGFloat
    let digitWeight: Font.Weight
    let design: Font.Design
    let digitColor: Color

    var body: some View {
        Text(valueText)
            .font(.system(size: baseSize * 1.7, weight: digitWeight, design: design))
            .foregroundStyle(digitColor)
            .monospacedDigit()
            .contentTransition(.numericText())
            .accessibilityLabel(valueText)
    }
}
