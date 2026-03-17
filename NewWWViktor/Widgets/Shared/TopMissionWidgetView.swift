import SwiftUI
import SwiftData

struct TopMissionWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
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

    private var entry: TopMissionEntry? {
        entries.first
    }

    private var hasMission: Bool {
        !(entry?.task.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var isCompleted: Bool {
        entry?.isCompleted ?? false
    }

    private var subtasks: [TopMissionSubtask] {
        entries.first?.subtasks ?? []
    }

    private var subtasksProgress: Double {
        guard !subtasks.isEmpty else { return 0 }
        return Double(subtasks.filter(\.isCompleted).count) / Double(subtasks.count)
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

            missionRow(fontSize: 14, lineLimit: 2)

            if !subtasks.isEmpty {
                subtasksList(maxItems: 4, fontSize: 9)
                missionProgressView
            }

            Spacer(minLength: 0)
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

            missionRow(fontSize: 18, lineLimit: 3)

            if !subtasks.isEmpty {
                subtasksList(maxItems: 2, fontSize: 11)
                missionProgressView
            }

            Spacer(minLength: 0)
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

            missionRow(fontSize: 22, lineLimit: 4)

            if !subtasks.isEmpty {
                subtasksList(maxItems: 4, fontSize: 12)
                missionProgressView
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func missionRow(fontSize: CGFloat, lineLimit: Int) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Button {
                toggleCompletion()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(checkboxStrokeColor, lineWidth: 1.2)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(checkboxFillColor)
                        )

                    if isCompleted && hasMission {
                        Image(systemName: "checkmark")
                            .font(.system(size: max(fontSize * 0.5, 8), weight: .bold))
                            .foregroundStyle(checkboxCheckmarkColor)
                    }
                }
                .frame(width: checkboxSize(for: fontSize), height: checkboxSize(for: fontSize))
                .contentShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!hasMission)
            .opacity(hasMission ? 1 : 0.55)

            Text(missionText)
                .font(.system(size: fontSize, weight: .bold))
                .foregroundStyle(missionTextColor)
                .strikethrough(isCompleted && hasMission, color: missionTextStrikeColor)
                .lineLimit(lineLimit)
        }
    }

    @ViewBuilder
    private func subtasksList(maxItems: Int, fontSize: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(subtasks.prefix(maxItems).enumerated()), id: \.offset) { index, subtask in
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Button {
                        toggleSubtaskCompletion(at: index)
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .strokeBorder(subtaskCheckboxStrokeColor(for: subtask), lineWidth: 1.0)
                                .background(
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .fill(subtaskCheckboxFillColor(for: subtask))
                                )

                            if subtask.isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: max(fontSize * 0.55, 7), weight: .bold))
                                    .foregroundStyle(checkboxCheckmarkColor)
                            }
                        }
                        .frame(width: max(fontSize, 10), height: max(fontSize, 10))
                        .contentShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    }
                    .buttonStyle(.plain)

                    Text(subtask.title)
                        .font(.system(size: fontSize, weight: .medium))
                        .foregroundStyle(subtaskTextColor(for: subtask))
                        .strikethrough(subtask.isCompleted, color: missionTextStrikeColor)
                        .lineLimit(1)
                }
            }
        }
    }

    private var missionProgressView: some View {
        ProgressView(value: subtasksProgress)
            .progressViewStyle(.linear)
            .tint(.white.opacity(0.85))
    }

    private var missionTextColor: Color {
        hasMission && isCompleted ? .primary.opacity(0.58) : .primary
    }

    private var missionTextStrikeColor: Color {
        .primary.opacity(0.45)
    }

    private var checkboxStrokeColor: Color {
        hasMission && isCompleted ? .white.opacity(0.9) : .white.opacity(0.68)
    }

    private var checkboxFillColor: Color {
        hasMission && isCompleted ? .white.opacity(0.18) : .clear
    }

    private var checkboxCheckmarkColor: Color {
        .white.opacity(0.95)
    }

    private func checkboxSize(for fontSize: CGFloat) -> CGFloat {
        max(fontSize * 0.9, 12)
    }

    private func subtaskTextColor(for subtask: TopMissionSubtask) -> Color {
        subtask.isCompleted ? .secondary.opacity(0.62) : .secondary
    }

    private func subtaskCheckboxStrokeColor(for subtask: TopMissionSubtask) -> Color {
        subtask.isCompleted ? .white.opacity(0.86) : .white.opacity(0.54)
    }

    private func subtaskCheckboxFillColor(for subtask: TopMissionSubtask) -> Color {
        subtask.isCompleted ? .white.opacity(0.14) : .clear
    }

    private func toggleCompletion() {
        guard let entry, hasMission else { return }
        entry.isCompleted.toggle()
        entry.updatedAt = Date()
        persistChanges()
    }

    private func toggleSubtaskCompletion(at index: Int) {
        guard let entry else { return }
        var updatedSubtasks = entry.subtasks
        guard updatedSubtasks.indices.contains(index) else { return }
        updatedSubtasks[index].isCompleted.toggle()
        entry.setSubtasks(updatedSubtasks)
        entry.updatedAt = Date()
        persistChanges()
    }

    private func persistChanges() {
        do {
            try modelContext.save()
        } catch {
            modelContext.rollback()
            print("TopMission toggle completion save error: \(error)")
        }
    }
}
