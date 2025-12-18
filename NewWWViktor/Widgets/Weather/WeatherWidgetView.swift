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

    var temperatureText: String {
        if let temperature = weather.temperatureCelsius {
            return "\(temperature)°"
        }
        return "--°"
    }

    var conditionText: String {
        weather.conditionDescription ?? localization.text(.widgetWeatherPlaceholderCondition)
    }

    var highLowText: String {
        if let high = weather.highCelsius, let low = weather.lowCelsius {
            return "H: \(high)° · L: \(low)°"
        }
        return localization.text(.widgetWeatherPlaceholderHiLow)
    }

    var contentPadding: EdgeInsets {
        EdgeInsets(top: 8,
                   leading: 10,
                   bottom: 8,
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
                    VStack(spacing: 6) {
                        Text(formattedHour(entry.date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.primary)
                        Image(systemName: entry.symbolName ?? "cloud.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(primaryColor)
                        Text(entry.temperatureCelsius.map { "\($0)°" } ?? "--°")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(secondaryColor)
                    }
                    .frame(width: 38, alignment: .center)
                }
            }
            .padding(.top, 4)
        }
        .padding(.top, 4)
    }

    func formattedHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = localization.selectedLanguage.locale
        formatter.dateFormat = "ha"
        formatter.timeZone = effectiveTimeZone
        return formatter.string(from: date).lowercased()
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
        VStack(alignment: .leading, spacing: 2) {
            header

            Text(temperatureText)
                .font(temperatureFont)
                .fontWeight(.semibold)
                .foregroundStyle(primaryColor)
                .contentTransition(.numericText())

            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: weatherSymbolName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(primaryColor)
            }

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
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    header
                    Text(temperatureText)
                        .font(temperatureFont)
                        .fontWeight(.semibold)
                        .foregroundStyle(primaryColor)
                        .contentTransition(.numericText())
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Image(systemName: weatherSymbolName)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(primaryColor)
                    VStack(alignment: .trailing, spacing: 2) {
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
