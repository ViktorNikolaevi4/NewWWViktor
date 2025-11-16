import SwiftUI

struct WidgetGeneralSettingsSection: View {
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool

    var body: some View {
        WidgetSettingsGroup(title: "Позиция") {
            WidgetSettingsRowButton(title: "Позиция") {
                isLocationPickerPresented = true
            } content: {
                ValuePill(text: widget.location.displayName,
                          icon: widget.location.iconName)
            }

            WidgetSettingsRow(title: "Название") {
                ValuePill(text: widget.location.city ?? "—")
            }

            ToggleRow(title: "Показывать дату", isOn: $widget.showsDate)
            ToggleRow(title: "Показывать местоположение", isOn: $widget.showsLocation)
            ToggleRow(title: "Показывать погоду", isOn: $showWeather)

            WidgetSettingsRow(title: "Время") {
                SegmentedPill(options: ["12ч", "24ч"], selected: $widget.prefersTwelveHour)
            }
        }
    }
}

enum WidgetColorRole {
    case main
    case secondary

    var title: String {
        switch self {
        case .main:
            return "Основной цвет"
        case .secondary:
            return "Вторичный цвет"
        }
    }
}

struct WidgetAppearanceSettingsSection: View {
    @Binding var widget: WidgetInstance
    let onColorPicker: (WidgetColorRole) -> Void

    var body: some View {
        WidgetSettingsGroup(title: "Цвета") {
            WidgetSettingsRowButton(title: "Основной цвет") {
                onColorPicker(.main)
            } content: {
                ColorChip(colorName: widget.mainColorName,
                          intensity: widget.mainColorIntensity)
            }
            WidgetSettingsRowButton(title: "Вторичный цвет") {
                onColorPicker(.secondary)
            } content: {
                ColorChip(colorName: widget.secondaryColorName,
                          intensity: widget.secondaryColorIntensity)
            }
            WidgetSettingsRow(title: "Фон") {
                ValuePill(text: "Глобальный", icon: "circle.lefthalf.filled")
            }
        }
    }
}

struct WidgetBehaviorSettingsSection: View {
    @Binding var sizeSelection: WidgetSizeOption
    @Binding var isPinnedTop: Bool
    @Binding var lockPosition: Bool
    @Binding var snapToGrid: Bool

    var body: some View {
        WidgetSettingsGroup(title: "Поведение") {
            WidgetSettingsRow(title: "Размер") {
                WidgetSizePicker(selection: $sizeSelection)
            }
            ToggleRow(title: "Закрепить сверху", isOn: $isPinnedTop)
            ToggleRow(title: "Зафиксировать положение", isOn: $lockPosition)
            ToggleRow(title: "Привязать к сетке", isOn: $snapToGrid)
        }
    }
}

struct WidgetManagementSettingsSection: View {
    var onAddWidgets: () -> Void
    var onShowGeneralSettings: () -> Void
    var onDelete: () -> Void

    var body: some View {
        WidgetSettingsGroup(title: "Действия") {
            WidgetSettingsRowButton(title: "Добавить виджеты", action: onAddWidgets) {
                IconButton(systemName: "plus", isSelected: true)
            }
            WidgetSettingsRowButton(title: "Основные настройки", action: onShowGeneralSettings) {
                IconButton(systemName: "gearshape", isSelected: true)
            }
            WidgetSettingsButton(title: "Удалить", role: .destructive, action: onDelete)
        }
    }
}
