import SwiftUI

struct SettingsMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
    let action: () -> Void
}

struct SettingsPopoverView: View {
    private let primaryItems: [SettingsMenuItem] = [
        SettingsMenuItem(id: "general", title: "Основные", systemImage: "slider.horizontal.3", action: {}),
        SettingsMenuItem(id: "appearance", title: "Оформление", systemImage: "paintbrush", action: {}),
        SettingsMenuItem(id: "shortcuts", title: "Быстрые команды", systemImage: "bolt", action: {}),
        SettingsMenuItem(id: "plan", title: "План", systemImage: "calendar", action: {}),
        SettingsMenuItem(id: "screens", title: "Экраны", systemImage: "macwindow", action: {}),
        SettingsMenuItem(id: "backups", title: "Резервные копии", systemImage: "externaldrive", action: {}),
        SettingsMenuItem(id: "support", title: "Поддержка", systemImage: "lifepreserver", action: {}),
        SettingsMenuItem(id: "about", title: "О нас", systemImage: "info.circle", action: {})
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(primaryItems) { item in
                SettingsMenuRow(item: item)
            }

            Divider()

            SettingsMenuRow(item: SettingsMenuItem(id: "logout",
                                                   title: "Выйти",
                                                   systemImage: "power",
                                                   action: {}))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .frame(width: 220)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.thinMaterial)
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 14)
        )
    }
}

private struct SettingsMenuRow: View {
    let item: SettingsMenuItem

    var body: some View {
        Button {
            item.action()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Text(item.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}
