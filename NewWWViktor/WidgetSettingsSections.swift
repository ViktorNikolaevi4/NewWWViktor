import SwiftUI

struct WidgetGeneralSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool

    var body: some View {
        WidgetSettingsGroup(title: "Location") {
            WidgetSettingsRowButton(title: localization.text(.widgetLocationSection)) {
                isLocationPickerPresented = true
            } content: {
                ValuePill(text: widget.location.displayName,
                          icon: widget.location.iconName)
            }

            WidgetSettingsRow(title: localization.text(.widgetNameLabel)) {
                ValuePill(text: widget.location.city ?? localization.text(.widgetPlaceholderDash))
            }

            ToggleRow(title: localization.text(.widgetShowDate), isOn: $widget.showsDate)
            ToggleRow(title: localization.text(.widgetShowLocation), isOn: $widget.showsLocation)
            ToggleRow(title: localization.text(.widgetShowWeather), isOn: $showWeather)

            WidgetSettingsRow(title: localization.text(.widgetTimeLabel)) {
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
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var widget: WidgetInstance
    let onColorPicker: (WidgetColorRole) -> Void
    let onBackgroundPicker: () -> Void

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetColorsSection)) {
            WidgetSettingsRowButton(title: localization.text(.appearancePrimaryColor)) {
                onColorPicker(.main)
            } content: {
                ColorChip(colorName: widget.mainColorName,
                          intensity: widget.mainColorIntensity)
            }
            WidgetSettingsRowButton(title: localization.text(.appearanceSecondaryColor)) {
                onColorPicker(.secondary)
            } content: {
                ColorChip(colorName: widget.secondaryColorName,
                          intensity: widget.secondaryColorIntensity)
            }
            WidgetSettingsRowButton(title: localization.text(.appearanceBackgroundSection), action: onBackgroundPicker) {
                let isGlobal = widget.backgroundStyle == nil
                ValuePill(text: isGlobal ? localization.text(.widgetBackgroundGlobal) : localization.text(.widgetBackgroundCustom),
                          icon: isGlobal ? "circle.lefthalf.filled" : "paintpalette")
            }
        }
    }
}

struct WidgetBehaviorSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var sizeSelection: WidgetSizeOption
    @Binding var isPinnedTop: Bool
    @Binding var lockPosition: Bool
    @Binding var snapToGrid: Bool

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetBehaviorSection)) {
            WidgetSettingsRow(title: localization.text(.widgetSizeLabel)) {
                WidgetSizePicker(selection: $sizeSelection)
            }
            ToggleRow(title: localization.text(.widgetPinToTop), isOn: $isPinnedTop)
            ToggleRow(title: localization.text(.widgetLockPosition), isOn: $lockPosition)
            ToggleRow(title: localization.text(.widgetSnapToGrid), isOn: $snapToGrid)
        }
    }
}

struct WidgetManagementSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    var onAddWidgets: () -> Void
    var onShowGeneralSettings: () -> Void
    var onDelete: () -> Void

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetActionsSection)) {
            WidgetSettingsRowButton(title: localization.text(.widgetAddWidgets), action: onAddWidgets) {
                IconButton(systemName: "plus", isSelected: true)
            }
            WidgetSettingsRowButton(title: localization.text(.widgetGeneralSettings), action: onShowGeneralSettings) {
                IconButton(systemName: "gearshape", isSelected: true)
            }
            WidgetSettingsButton(title: localization.text(.widgetDelete), role: .destructive, action: onDelete)
        }
    }
}
