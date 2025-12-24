import SwiftUI

struct WidgetGeneralSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool

    var body: some View {
        let isWeather = widget.type == .weather
        let isClock = widget.type == .clock
        let usesLocation = isWeather || isClock

        if usesLocation {
            WidgetSettingsGroup(title: localization.text(.locationTitle)) {
                WidgetSettingsRowButton(title: localization.text(.widgetLocationSection)) {
                    isLocationPickerPresented = true
                } content: {
                    ValuePill(text: widget.location.displayName,
                              icon: widget.location.iconName)
                }

                if isClock {
                    WidgetSettingsRow(title: localization.text(.widgetNameLabel)) {
                        ValuePill(text: widget.location.city ?? localization.text(.widgetPlaceholderDash))
                    }

                    ToggleRow(title: localization.text(.widgetShowDate), isOn: $widget.showsDate)
                    ToggleRow(title: localization.text(.widgetShowLocation), isOn: $widget.showsLocation)
                    ToggleRow(title: localization.text(.widgetShowWeather), isOn: $showWeather)

                    WidgetSettingsRow(title: localization.text(.widgetTimeLabel)) {
                        SegmentedPill(options: [localization.text(.widgetTimeFormat12h),
                                                localization.text(.widgetTimeFormat24h)],
                                      selected: $widget.prefersTwelveHour)
                    }
                }
            }
        }

        if isWeather {
            WidgetSettingsGroup(title: localization.text(.widgetWeatherDetailTitle)) {
                WidgetSettingsRow(title: localization.text(.widgetTemperatureLabel)) {
                    SegmentedPill(options: ["°C", "°F"], selected: $widget.prefersCelsius)
                }

                WidgetSettingsRow(title: localization.text(.widgetTimeLabel)) {
                    SegmentedPill(options: [localization.text(.widgetTimeFormat12h),
                                            localization.text(.widgetTimeFormat24h)],
                                  selected: $widget.prefersTwelveHour)
                }
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
                ColorChip(colorName: widget.backgroundColorName ?? localization.text(.global),
                          intensity: widget.backgroundIntensity)
            }
            ToggleRow(title: localization.text(.appearanceBlurBackground), isOn: $widget.isBackgroundHidden)
        }
    }
}

struct WidgetBehaviorSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var sizeSelection: WidgetSizeOption
    @Binding var isPinnedTop: Bool
    @Binding var lockPosition: Bool
    var availableSizes: [WidgetSizeOption]

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetBehaviorSection)) {
            WidgetSettingsRow(title: localization.text(.widgetSizeLabel)) {
                WidgetSizePicker(selection: $sizeSelection, availableSizes: availableSizes)
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
