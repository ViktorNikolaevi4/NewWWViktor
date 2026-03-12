import SwiftUI

struct TopMissionWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var localization: LocalizationManager

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

            Text(localization.text(.widgetTopMissionTaskPlaceholder))
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

            Text(localization.text(.widgetTopMissionTaskPlaceholder))
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

            Text(localization.text(.widgetTopMissionTaskPlaceholder))
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
