import SwiftUI

struct WidgetGeneralSettingsSection: View {
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool

    var body: some View {
        WidgetSettingsGroup(title: "Location") {
            WidgetSettingsRowButton(title: "Location") {
                isLocationPickerPresented = true
            } content: {
                ValuePill(text: widget.location.displayName,
                          icon: widget.location.iconName)
            }

            WidgetSettingsRow(title: "Name") {
                ValuePill(text: widget.location.city ?? "—")
            }

            ToggleRow(title: "Show Date", isOn: $widget.showsDate)
            ToggleRow(title: "Show Location", isOn: $widget.showsLocation)
            ToggleRow(title: "Show Weather", isOn: $showWeather)

            WidgetSettingsRow(title: "Time") {
                SegmentedPill(options: ["12h", "24h"], selected: $widget.prefersTwelveHour)
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
            return "Primary Color"
        case .secondary:
            return "Secondary Color"
        }
    }
}

struct WidgetAppearanceSettingsSection: View {
    @Binding var widget: WidgetInstance
    let onColorPicker: (WidgetColorRole) -> Void

    var body: some View {
        WidgetSettingsGroup(title: "Colors") {
            WidgetSettingsRowButton(title: "Primary Color") {
                onColorPicker(.main)
            } content: {
                ColorChip(colorName: widget.mainColorName,
                          intensity: widget.mainColorIntensity)
            }
            WidgetSettingsRowButton(title: "Secondary Color") {
                onColorPicker(.secondary)
            } content: {
                ColorChip(colorName: widget.secondaryColorName,
                          intensity: widget.secondaryColorIntensity)
            }
            WidgetSettingsRow(title: "Background") {
                ValuePill(text: "Global", icon: "circle.lefthalf.filled")
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
        WidgetSettingsGroup(title: "Behavior") {
            WidgetSettingsRow(title: "Size") {
                WidgetSizePicker(selection: $sizeSelection)
            }
            ToggleRow(title: "Pin to Top", isOn: $isPinnedTop)
            ToggleRow(title: "Lock Position", isOn: $lockPosition)
            ToggleRow(title: "Snap to Grid", isOn: $snapToGrid)
        }
    }
}

struct WidgetManagementSettingsSection: View {
    var onAddWidgets: () -> Void
    var onShowGeneralSettings: () -> Void
    var onDelete: () -> Void

    var body: some View {
        WidgetSettingsGroup(title: "Actions") {
            WidgetSettingsRowButton(title: "Add Widgets", action: onAddWidgets) {
                IconButton(systemName: "plus", isSelected: true)
            }
            WidgetSettingsRowButton(title: "General Settings", action: onShowGeneralSettings) {
                IconButton(systemName: "gearshape", isSelected: true)
            }
            WidgetSettingsButton(title: "Delete", role: .destructive, action: onDelete)
        }
    }
}
