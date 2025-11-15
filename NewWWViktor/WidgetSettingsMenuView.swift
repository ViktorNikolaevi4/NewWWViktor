import SwiftUI

struct WidgetSettingsMenuView: View {
    @State private var showDate = true
    @State private var showLocation = true
    @State private var showWeather = false
    @State private var isTwelveHour = true
    @State private var isPinnedTop = false
    @State private var lockPosition = false
    @State private var snapToGrid = true

    var body: some View {
        VStack(spacing: 16) {
            handle

            ScrollView {
                VStack(spacing: 12) {
                    generalSection
                    appearanceSection
                    behaviorSection
                    managementSection
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(minWidth: nil,
               idealWidth: nil,
               maxWidth: nil,
               minHeight: nil,
               idealHeight: nil,
               maxHeight: 520,
               alignment: .center)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(LinearGradient(colors: [Color.white.opacity(0.25), Color.black.opacity(0.15)],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 30)
        .frame(minHeight: 400)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.4))
            .frame(width: 38, height: 5)
            .padding(.top, 4)
    }

    private var generalSection: some View {
        WidgetSettingsGroup(title: "Позиция") {
            WidgetSettingsRow(title: "Позиция") {
                ValuePill(text: "Текущее местоположение", icon: "location.fill")
            }

            WidgetSettingsRow(title: "Название") {
                ValuePill(text: "Сочи")
            }

            ToggleRow(title: "Показывать дату", isOn: $showDate)
            ToggleRow(title: "Показывать местоположение", isOn: $showLocation)
            ToggleRow(title: "Показывать погоду", isOn: $showWeather)

            WidgetSettingsRow(title: "Время") {
                SegmentedPill(options: ["12ч", "24ч"], selected: $isTwelveHour)
            }
        }
    }

    private var appearanceSection: some View {
        WidgetSettingsGroup(title: "Цвета") {
            WidgetSettingsRow(title: "Основной цвет") {
                ValuePill(text: "Глобальный", icon: "paintbrush")
            }
            WidgetSettingsRow(title: "Вторичный цвет") {
                ValuePill(text: "Глобальный", icon: "eyedropper")
            }
            WidgetSettingsRow(title: "Фон") {
                ValuePill(text: "Глобальный", icon: "circle.lefthalf.filled")
            }
        }
    }

    private var behaviorSection: some View {
        WidgetSettingsGroup(title: "Поведение") {
            WidgetSettingsRow(title: "Размер") {
                HStack(spacing: 8) {
                    IconButton(systemName: "rectangle.portrait", isSelected: true)
                    IconButton(systemName: "rectangle", isSelected: false)
                }
            }
            ToggleRow(title: "Закрепить сверху", isOn: $isPinnedTop)
            ToggleRow(title: "Зафиксировать положение", isOn: $lockPosition)
            ToggleRow(title: "Привязать к сетке", isOn: $snapToGrid)
        }
    }

    private var managementSection: some View {
        WidgetSettingsGroup(title: "Действия") {
            WidgetSettingsRow(title: "Добавить виджеты") {
                IconButton(systemName: "plus", isSelected: true)
            }
            WidgetSettingsRow(title: "Основные настройки") {
                IconButton(systemName: "gearshape", isSelected: true)
            }
            WidgetSettingsButton(title: "Удалить", role: .destructive) { }
        }
    }
}

// MARK: - Building Blocks

private struct WidgetSettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))

            VStack(spacing: 1) {
                content
            }
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08))
            )
        }
    }
}

private struct WidgetSettingsRow<Content: View>: View {
    let title: String
    @ViewBuilder var trailing: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.trailing = content()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            Spacer()
            trailing
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.15))
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        WidgetSettingsRow(title: title) {
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.green.opacity(0.8)))
                .labelsHidden()
        }
    }
}

private struct ValuePill: View {
    let text: String
    var icon: String?

    var body: some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
            }
            Text(text)
        }
        .font(.system(size: 13, weight: .medium))
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.14))
        .clipShape(Capsule())
    }
}

private struct SegmentedPill: View {
    let options: [String]
    @Binding var selected: Bool

    var body: some View {
        HStack(spacing: 0) {
            segment(title: options.first ?? "", active: selected, toggleValue: true)
            segment(title: options.last ?? "", active: !selected, toggleValue: false)
        }
        .background(Color.black.opacity(0.25))
        .clipShape(Capsule())
    }

    private func segment(title: String, active: Bool, toggleValue: Bool) -> some View {
        Button {
            selected = toggleValue
        } label: {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(active ? .black : .white.opacity(0.7))
                .padding(.vertical, 6)
                .padding(.horizontal, 18)
                .background(active ? Color.white : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct IconButton: View {
    let systemName: String
    var isSelected: Bool

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? Color.white : Color.black.opacity(0.25))
            )
    }
}

private struct WidgetSettingsButton: View {
    enum Role {
        case normal
        case destructive
    }

    let title: String
    var role: Role = .normal
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                Image(systemName: role == .destructive ? "trash" : "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(role == .destructive ? Color.red.opacity(0.15) : Color.black.opacity(0.15))
            .foregroundColor(role == .destructive ? .red : .white)
        }
        .buttonStyle(.plain)
    }
}
