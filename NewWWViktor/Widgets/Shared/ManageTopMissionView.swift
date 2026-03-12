import SwiftUI
import SwiftData

struct ManageTopMissionView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
    @Binding var isPresented: Bool
    @Query private var entries: [TopMissionEntry]

    let widgetID: UUID

    @State private var draftTask: String = ""
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
                        speechRecognizer.toggleRecording { text in
                            draftTask = text
                        }
                    } label: {
                        Image(systemName: speechRecognizer.isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(
                                Circle()
                                    .fill(speechRecognizer.isRecording ? Color.red.opacity(0.82) : Color.white.opacity(0.2))
                            )
                    }
                    .buttonStyle(.plain)
                    .help(speechRecognizer.isRecording ? "Stop voice input" : "Start voice input")
                }

                if let error = speechRecognizer.errorMessage, !error.isEmpty {
                    Text(error)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.red.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                HStack {
                    Button(localization.text(.widgetEisenhowerSave)) {
                        saveTask()
                        speechRecognizer.stopRecording()
                        isPresented = false
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Button(localization.text(.widgetDelete), role: .destructive) {
                        deleteTask()
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
        .frame(width: 360, height: 220)
        .onAppear {
            draftTask = entries.first?.task ?? ""
        }
        .onDisappear {
            speechRecognizer.stopRecording()
        }
    }

    private func saveTask() {
        let text = draftTask.trimmed
        if let existing = entries.first {
            existing.task = text
            existing.updatedAt = Date()
        } else {
            let entry = TopMissionEntry(widgetID: widgetID, task: text)
            modelContext.insert(entry)
        }
    }

    private func deleteTask() {
        for entry in entries {
            modelContext.delete(entry)
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
