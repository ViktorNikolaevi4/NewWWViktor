import SwiftUI
import SwiftData

struct TopMissionWidgetView: View {
    let widget: WidgetInstance
    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [TopMissionEntry]
    @State private var showDeadlineEditor = false
    @State private var draftDeadline = Date()

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

    private var deadlineAt: Date? {
        entries.first?.deadlineAt
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
            sectionTitle(fontSize: 11)

            missionRow(fontSize: 14, lineLimit: 2)

            if !subtasks.isEmpty {
                sectionDivider
                subtasksList(maxItems: 4, fontSize: 9)
                sectionDivider
                missionProgressView
            }

            Spacer(minLength: 0)
        }
    }

    private var mediumLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle(fontSize: 12)

            HStack(alignment: .top, spacing: 10) {
                missionRow(fontSize: 18, lineLimit: 3)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !subtasks.isEmpty {
                    Rectangle()
                        .fill(secondaryColor.opacity(0.18))
                        .frame(width: 1)
                        .padding(.vertical, 2)

                    subtasksList(maxItems: 4, fontSize: 11)
                        .frame(width: 116, alignment: .leading)
                }
            }

            if !subtasks.isEmpty {
                sectionDivider
                missionProgressView
            }

            Spacer(minLength: 0)
        }
    }

    private var largeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionTitle(fontSize: 12)

            missionRow(fontSize: 22, lineLimit: 4)

            if !subtasks.isEmpty {
                sectionDivider
                subtasksList(maxItems: 4, fontSize: 12)
                sectionDivider
                missionProgressView
            }

            if hasMission {
                deadlineSection
            }

            Spacer(minLength: 0)
        }
        .onChange(of: deadlineAt) { _, newValue in
            draftDeadline = newValue ?? Date()
        }
    }

    @ViewBuilder
    private func sectionTitle(fontSize: CGFloat) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "target")
                .font(.system(size: max(fontSize - 1, 10), weight: .semibold))
                .foregroundStyle(primaryColor)

            Text(localization.text(.widgetTopMissionTitle))
                .font(.system(size: fontSize, weight: .semibold))
                .foregroundStyle(secondaryColor)
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
            .tint(primaryColor.opacity(0.9))
    }

    @ViewBuilder
    private var deadlineSection: some View {
        if let deadlineAt {
            Button {
                draftDeadline = deadlineAt
                showDeadlineEditor = true
            } label: {
                deadlineRow(deadlineAt)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDeadlineEditor, arrowEdge: .bottom) {
                deadlineEditorPopover
            }
        } else {
            Button {
                draftDeadline = Date()
                showDeadlineEditor = true
            } label: {
                addDeadlineRow
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDeadlineEditor, arrowEdge: .bottom) {
                deadlineEditorPopover
            }
        }
    }

    private func deadlineRow(_ date: Date) -> some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(primaryColor)

            Text(localization.text(.widgetTopMissionDeadlineTitle))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(secondaryColor)

            Spacer(minLength: 0)

            Text(deadlineText(for: date))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(primaryColor)
                .multilineTextAlignment(.trailing)
        }
    }

    private var addDeadlineRow: some View {
        HStack(spacing: 8) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(primaryColor)

            Text(localization.text(.widgetTopMissionShowDeadline))
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(secondaryColor)

            Spacer(minLength: 0)
        }
    }

    private var deadlineEditorPopover: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.text(.widgetTopMissionDeadlineTitle))
                .font(.system(size: 13, weight: .semibold))

            DatePicker("",
                       selection: $draftDeadline,
                       displayedComponents: [.date, .hourAndMinute])
                .labelsHidden()
                .datePickerStyle(.graphical)

            HStack {
                Button(localization.text(.widgetEisenhowerSave)) {
                    saveDeadline(draftDeadline)
                }
                .buttonStyle(.plain)

                Spacer()

                if deadlineAt != nil {
                    Button(localization.text(.widgetDelete), role: .destructive) {
                        clearDeadline()
                    }
                    .buttonStyle(.plain)
                }

                Button(localization.text(.widgetEisenhowerCancel)) {
                    showDeadlineEditor = false
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 280)
    }

    private var sectionDivider: some View {
        Rectangle()
            .fill(secondaryColor.opacity(0.2))
            .frame(height: 1)
    }

    private var missionTextColor: Color {
        hasMission && isCompleted ? primaryColor.opacity(0.58) : primaryColor
    }

    private var missionTextStrikeColor: Color {
        primaryColor.opacity(0.45)
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
        subtask.isCompleted ? secondaryColor.opacity(0.62) : secondaryColor
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

    private func saveDeadline(_ date: Date) {
        guard let entry else { return }
        entry.deadlineAt = date
        entry.updatedAt = Date()
        persistChanges()
        showDeadlineEditor = false
    }

    private func clearDeadline() {
        guard let entry else { return }
        entry.deadlineAt = nil
        entry.updatedAt = Date()
        persistChanges()
        showDeadlineEditor = false
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

    private func deadlineText(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.setLocalizedDateFormatFromTemplate("d MMM HH:mm")
        return formatter.string(from: date)
    }
}
