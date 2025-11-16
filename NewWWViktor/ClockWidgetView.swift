import SwiftUI
import Combine

struct ClockWidgetView: View {
    let widget: WidgetInstance
    @State private var date = Date()
    @StateObject private var locationProvider = LocationProvider()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {

            // Основное время
            Text(formattedTime(date, in: effectiveTimeZone))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(timeColor)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            if widget.showsDate {
                Text(formattedDate(date, in: effectiveTimeZone))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            // Город / зона (без реального Location, по таймзоне — как «Local»)
            if widget.showsLocation {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    Text(locationLabel)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(timer) { output in
            date = output
        }
        .onAppear {
            locationProvider.requestLocationIfNeeded()
        }
        // ВАЖНО: не добавляем .background / .clipShape здесь.
        // Это делает WidgetHostView и превью-карточка, чтобы стиль везде был единый.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formattedTime(date, in: effectiveTimeZone)), \(formattedDate(date, in: effectiveTimeZone)), \(locationLabel)")
    }

    // MARK: - Formatting

    private func formattedTime(_ date: Date, in timeZone: TimeZone) -> String {
        let f = DateFormatter()
        f.locale = .current
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
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        f.timeZone = timeZone
        return f.string(from: date)
    }

    private var locationLabel: String {
        switch widget.location.mode {
        case .current:
            return locationProvider.cityName ?? fallbackCityName()
        case .custom:
            if let city = widget.location.city {
                if let region = widget.location.region, !region.isEmpty {
                    return "\(city), \(region)"
                }
                return city
            }
            return "Выбранный город"
        }
    }

    private var effectiveTimeZone: TimeZone {
        switch widget.location.mode {
        case .current:
            return locationProvider.currentTimeZone ?? .current
        case .custom:
            return widget.location.timeZone
        }
    }

    private func fallbackCityName() -> String {
        let tz = TimeZone.current.identifier
        if let raw = tz.split(separator: "/").last {
            return String(raw).replacingOccurrences(of: "_", with: " ")
        }
            return "Local time"
    }

    private var timeColor: Color {
        WidgetPaletteColor.color(named: widget.mainColorName,
                                 intensity: widget.mainColorIntensity,
                                 fallback: .primary)
    }
}
