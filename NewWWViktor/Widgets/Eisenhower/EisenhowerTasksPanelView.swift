import SwiftUI
import SwiftData

struct EisenhowerTasksPanelView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localization: LocalizationManager
    @Query(sort: \EisenhowerTask.createdAt, order: .reverse)
    private var tasks: [EisenhowerTask]

    @State private var editorState: EisenhowerTaskEditorState?
    @State private var showCompleted = false

    var body: some View {
        VStack(spacing: 0) {
            header

            List {
                let quadrants: [EisenhowerQuadrant] = EisenhowerQuadrant.allCases
                SwiftUI.ForEach(quadrants, id: \EisenhowerQuadrant.id) { (quadrant: EisenhowerQuadrant) in
                    let items = tasksForQuadrant(quadrant)
                    if !items.isEmpty {
                        Section(header: Text(quadrantLabel(quadrant))) {
                            ForEach(items, id: \.uuid) { task in
                                EisenhowerTaskRow(task: task,
                                                  accent: quadrantColor(quadrant),
                                                  onEdit: { editorState = .edit(task) },
                                                  onDelete: { modelContext.delete(task) })
                                    .contextMenu {
                                        Button(localization.text(.widgetEisenhowerEditTask)) {
                                            editorState = .edit(task)
                                        }
                                        Button(role: .destructive) {
                                            modelContext.delete(task)
                                        } label: {
                                            Text(localization.text(.widgetEisenhowerDeleteTask))
                                        }
                                    }
                            }
                            .onDelete { indexSet in
                                deleteItems(indexSet, quadrant: quadrant)
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 420, height: 520)
        .sheet(item: $editorState) { state in
            EisenhowerTaskEditorView(state: state,
                                     onSave: saveTask)
                .environmentObject(localization)
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Text(localization.text(.widgetEisenhowerManageTasks))
                .font(.system(size: 16, weight: .semibold))

            Spacer()

            Toggle(isOn: $showCompleted) {
                Text(localization.text(.widgetEisenhowerShowCompleted))
            }
            .toggleStyle(.switch)
            .font(.system(size: 12, weight: .medium))

            Button {
                editorState = .add
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .bold))
                    .padding(6)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.2))
    }

    private func tasksForQuadrant(_ quadrant: EisenhowerQuadrant) -> [EisenhowerTask] {
        tasks.filter { task in
            task.quadrant == quadrant && (showCompleted || !task.isDone)
        }
    }

    private func deleteItems(_ indexSet: IndexSet, quadrant: EisenhowerQuadrant) {
        let items = tasksForQuadrant(quadrant)
        indexSet.map { items[$0] }.forEach { task in
            modelContext.delete(task)
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

    private func quadrantColor(_ quadrant: EisenhowerQuadrant) -> Color {
        switch quadrant {
        case .importantUrgent:
            return Color.red.opacity(0.9)
        case .importantNotUrgent:
            return Color.yellow.opacity(0.9)
        case .notImportantUrgent:
            return Color.blue.opacity(0.9)
        case .notImportantNotUrgent:
            return Color.gray.opacity(0.7)
        }
    }

    private func saveTask(_ state: EisenhowerTaskEditorState,
                          title: String,
                          quadrant: EisenhowerQuadrant,
                          isDone: Bool) {
        switch state {
        case .add:
            let task = EisenhowerTask(title: title, quadrant: quadrant, isDone: isDone)
            modelContext.insert(task)
        case .edit(let task):
            task.title = title
            task.quadrant = quadrant
            task.isDone = isDone
        }
    }
}

private struct EisenhowerTaskRow: View {
    let task: EisenhowerTask
    let accent: Color
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(accent)
                .frame(width: 8, height: 8)

            Text(task.title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            Toggle("", isOn: Binding(
                get: { task.isDone },
                set: { task.isDone = $0 }
            ))
            .labelsHidden()
            .toggleStyle(.checkbox)

            Button {
                onEdit()
            } label: {
                Image(systemName: "pencil")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)

            Button(role: .destructive) {
                onDelete()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .semibold))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }
}

enum EisenhowerTaskEditorState: Identifiable {
    case add
    case edit(EisenhowerTask)

    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let task):
            return task.uuid.uuidString
        }
    }
}
