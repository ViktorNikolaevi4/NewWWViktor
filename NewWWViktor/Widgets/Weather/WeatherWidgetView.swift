import SwiftUI

struct WeatherWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            header

            Text(temperatureText)
                .font(temperatureFont)
                .fontWeight(.semibold)
                .foregroundStyle(primaryColor)
                .contentTransition(.numericText())

       //     Spacer(minLength: 0)

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
        .padding(contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .id(manager.globalColorsVersion) // refresh when palette changes
        .task {
            manager.refreshWeather()
        }
    }
}

private extension WeatherWidgetView {
    var isSmallWidget: Bool {
        widget.sizeOption == .small
    }

    var weather: WeatherSnapshot {
        manager.weatherSnapshot
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
        .system(size: 15, weight: .semibold, design: .rounded)
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
        let weatherCity = manager.weatherSnapshot.city
        if !weatherCity.isEmpty {
            return weatherCity
        }
        if let currentCity = manager.locationProvider.cityName, !currentCity.isEmpty {
            return currentCity
        }
        return localization.text(.widgetWeatherDetailTitle)
    }
}
