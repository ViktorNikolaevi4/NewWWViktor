import SwiftUI

struct WidgetGeneralSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.locationTitle)) {
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

    func title(using localization: LocalizationManager) -> String {
        switch self {
        case .main:
            return localization.text(.appearancePrimaryColor)
        case .secondary:
            return localization.text(.appearanceSecondaryColor)
        }
    }
}

struct WidgetBehaviorSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var sizeSelection: WidgetSizeOption
    @Binding var isPinnedTop: Bool
    @Binding var lockPosition: Bool

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetBehaviorSection)) {
            WidgetSettingsRow(title: localization.text(.widgetSizeLabel)) {
                WidgetSizePicker(selection: $sizeSelection)
            }
            ToggleRow(title: localization.text(.widgetPinToTop), isOn: $isPinnedTop)
            ToggleRow(title: localization.text(.widgetLockPosition), isOn: $lockPosition)
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
