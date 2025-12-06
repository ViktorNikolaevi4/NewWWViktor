import SwiftUI
import Combine

struct ClockWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager
    @State private var date = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            timeDisplay

            VStack(alignment: .leading, spacing: 6) {
                if widget.showsDate {
                    HStack(spacing: 5) {
                        Text("\(weekdayString),")
                        Text(formattedDate(date, in: effectiveTimeZone))
                    }
                    .font(dateFont)
                    .foregroundStyle(secondaryColor)
                }

                if widget.showsLocation {
                    Text(locationLabel)
                        .font(locationFont)
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.top, dateTopPadding)
        }
        .padding(contentPadding)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onChange(of: manager.sharedDate) { _, newDate in
            date = newDate
        }
        .onAppear {
            date = manager.sharedDate
            manager.locationProvider.updatePreferredLocale(interfaceLocale)
            manager.locationProvider.requestLocationIfNeeded()
        }
        .onChange(of: localization.selectedLanguage) { _, _ in
            manager.locationProvider.updatePreferredLocale(interfaceLocale)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formattedTime(date, in: effectiveTimeZone)), \(formattedDate(date, in: effectiveTimeZone)), \(locationLabel)")
    }

    private func formattedTime(_ date: Date, in timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = interfaceLocale
        f.timeZone = timeZone
        if widget.prefersTwelveHour {
            f.setLocalizedDateFormatFromTemplate("h:mm a")
        } else {
            f.setLocalizedDateFormatFromTemplate("HH:mm")
        }
        f.timeZone = timeZone
        return f.string(from: date)
    }

    private func formattedDate(_ date: Date, in timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = interfaceLocale
        f.setLocalizedDateFormatFromTemplate("MMM d")
        f.timeZone = timeZone
        return f.string(from: date)
    }

    private func formattedHourMinute(_ date: Date, in timeZone: TimeZone) -> String {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = components.hour, let minute = components.minute else { return "" }

        let minuteString = String(format: "%02d", minute)

        if widget.prefersTwelveHour {
            var normalizedHour = hour % 12
            if normalizedHour == 0 { normalizedHour = 12 }
            return "\(normalizedHour):\(minuteString)"
        } else {
            let hourString = String(format: "%02d", hour)
            return "\(hourString):\(minuteString)"
        }
    }

    private func formattedMeridiem(_ date: Date, in timeZone: TimeZone) -> String? {
        guard widget.prefersTwelveHour else { return nil }
        let f = DateFormatter()
        f.locale = interfaceLocale
        f.timeZone = timeZone
        f.setLocalizedDateFormatFromTemplate("a")
        return f.string(from: date)
    }

    private var locationLabel: String {
        let city: String?
        let region: String?

        switch widget.location.mode {
        case .current:
            city = manager.locationProvider.cityName ?? fallbackCityName()
            region = manager.locationProvider.regionName
        case .custom:
            city = widget.location.city?.isEmpty == false ? widget.location.city : nil
            region = widget.location.region?.isEmpty == false ? widget.location.region : nil
        }

        // Small: только город. Medium/large: добавляем регион/штат, если есть.
        if isSmallWidget {
            return city ?? region ?? localization.text(.widgetSelectedCityFallback)
        } else {
            if let city, let region {
                return "\(city), \(region)"
            }
            return city ?? region ?? localization.text(.widgetSelectedCityFallback)
        }
    }

    private var effectiveTimeZone: TimeZone {
        switch widget.location.mode {
        case .current:
            return manager.locationProvider.currentTimeZone ?? .current
        case .custom:
            return widget.location.timeZone
        }
    }

    private func fallbackCityName() -> String {
        let tz = effectiveTimeZone.identifier
        if let raw = tz.split(separator: "/").last {
            return String(raw).replacingOccurrences(of: "_", with: " ")
        }
        return localization.text(.widgetLocalTimeFallback)
    }

    private var timeColor: Color {
        let name = widget.mainColorName ?? manager.globalPrimaryColorName
        let intensity = widget.mainColorName == nil ? manager.globalPrimaryIntensity : widget.mainColorIntensity
        _ = manager.globalColorsVersion // dependency to refresh when global colors change
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
        Color(red: 1.0, green: 0.84, blue: 0.25)
    }

    private var contentPadding: EdgeInsets {
        EdgeInsets(top: isSmallWidget ? 2 : 4,
                   leading: isSmallWidget ? 4 : 6,
                   bottom: 12,
                   trailing: 12)
    }

    private var dateTopPadding: CGFloat {
        isSmallWidget ? 10 : 8
    }

    private var isSmallWidget: Bool {
        widget.sizeOption == .small
    }

    private var timeFont: Font {
        if isSmallWidget {
            .system(size: 58, weight: .medium, design: .rounded)
        } else {
            .system(size: 68, weight: .medium, design: .rounded)
        }
    }

    private var meridiemFont: Font {
        if isSmallWidget {
            .system(size: 18, weight: .medium, design: .rounded) // small but readable
        } else {
            .system(size: 20, weight: .medium, design: .rounded)
        }
    }

    private var dateFont: Font {
        .system(size: isSmallWidget ? 16 : 15, weight: .medium)
    }

    private var locationFont: Font {
        .system(size: isSmallWidget ? 18 : 16, weight: .semibold)
    }

    private var weekdayString: String {
        let formatter = DateFormatter()
        formatter.locale = interfaceLocale
        formatter.setLocalizedDateFormatFromTemplate("EEE")
        formatter.timeZone = effectiveTimeZone
        return formatter.string(from: date).capitalized
    }

    private var timeDisplay: some View {
        HStack(alignment: .center, spacing: 3) {
            // Only hours and minutes — AM/PM rendered separately
            Text(formattedHourMinute(date, in: effectiveTimeZone))
                .font(timeFont)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(timeColor)
                .contentTransition(.numericText())

            // Small AM/PM when needed
            if let meridiem = formattedMeridiem(date, in: effectiveTimeZone) {
                Text(meridiem.uppercased())
                    .font(meridiemFont)
                    .foregroundStyle(timeColor.opacity(0.8))
                    .offset(y: -8) // slightly higher to match the reference design
                    .contentTransition(.opacity)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5) // apply once to the HStack to avoid ellipsis
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private extension ClockWidgetView {
    var interfaceLocale: Locale {
        localization.selectedLanguage.locale
    }
}
