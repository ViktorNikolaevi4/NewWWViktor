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

struct WidgetAppearanceSettingsSection: View {
    @Binding var widget: WidgetInstance
    @Binding var isColorPickerPresented: Bool

    var body: some View {
        WidgetSettingsGroup(title: "Цвета") {
            WidgetSettingsRowButton(title: "Основной цвет") {
                isColorPickerPresented = true
            } content: {
                ColorChip(colorName: widget.mainColorName,
                          intensity: widget.mainColorIntensity)
            }
            WidgetSettingsRow(title: "Вторичный цвет") {
                ValuePill(text: "Глобальный", icon: "eyedropper")
            }
            WidgetSettingsRow(title: "Фон") {
                ValuePill(text: "Глобальный", icon: "circle.lefthalf.filled")
            }
        }
    }
}

struct WidgetBehaviorSettingsSection: View {
    @Binding var isPinnedTop: Bool
    @Binding var lockPosition: Bool
    @Binding var snapToGrid: Bool

    var body: some View {
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
}

struct WidgetManagementSettingsSection: View {
    var body: some View {
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
