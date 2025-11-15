import SwiftUI

struct SettingsMenuItem: Identifiable {
    let id: String
    let title: String
    let systemImage: String
}

struct SettingsPopoverView: View {
    let onSelect: (String) -> Void
    private let primaryItems: [SettingsMenuItem] = [
        SettingsMenuItem(id: "general", title: "Основные", systemImage: "slider.horizontal.3"),
        SettingsMenuItem(id: "appearance", title: "Оформление", systemImage: "paintbrush"),
        SettingsMenuItem(id: "plan", title: "План", systemImage: "calendar"),
        SettingsMenuItem(id: "screens", title: "Экраны", systemImage: "macwindow"),
        SettingsMenuItem(id: "backups", title: "Резервные копии", systemImage: "externaldrive"),
        SettingsMenuItem(id: "support", title: "Поддержка", systemImage: "lifepreserver"),
        SettingsMenuItem(id: "about", title: "О нас", systemImage: "info.circle")
    ]

    var body: some View {
        VStack(spacing: 12) {
            ForEach(primaryItems) { item in
                SettingsMenuRow(item: item, onSelect: onSelect)
            }

            Divider()

            SettingsMenuRow(item: SettingsMenuItem(id: "logout",
                                                   title: "Выйти",
                                                   systemImage: "power"),
                            onSelect: onSelect)
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
    let onSelect: (String) -> Void

    var body: some View {
        Button {
            onSelect(item.id)
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
