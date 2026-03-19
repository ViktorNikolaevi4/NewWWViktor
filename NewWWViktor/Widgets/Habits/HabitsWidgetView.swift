import SwiftUI
import SwiftData

struct HabitsWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [HabitEntry]
    @Query private var customHabits: [CustomHabit]

    init(widget: WidgetInstance) {
        self.widget = widget
        _entries = Query(filter: #Predicate<HabitEntry> { $0.widgetID == widget.id })
        _customHabits = Query()
    }

    private var habitEntry: HabitEntry? { entries.first }
    private var habitKind: HabitKind { habitEntry?.habitKind ?? .drinkWater }
    private var streakDays: Int { habitEntry?.streakDays ?? 0 }
    private var progressDays: Int { habitEntry?.progressDays ?? 0 }
    private let ringLineWidth: CGFloat = 10

    var body: some View {
        VStack(spacing: 8) {
            Text(habitTitle)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(primaryColor)

            ring

            Divider()
                .background(secondaryColor.opacity(0.2))
                .padding(.horizontal, 2)

            bottomRow
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .padding(.top, 4)
        .onAppear(perform: ensureHabitEntry)
    }

    private var ring: some View {
        ZStack(alignment: .bottom) {
            Circle()
                .stroke(secondaryColor.opacity(0.22), lineWidth: ringLineWidth)

            Circle()
                .trim(from: 0, to: ringProgress)
                .stroke(ringGradient,
                        style: StrokeStyle(lineWidth: ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.black.opacity(0.18), radius: 4, x: 0, y: 2)

            VStack(spacing: 2) {
                Text("\(progressDays)")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(primaryColor)

                Text(localization.text(.widgetHabitsDaysLabel))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(secondaryColor)
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
                .fill(secondaryColor.opacity(0.2))
                .frame(width: 1, height: 14)

            HStack(spacing: 4) {
                Text(localization.text(.widgetHabitsStreakLabel))
                    .foregroundStyle(secondaryColor)
                Text("\(streakDays)")
                    .foregroundStyle(primaryColor)
                Text(localization.text(.widgetHabitsDaysLabel))
                    .foregroundStyle(secondaryColor)
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
        guard streakDays > 0 else { return }
        guard let entry = habitEntry else {
            ensureHabitEntry()
            return
        }
        if entry.progressDays < streakDays {
            entry.progressDays = min(streakDays, entry.progressDays + 1)
            entry.updatedAt = Date()
        }
    }

    private func ensureHabitEntry() {
        guard habitEntry == nil else { return }
        let entry = HabitEntry(widgetID: widget.id)
        modelContext.insert(entry)
    }

    private var habitTitle: String {
        if let customID = habitEntry?.customHabitID,
           let custom = customHabits.first(where: { $0.id == customID }) {
            return custom.title
        }
        return localization.text(habitKind.titleKey)
    }

    private var ringGradient: LinearGradient {
        LinearGradient(colors: [
            primaryColor,
            secondaryColor
        ], startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    private var primaryColor: Color {
        let name = widget.mainColorName ?? manager.globalPrimaryColorName
        let intensity = widget.mainColorName == nil ? manager.globalPrimaryIntensity : widget.mainColorIntensity
        return WidgetPaletteColor.color(named: name, intensity: intensity, fallback: .primary)
    }

    private var secondaryColor: Color {
        let name = widget.secondaryColorName ?? manager.globalSecondaryColorName
        let intensity = widget.secondaryColorName == nil ? manager.globalSecondaryIntensity : widget.secondaryColorIntensity
        return WidgetPaletteColor.color(named: name, intensity: intensity, fallback: .secondary)
    }
}
