import SwiftUI
import SwiftData

struct ManageTopMissionView: View {
    private enum RecordingTarget: Equatable {
        case mainTask
        case subtask(Int)
    }

    private let maxSubtasks = 4
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @Query private var entries: [TopMissionEntry]

    let widgetID: UUID

    @State private var draftTask: String = ""
    @State private var draftSubtasks: [TopMissionSubtask] = []
    @State private var recordingTarget: RecordingTarget?
    @StateObject private var speechRecognizer = TopMissionSpeechRecognizer()

    init(widgetID: UUID, isPresented: Binding<Bool>) {
        self.widgetID = widgetID
        self._isPresented = isPresented
        _entries = Query(filter: #Predicate<TopMissionEntry> { $0.widgetID == widgetID })
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)

            VStack(spacing: 12) {
                HStack {
                    Text(localization.text(.widgetTopMissionManageAction))
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Button {
                        speechRecognizer.stopRecording()
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 8) {
                    TextField(localization.text(.widgetTopMissionTaskPlaceholder), text: $draftTask, axis: .vertical)
                        .lineLimit(3...6)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        toggleRecording(for: .mainTask) { text in
                            draftTask = text
                        }
                    } label: {
                        Image(systemName: isRecording(.mainTask) ? "stop.fill" : "mic.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(isRecording(.mainTask) ? Color.red.opacity(0.82) : Color.white.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .help(isRecording(.mainTask) ? "Stop voice input" : "Start voice input")
                }

                if let error = speechRecognizer.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.text(.widgetTopMissionSubtasksTitle))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(spacing: 6) {
                            ForEach(Array(draftSubtasks.enumerated()), id: \.offset) { index, _ in
                                HStack(spacing: 8) {
                                    TextField(localization.text(.widgetTopMissionSubtaskPlaceholder),
                                              text: bindingForSubtask(at: index))
                                    .textFieldStyle(.roundedBorder)

                                    Button {
                                        toggleRecording(for: .subtask(index)) { text in
                                            guard draftSubtasks.indices.contains(index) else { return }
                                            draftSubtasks[index].title = text
                                        }
                                    } label: {
                                        Image(systemName: isRecording(.subtask(index)) ? "stop.fill" : "mic.fill")
                                            .font(.system(size: 11, weight: .semibold))
                                            .foregroundStyle(.white)
                                            .frame(width: 24, height: 24)
                                            .background(
                                                Circle()
                                                    .fill(isRecording(.subtask(index)) ? Color.red.opacity(0.82) : Color.white.opacity(0.16))
                                            )
                                    }
                                    .buttonStyle(.plain)
                                    .help(isRecording(.subtask(index)) ? "Stop voice input" : "Start voice input for subtask")

                                    if isRecording(.subtask(index)) {
                                        Button {
                                            finishRecordingAndSaveDraft()
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundStyle(.green.opacity(0.92))
                                        }
                                        .buttonStyle(.plain)
                                        .help("Finish voice input")
                                    } else {
                                        Button(role: .destructive) {
                                            removeSubtask(at: index)
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(.red.opacity(0.9))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: 90)

                    Button {
                        guard draftSubtasks.count < maxSubtasks else { return }
                        draftSubtasks.append(TopMissionSubtask(title: ""))
                    } label: {
                        Label(localization.text(.widgetTopMissionAddSubtask), systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(draftSubtasks.count >= maxSubtasks)
                }

                HStack {
                    Button(localization.text(.widgetEisenhowerSave)) {
                        saveTask()
                        persistContext()
                        speechRecognizer.stopRecording()
                        isPresented = false
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(localization.text(.widgetDelete), role: .destructive) {
                        deleteTask()
                        persistContext()
                        speechRecognizer.stopRecording()
                        isPresented = false
                    }
                    .buttonStyle(.plain)

                    Button(localization.text(.widgetEisenhowerCancel)) {
                        speechRecognizer.stopRecording()
                        isPresented = false
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .frame(width: 332, height: 320)
        .onAppear {
            refreshDraftFromEntry()
        }
        .onChange(of: entries.first?.updatedAt) { _, _ in
            refreshDraftFromEntry()
        }
        .onDisappear {
            recordingTarget = nil
            speechRecognizer.stopRecording()
        }
    }

    private func saveTask() {
        let text = draftTask.trimmed
        let subtasks = draftSubtasks
            .prefix(maxSubtasks)
            .map { $0 }
        if let existing = entries.first {
            existing.task = text
            existing.isCompleted = text.isEmpty ? false : existing.isCompleted
            existing.setSubtasks(Array(subtasks))
            existing.updatedAt = Date()
        } else {
            let entry = TopMissionEntry(widgetID: widgetID,
                                       task: text,
                                       isCompleted: false)
            entry.setSubtasks(Array(subtasks))
            modelContext.insert(entry)
        }
    }

    private func deleteTask() {
        for entry in entries {
            modelContext.delete(entry)
        }
    }

    private func persistContext() {
        do {
            try modelContext.save()
        } catch {
            print("TopMission save error: \(error)")
        }
    }

    private func bindingForSubtask(at index: Int) -> Binding<String> {
        Binding(
            get: {
                guard draftSubtasks.indices.contains(index) else { return "" }
                return draftSubtasks[index].title
            },
            set: { value in
                guard draftSubtasks.indices.contains(index) else { return }
                draftSubtasks[index].title = value
            }
        )
    }

    private func isRecording(_ target: RecordingTarget) -> Bool {
        speechRecognizer.isRecording && recordingTarget == target
    }

    private func stopRecording() {
        recordingTarget = nil
        speechRecognizer.stopRecording()
    }

    private func finishRecordingAndSaveDraft() {
        recordingTarget = nil
        speechRecognizer.completeRecording {
            saveTask()
            persistContext()
            refreshDraftFromEntry()
        }
    }

    private func toggleRecording(for target: RecordingTarget, onText: @escaping (String) -> Void) {
        if speechRecognizer.isRecording {
            if recordingTarget == target {
                stopRecording()
                return
            }

            stopRecording()
        }

        recordingTarget = target
        speechRecognizer.toggleRecording { text in
            onText(text)
            if !speechRecognizer.isRecording {
                recordingTarget = nil
            }
        }
    }

    private func removeSubtask(at index: Int) {
        guard draftSubtasks.indices.contains(index) else { return }
        if case .subtask = recordingTarget {
            stopRecording()
        }
        draftSubtasks.remove(at: index)
    }

    private func refreshDraftFromEntry() {
        draftTask = entries.first?.task ?? ""
        draftSubtasks = Array((entries.first?.subtasks ?? []).prefix(maxSubtasks))
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
