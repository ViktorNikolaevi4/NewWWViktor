import SwiftUI

struct EisenhowerTaskEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var localization: LocalizationManager

    let state: EisenhowerTaskEditorState
    let onSave: (EisenhowerTaskEditorState, String, EisenhowerQuadrant, Bool) -> Void

    @State private var title: String = ""
    @State private var quadrant: EisenhowerQuadrant = .importantNotUrgent
    @State private var isDone: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            Text(titleText)
                .font(.system(size: 16, weight: .semibold))

            TextField(localization.text(.widgetEisenhowerTaskTitlePlaceholder), text: $title)
                .textFieldStyle(.roundedBorder)

            Picker(localization.text(.widgetEisenhowerQuadrantLabel), selection: $quadrant) {
                ForEach(EisenhowerQuadrant.allCases, id: \.id) { option in
                    Text(quadrantLabel(option))
                        .tag(option)
                }
            }
            .pickerStyle(.menu)

            Toggle(localization.text(.widgetEisenhowerDone), isOn: $isDone)

            HStack(spacing: 12) {
                Button(localization.text(.widgetEisenhowerCancel)) {
                    dismiss()
                }
                .buttonStyle(.plain)

                Spacer()

                Button(localization.text(.widgetEisenhowerSave)) {
                    onSave(state, title.trimmed, quadrant, isDone)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(title.trimmed.isEmpty)
            }
        }
        .padding(16)
        .frame(width: 360)
        .onAppear(perform: loadInitialState)
    }

    private var titleText: String {
        switch state {
        case .add:
            return localization.text(.widgetEisenhowerAddTask)
        case .edit:
            return localization.text(.widgetEisenhowerEditTask)
        }
    }

    private func quadrantLabel(_ quadrant: EisenhowerQuadrant) -> String {
        switch quadrant {
        case .importantUrgent:
            return localization.text(.widgetEisenhowerImportantUrgent)
        case .importantNotUrgent:
            return localization.text(.widgetEisenhowerImportantNotUrgent)
        case .notImportantUrgent:
            return localization.text(.widgetEisenhowerNotImportantUrgent)
        case .notImportantNotUrgent:
            return localization.text(.widgetEisenhowerNotImportantNotUrgent)
        }
    }

    private func loadInitialState() {
        switch state {
        case .add:
            title = ""
            quadrant = .importantNotUrgent
            isDone = false
        case .edit(let task):
            title = task.title
            quadrant = task.quadrant
            isDone = task.isDone
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
