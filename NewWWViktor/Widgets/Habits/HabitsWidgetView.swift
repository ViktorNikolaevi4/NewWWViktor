import SwiftUI

struct HabitsWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    private var streakDays: Int { widget.habitStreakDays }
    private var progressDays: Int { widget.habitProgressDays }
    private let ringLineWidth: CGFloat = 10

    var body: some View {
        VStack(spacing: 8) {
            Text(localization.text(widget.habitKind.titleKey))
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)

            ring

            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.horizontal, 2)

            bottomRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 4)
    }

    private var ring: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .stroke(Color.white.opacity(0.14), lineWidth: ringLineWidth)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(ringGradient,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)

            VStack(spacing: 2) {
                Text("\(progressDays)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(.primary)

                Text(localization.text(.widgetHabitsDaysLabel))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            .offset(y: -18)
        }
        .frame(width: 92, height: 92)
    }

    private var bottomRow: some View {
        HStack(spacing: 8) {
            Button {
                incrementProgress()
            } label: {
                checkmarkBadge
            }
            .buttonStyle(.plain)

            Rectangle()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 14)

            HStack(spacing: 4) {
                Text(localization.text(.widgetHabitsStreakLabel))
                    .foregroundStyle(.secondary)
                Text("\(streakDays)")
                    .foregroundStyle(.primary)
                Text(localization.text(.widgetHabitsDaysLabel))
                    .foregroundStyle(.secondary)
            }
            .font(.system(size: 11, weight: .semibold))

            Spacer(minLength: 0)
        }
    }

    private var checkmarkBadge: some View {
        Image(systemName: "checkmark.circle.fill")
            .foregroundStyle(.green)
            .font(.system(size: 16, weight: .semibold))
    }

    private var ringProgress: Double {
        guard streakDays > 0 else { return 0 }
        return min(1, max(0, Double(progressDays) / Double(streakDays)))
    }

    private func incrementProgress() {
        guard progressDays < streakDays else { return }
        var updated = widget
        updated.habitProgressDays = min(streakDays, progressDays + 1)
        manager.update(updated)
    }

    private var ringGradient: LinearGradient {
        LinearGradient(colors: [
            Color(red: 0.23, green: 0.74, blue: 1.0),
            Color(red: 0.12, green: 0.42, blue: 0.98)
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}
