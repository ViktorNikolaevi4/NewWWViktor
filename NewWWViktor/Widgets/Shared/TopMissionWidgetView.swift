import SwiftUI
import SwiftData

struct TopMissionWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var localization: LocalizationManager
    @Query private var entries: [TopMissionEntry]

    init(widget: WidgetInstance) {
        self.widget = widget
        _entries = Query(filter: #Predicate<TopMissionEntry> { $0.widgetID == widget.id })
    }

    private var missionText: String {
        let current = entries.first?.task ?? ""
        let trimmed = current.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? localization.text(.widgetTopMissionTaskPlaceholder) : trimmed
    }

    var body: some View {
        switch widget.sizeOption {
        case .small:
            smallLayout
        case .medium:
            mediumLayout
        case .large:
            largeLayout
        default:
            largeLayout
        }
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.text(.widgetTopMissionTitle))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(missionText)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(3)

            Spacer(minLength: 0)

            missionBadge
        }
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localization.text(.widgetTopMissionTitle))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(localization.text(.widgetTopMissionSubtitle))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(missionText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(3)

            Spacer(minLength: 0)

            missionBadge
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.text(.widgetTopMissionTitle))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(localization.text(.widgetTopMissionSubtitle))
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.secondary)

            Text(missionText)
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.primary)
                .lineLimit(4)

            Spacer(minLength: 0)

            missionBadge
        }
    }

    private var missionBadge: some View {
        Text(localization.text(.widgetTopMissionCTA))
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.2))
            )
    }
}
