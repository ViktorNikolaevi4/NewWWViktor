import SwiftUI
import SwiftData

struct ManageHabitsView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Query private var customHabits: [CustomHabit]
    @State private var searchText = ""
    let onDelete: (CustomHabit) -> Void

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
                    Text(localization.text(.widgetHabitsManageTitle))
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Button {
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

                TextField(localization.text(.widgetHabitsManageSearch), text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if filteredHabits.isEmpty {
                    Text(localization.text(.widgetHabitsManageEmpty))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredHabits) { habit in
                            HStack {
                                Text(habit.title)
                                Spacer()
                                Button(role: .destructive) {
                                    onDelete(habit)
                                } label: {
                                    Image(systemName: "trash")
                                }
                                .buttonStyle(.plain)
                                .help(localization.text(.widgetHabitsDeleteCustom))
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(16)
        }
        .frame(width: 320, height: 360)
    }

    private var filteredHabits: [CustomHabit] {
        let trimmed = searchText.trimmed
        guard !trimmed.isEmpty else { return customHabits.sorted { $0.createdAt < $1.createdAt } }
        return customHabits
            .filter { $0.title.localizedCaseInsensitiveContains(trimmed) }
            .sorted { $0.createdAt < $1.createdAt }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
