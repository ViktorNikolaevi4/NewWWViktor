import SwiftUI
import Combine

struct ClockWidgetView: View {
    @State private var date = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Верхний служебный заголовок (как у системных виджетов)
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text("Clock")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Основное время
            Text(formattedTime(date))
                .font(.system(size: 40, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.7)
                .lineLimit(1)

            // Дата
            Text(formattedDate(date))
                .font(.footnote)
                .foregroundStyle(.secondary)

            // Город / зона (без реального Location, по таймзоне — как «Local»)
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(currentCity())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onReceive(timer) { output in
            date = output
        }
        // ВАЖНО: не добавляем .background / .clipShape здесь.
        // Это делает WidgetHostView и превью-карточка, чтобы стиль везде был единый.
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(formattedTime(date)), \(formattedDate(date)), \(currentCity())")
    }

    // MARK: - Formatting

    private func formattedTime(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: date)
    }

    private func formattedDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = .current
        f.setLocalizedDateFormatFromTemplate("EEEE, MMM d")
        return f.string(from: date)
    }

    private func currentCity() -> String {
        let tz = TimeZone.current.identifier
        if let raw = tz.split(separator: "/").last {
            return String(raw).replacingOccurrences(of: "_", with: " ")
        }
        return "Local time"
    }
}
