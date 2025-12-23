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
        // Rebuild when palette or size changes to avoid keeping stale layout from previous size (e.g., XL -> L).
        .id("\(widget.sizeOption.rawValue)-\(manager.globalColorsVersion)")
        // Disable implicit animation on size switch to avoid transient layouts sticking around.
        .animation(.none, value: widget.sizeOption)
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
        localizedCondition(from: weather.conditionDescription) ?? localization.text(.widgetWeatherPlaceholderCondition)
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

    var pressureValue: (value: String, unit: String?) {
        if let pressure = weather.pressureHPa {
            if localization.selectedLanguage == .russian {
                let mmHg = Int((Double(pressure) * 0.75006).rounded())
                return ("\(mmHg)", "мм рт. ст.")
            }
            return ("\(pressure)", "hPa")
        }
        return ("--", nil)
    }

    func nextSunEventMetric() -> MetricItem? {
        guard weather.sunrise != nil || weather.sunset != nil else { return nil }
        let now = Date()
        let day: TimeInterval = 24 * 60 * 60

        if let sunrise = weather.sunrise, let sunset = weather.sunset {
            if now < sunrise {
                return MetricItem(title: localization.text(.widgetWeatherSunrise),
                                  value: timeText(sunrise),
                                  unit: nil,
                                  icon: "sunrise.fill")
            } else if now < sunset {
                return MetricItem(title: localization.text(.widgetWeatherSunset),
                                  value: timeText(sunset),
                                  unit: nil,
                                  icon: "sunset.fill")
            } else {
                return MetricItem(title: localization.text(.widgetWeatherSunrise),
                                  value: timeText(sunrise.addingTimeInterval(day)),
                                  unit: nil,
                                  icon: "sunrise.fill")
            }
        } else if let sunrise = weather.sunrise {
            return MetricItem(title: localization.text(.widgetWeatherSunrise),
                              value: timeText(sunrise),
                              unit: nil,
                              icon: "sunrise.fill")
        } else if let sunset = weather.sunset {
            if now < sunset {
                return MetricItem(title: localization.text(.widgetWeatherSunset),
                                  value: timeText(sunset),
                                  unit: nil,
                                  icon: "sunset.fill")
            } else {
                return MetricItem(title: localization.text(.widgetWeatherSunrise),
                                  value: timeText(sunset.addingTimeInterval(day)),
                                  unit: nil,
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

    private func localizedCondition(from raw: String?) -> String? {
        guard let raw else { return nil }
        let key = raw.lowercased()

        switch localization.selectedLanguage {
        case .russian:
            if let mapped = conditionTranslationsEnToRu[key] { return mapped }
            if key.contains("mostly") && key.contains("cloud") { return "В основном облачно" }
            if key.contains("partly") && key.contains("cloud") { return "Переменная облачность" }
            if key.contains("cloud") { return "Облачно" }
            if key.contains("clear") || key.contains("sunny") { return "Ясно" }
            if key.contains("rain") || key.contains("shower") { return "Дождь" }
            if key.contains("snow") { return "Снег" }
            if key.contains("sleet") { return "Мокрый снег" }
            if key.contains("thunder") { return "Гроза" }
            if key.contains("fog") { return "Туман" }
            if key.contains("haze") { return "Дымка" }
            if key.contains("wind") { return "Ветрено" }
            return raw
        case .english:
            // Если API вернул русское описание — переведём в английский.
            if containsCyrillic(key) {
                if let mapped = conditionTranslationsRuToEn[key] { return mapped }
                if key.contains("облачно") && key.contains("перем") { return "Partly cloudy" }
                if key.contains("облачно") { return "Cloudy" }
                if key.contains("ясно") { return "Clear" }
                if key.contains("дожд") { return "Rain" }
                if key.contains("снег") { return "Snow" }
                if key.contains("гроза") { return "Thunderstorm" }
                if key.contains("туман") { return "Fog" }
                if key.contains("ветер") { return "Windy" }
            }
            return raw
        }
    }

    private func containsCyrillic(_ text: String) -> Bool {
        text.range(of: "\\p{Cyrillic}", options: .regularExpression) != nil
    }

    private var conditionTranslationsEnToRu: [String: String] {
        [
            "clear": "Ясно",
            "sunny": "Солнечно",
            "mostly clear": "Преимущественно ясно",
            "partly cloudy": "Переменная облачность",
            "mostly cloudy": "В основном облачно",
            "cloudy": "Облачно",
            "overcast": "Пасмурно",
            "fog": "Туман",
            "haze": "Дымка",
            "smoky": "Дым",
            "windy": "Ветрено",
            "breezy": "Лёгкий ветер",
            "drizzle": "Морось",
            "rain": "Дождь",
            "light rain": "Небольшой дождь",
            "heavy rain": "Сильный дождь",
            "showers": "Ливень",
            "rain showers": "Дождевые ливни",
            "snow": "Снег",
            "light snow": "Небольшой снег",
            "heavy snow": "Сильный снег",
            "snow showers": "Снегопад",
            "sleet": "Мокрый снег",
            "freezing rain": "Ледяной дождь",
            "thunderstorms": "Грозы",
            "thunderstorm": "Гроза",
            "isolated thunderstorms": "Местами гроза"
        ]
    }

    private var conditionTranslationsRuToEn: [String: String] {
        [
            "ясно": "Clear",
            "солнечно": "Sunny",
            "в основном облачно": "Mostly cloudy",
            "переменная облачность": "Partly cloudy",
            "облачно": "Cloudy",
            "пасмурно": "Overcast",
            "туман": "Fog",
            "дымка": "Haze",
            "дым": "Smoke",
            "ветрено": "Windy",
            "небольшой дождь": "Light rain",
            "дождь": "Rain",
            "сильный дождь": "Heavy rain",
            "ливень": "Showers",
            "снег": "Snow",
            "небольшой снег": "Light snow",
            "сильный снег": "Heavy snow",
            "снегопад": "Snow showers",
            "мокрый снег": "Sleet",
            "ледяной дождь": "Freezing rain",
            "гроза": "Thunderstorm",
            "местами гроза": "Isolated thunderstorms"
        ]
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
            .foregroundStyle(primaryColor)
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

                    VStack(alignment: .leading, spacing: 4) {
                        Text(formattedHour(entry.date))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(secondaryColor)
                        stylizedWeatherIcon(systemName: entry.symbolName ?? "cloud.fill",
                                            size: 16,
                                            background: 28)
                        Text(displayTemperature(from: entry.temperatureCelsius))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(secondaryColor)
                    }
                    .frame(width: 38, alignment: .leading)
                }
            }
            .padding(.top, 2)
        }
        .padding(.top, 2)
    }

    @ViewBuilder
    func stylizedWeatherIcon(systemName: String, size: CGFloat, background: CGFloat) -> some View {
        let normalizedName = filledCloudSymbolName(systemName)
        let palette = weatherIconPalette(for: normalizedName)
        Image(systemName: normalizedName)
            .symbolRenderingMode(.palette)
            .foregroundStyle(palette[0], palette[1])
            .font(.system(size: size, weight: .semibold))
            .accessibilityHidden(true)
    }

    private func filledCloudSymbolName(_ systemName: String) -> String {
        guard systemName.contains("cloud"), !systemName.contains(".fill") else {
            return systemName
        }
        return systemName + ".fill"
    }

    private func weatherIconPalette(for systemName: String) -> [Color] {
        let name = systemName.lowercased()
        let cloud = Color.white
        let sun = Color(red: 1.0, green: 0.82, blue: 0.2)
        let moon = Color.white
        let rain = Color(red: 0.35, green: 0.65, blue: 0.98)
        let snow = Color(red: 0.75, green: 0.9, blue: 1.0)
        let bolt = Color(red: 1.0, green: 0.8, blue: 0.2)
        let fog = Color.white.opacity(0.7)
        let wind = Color.white.opacity(0.75)

        if name.contains("rain") || name.contains("drizzle") {
            return [cloud, rain]
        }
        if name.contains("snow") || name.contains("sleet") || name.contains("hail") {
            return [cloud, snow]
        }
        if name.contains("bolt") {
            return [cloud, bolt]
        }
        if name.contains("cloud.sun") {
            return [cloud, sun]
        }
        if name.contains("cloud.moon") {
            return [cloud, moon]
        }
        if name.contains("sun") {
            return [sun, sun]
        }
        if name.contains("moon") {
            return [moon, moon]
        }
        if name.contains("fog") || name.contains("haze") || name.contains("smoke") {
            return [fog, fog]
        }
        if name.contains("wind") || name.contains("tornado") {
            return [wind, wind]
        }

        return [cloud, cloud]
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
                                 digitColor: secondaryColor)

                stylizedWeatherIcon(systemName: weatherSymbolName,
                                    size: 18,
                                    background: 30)

            VStack(alignment: .leading, spacing: 0) {
                Text(conditionText)
                    .font(conditionFont)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(highLowText)
                    .font(highLowFont)
                    .foregroundStyle(primaryColor)
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
                                         digitColor: secondaryColor)
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
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(highLowText)
                            .font(highLowFont)
                            .foregroundStyle(primaryColor)
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
                                         digitColor: secondaryColor)
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
                            .lineLimit(2)
                            .multilineTextAlignment(.trailing)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(highLowText)
                            .font(highLowFont)
                            .foregroundStyle(primaryColor)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }

            hourlyForecast

            if !dailyItems.isEmpty {
                Divider()
                    .frame(height: 1)
                    .background(Color.white.opacity(0.18))
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.25),
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
                    .background(Color.white.opacity(0.18))
                    .overlay(
                        LinearGradient(gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.25),
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
                        .foregroundStyle(secondaryColor)
                        .frame(width: 70, alignment: .leading)
                        .lineLimit(1)

                    stylizedWeatherIcon(systemName: entry.symbolName ?? "cloud.fill",
                                        size: 16,
                                        background: 0)

                    Spacer()

                    Text(temperatureText(entry.highCelsius))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(secondaryColor)

                    Text(temperatureText(entry.lowCelsius))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(secondaryColor)
                }
            }
        }
    }

    var extraMetrics: some View {
        var metrics: [MetricItem] = [
            MetricItem(title: localization.text(.widgetWeatherFeelsLike),
                       value: feelsLikeText,
                       unit: nil,
                       icon: "thermometer.medium"),
            MetricItem(title: localization.text(.widgetWeatherPressure),
                       value: pressureValue.value,
                       unit: pressureValue.unit,
                       icon: "gauge.medium"),
            MetricItem(title: localization.text(.widgetWeatherHumidity),
                       value: humidityText,
                       unit: nil,
                       icon: "drop.fill")
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
                            .fill(Color.white.opacity(0.12))
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
                        .background(Color.white.opacity(0.18))
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
                        .foregroundStyle(Color.white.opacity(0.9))
                        .frame(width: 22, alignment: .leading)
                    Text(metric.title)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(primaryColor)
                        .lineLimit(1)
                }
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(metric.value)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                    if let unit = metric.unit {
                        Text(unit)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                    }
                }
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
    let unit: String?
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
