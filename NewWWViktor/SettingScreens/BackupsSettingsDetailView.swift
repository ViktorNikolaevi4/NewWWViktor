import SwiftUI

struct BackupsSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var manager: WidgetManager
    @State private var backups: [BackupEntry] = []
    @State private var isLoading = false
    @State private var alertMessage: String?
    @State private var showAlert = false
    private let backupsListKey = "miniww.backups.list"

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    backupSection
                    backupsList
                }
                .padding(.horizontal, 6)
                .padding(.bottom, 12)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity)
        .onAppear(perform: loadBackups)
        .alert("Ошибка", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let alertMessage {
                Text(alertMessage)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.text(.categoryBackups))
                .font(.title3.weight(.semibold))
            Text(localization.text(.backupsSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var backupSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(localization.text(.backupsManualTitle))
                .font(.headline.weight(.semibold))

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text(.backupsCreateTitle))
                        .font(.body.weight(.semibold))
                    Text(localization.text(.backupsCreateDescription))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(localization.text(.backupsSaveNowButton)) {
                    saveBackup()
                }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
        )
    }

    private var backupsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(backups) { entry in
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                            .font(.headline.weight(.semibold))
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(localization.text(.backupsRestoreButton)) {
                        restore(entry)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)

                    Button(role: .destructive) {
                        delete(entry)
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
    }

    private func saveBackup() {
        isLoading = true
        let snapshot = manager.exportSnapshot()
        do {
            let data = try JSONEncoder().encode(snapshot)
            let dir = manager.backupsDirectory()
            let filename = "backup-\(ISO8601DateFormatter().string(from: snapshot.createdAt)).json"
            let url = dir.appendingPathComponent(filename)
            try data.write(to: url)

            var list = backups
            let entry = BackupEntry(id: UUID(),
                                    date: snapshot.createdAt,
                                    path: url.path)
            list.insert(entry, at: 0)
            backups = list
            persistBackups()
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
        isLoading = false
    }

    private func restore(_ entry: BackupEntry) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: entry.path))
            let snapshot = try JSONDecoder().decode(WidgetManager.BackupSnapshot.self, from: data)
            manager.applySnapshot(snapshot)
        } catch {
            alertMessage = error.localizedDescription
            showAlert = true
        }
    }

    private func delete(_ entry: BackupEntry) {
        let fm = FileManager.default
        if fm.fileExists(atPath: entry.path) {
            try? fm.removeItem(atPath: entry.path)
        }
        backups.removeAll { $0.id == entry.id }
        persistBackups()
    }

    private func loadBackups() {
        guard let data = UserDefaults.standard.data(forKey: backupsListKey),
              let saved = try? JSONDecoder().decode([BackupEntry].self, from: data) else { return }
        backups = saved
    }

    private func persistBackups() {
        if let data = try? JSONEncoder().encode(backups) {
            UserDefaults.standard.set(data, forKey: backupsListKey)
        }
    }
}

private struct BackupEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let path: String

    var title: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    var subtitle: String {
        "Файл: \(URL(fileURLWithPath: path).lastPathComponent)"
    }
}
