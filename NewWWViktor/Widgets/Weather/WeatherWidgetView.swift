import SwiftUI

struct WeatherWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Group {
            if isSmallWidget {
                smallLayout
            } else if isLargeWidget {
                largeLayout
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

    var highLowPair: (Int?, Int?) {
        (weather.highCelsius, weather.lowCelsius)
    }

    var feelsLikeText: String {
        displayTemperature(from: weather.feelsLikeCelsius)
    }

    var humidityText: String {
        if let humidity = weather.humidityPercent {
            return "\(humidity)%"
        }
        return "--"
    }

    var pressureText: String {
        if let pressure = weather.pressureHPa {
            return "\(pressure) hPa"
        }
        return "--"
    }

    func nextSunEventMetric() -> MetricItem? {
        guard weather.sunrise != nil || weather.sunset != nil else { return nil }
        let now = Date()
        let day: TimeInterval = 24 * 60 * 60

        if let sunrise = weather.sunrise, let sunset = weather.sunset {
            if now < sunrise {
                return MetricItem(title: localization.text(.widgetWeatherSunrise),
                                  value: timeText(sunrise),
                                  icon: "sunrise.fill")
            } else if now < sunset {
                return MetricItem(title: localization.text(.widgetWeatherSunset),
                                  value: timeText(sunset),
                                  icon: "sunset.fill")
            } else {
                return MetricItem(title: localization.text(.widgetWeatherSunrise),
                                  value: timeText(sunrise.addingTimeInterval(day)),
                                  icon: "sunrise.fill")
            }
        } else if let sunrise = weather.sunrise {
            return MetricItem(title: localization.text(.widgetWeatherSunrise),
                              value: timeText(sunrise),
                              icon: "sunrise.fill")
        } else if let sunset = weather.sunset {
            if now < sunset {
                return MetricItem(title: localization.text(.widgetWeatherSunset),
                                  value: timeText(sunset),
                                  icon: "sunset.fill")
            } else {
                return MetricItem(title: localization.text(.widgetWeatherSunrise),
                                  value: timeText(sunset.addingTimeInterval(day)),
                                  icon: "sunrise.fill")
            }
        }
        return nil
    }

    func timeText(_ date: Date?) -> String {
        guard let date else { return "--:--" }
        let formatter = DateFormatter()
        formatter.locale = localization.selectedLanguage.locale
        formatter.timeZone = effectiveTimeZone
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    var highLowText: String {
        if let high = highLowPair.0, let low = highLowPair.1 {
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
                              leading: 6, // move content slightly left
                              bottom: 6,
                              trailing: 8)
        }
        return EdgeInsets(top: 8,
                          leading: 8, // move content slightly left
                          bottom: 8,
                          trailing: 12)
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

    var dailyItems: [DailyWeatherSnapshot] {
        weather.daily
    }

    var isLargeWidget: Bool {
        widget.sizeOption == .large || widget.sizeOption == .extraLarge
    }

    var isExtraLarge: Bool {
        widget.sizeOption == .extraLarge
    }

    var hourlyDisplayLimit: Int {
        switch widget.sizeOption {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 10
        case .extraLarge:
            return 12
        }
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
                ForEach(Array(hourlyItems.prefix(hourlyDisplayLimit)).enumerated(), id: \.offset) { item in
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

    func formattedDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = localization.selectedLanguage.locale
        formatter.timeZone = effectiveTimeZone
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }

    func formattedDayFull(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = localization.selectedLanguage.locale
        formatter.timeZone = effectiveTimeZone
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    func temperatureText(_ value: Int?) -> String {
        guard let value else { return "--" }
        return displayTemperature(from: value)
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

    var largeLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    header
                    TemperatureValueView(valueText: displayTemperatureNumber(from: weather.temperatureCelsius),
                                         baseSize: 28,
                                         digitWeight: .regular,
                                         design: .rounded,
                                         digitColor: primaryColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    stylizedWeatherIcon(systemName: weatherSymbolName,
                                        size: 24,
                                        background: 38)
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

            if !dailyItems.isEmpty {
                Divider()
                    .frame(height: 1)
                    .background(primaryColor.opacity(0.20))
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [
                            .clear,
                            primaryColor.opacity(0.35),
                            .clear
                        ]), startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.horizontal, -4)
                    .opacity(0.85)
                dailyForecast
            }

            if isExtraLarge {
                Spacer(minLength: 0) // push metrics closer to bottom in XL
                Divider()
                    .frame(height: 1)
                    .background(primaryColor.opacity(0.20))
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [
                            .clear,
                            primaryColor.opacity(0.35),
                            .clear
                        ]), startPoint: .leading, endPoint: .trailing)
                    )
                    .padding(.horizontal, -4)
                    .opacity(0.85)
                extraMetrics
            }
        }
    }

    var dailyForecast: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(dailyItems.prefix(5)).enumerated(), id: \.offset) { item in
                let entry = item.element
                HStack(spacing: 10) {
                    Text(formattedDay(entry.date))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .frame(width: 70, alignment: .leading)
                        .lineLimit(1)

                    stylizedWeatherIcon(systemName: entry.symbolName ?? "cloud.fill",
                                        size: 16,
                                        background: 0)

                    Spacer()

                    Text(temperatureText(entry.highCelsius))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)

                    Text(temperatureText(entry.lowCelsius))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(secondaryColor)
                }
            }
        }
    }

    var extraMetrics: some View {
        var metrics: [MetricItem] = [
            MetricItem(title: localization.text(.widgetWeatherFeelsLike), value: feelsLikeText, icon: "thermometer.medium"),
            MetricItem(title: localization.text(.widgetWeatherPressure), value: pressureText, icon: "gauge.medium"),
            MetricItem(title: localization.text(.widgetWeatherHumidity), value: humidityText, icon: "drop.fill")
        ]
        if let sun = nextSunEventMetric() {
            metrics.append(sun)
        }

        let rows = stride(from: 0, to: metrics.count, by: 2).map { idx -> [MetricItem] in
            Array(metrics[idx..<min(idx + 2, metrics.count)])
        }

        return VStack(spacing: 0) {
            ForEach(rows.indices, id: \.self) { rowIndex in
                let row = rows[rowIndex]
                HStack(alignment: .center, spacing: 0) {
                    metricCell(row.first, alignment: .leading)

                    if row.count == 2 {
                        Rectangle()
                            .fill(primaryColor.opacity(0.12))
                            .frame(width: 1, height: 32)
                            .padding(.horizontal, 6)
                        metricCell(row.last, alignment: .leading)
                    } else {
                        Spacer(minLength: 0)
                    }
                }
                .padding(.vertical, 8)

                if rowIndex != rows.count - 1 {
                    Divider()
                        .frame(height: 1)
                        .background(primaryColor.opacity(0.18))
                        .padding(.vertical, 6)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func metricCell(_ metric: MetricItem?, alignment: Alignment = .leading) -> some View {
        if let metric {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: metric.icon)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(primaryColor)
                        .frame(width: 22, alignment: .leading)
                    Text(metric.title)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                }
                Text(metric.value)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: alignment)
        } else {
            Spacer()
        }
    }
}

private struct MetricItem {
    let title: String
    let value: String
    let icon: String
}

private struct TemperatureValueView: View {
    let valueText: String
    let baseSize: CGFloat
    let digitWeight: Font.Weight
    let design: Font.Design
    let digitColor: Color

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(valueText)
                .font(.system(size: baseSize * 1.7, weight: digitWeight, design: design))
                .foregroundStyle(digitColor)
                .monospacedDigit()
                .contentTransition(.numericText())
            Text("°")
                .font(.system(size: baseSize * 1.1, weight: .semibold, design: design))
                .foregroundStyle(digitColor)
                .baselineOffset(baseSize * 0.6) // nudge degree further downward/right
        }
        .accessibilityLabel("\(valueText)°")
    }
}
