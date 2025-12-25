import SwiftUI

struct WidgetGeneralSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool

    var body: some View {
        let isWeather = widget.type == .weather
        let isClock = widget.type == .clock
        let isPomodoro = widget.type == .pomodoro
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

        if isPomodoro {
            WidgetSettingsGroup(title: localization.text(.widgetPomodoroSettingsTitle)) {
                PomodoroStepperRow(title: localization.text(.widgetPomodoroFocusDuration),
                                   value: $widget.pomodoroFocusMinutes,
                                   range: 5...60,
                                   step: 5,
                                   unit: localization.text(.widgetPomodoroMinutesUnit))
                PomodoroStepperRow(title: localization.text(.widgetPomodoroShortBreakDuration),
                                   value: $widget.pomodoroShortBreakMinutes,
                                   range: 1...60,
                                   step: 5,
                                   unit: localization.text(.widgetPomodoroMinutesUnit),
                                   increment: { value in
                                       value <= 1 ? 5 : value + 5
                                   },
                                   decrement: { value in
                                       value <= 5 ? 1 : value - 5
                                   })
                PomodoroStepperRow(title: localization.text(.widgetPomodoroLongBreakDuration),
                                   value: $widget.pomodoroLongBreakMinutes,
                                   range: 5...60,
                                   step: 5,
                                   unit: localization.text(.widgetPomodoroMinutesUnit))
                PomodoroStepperRow(title: localization.text(.widgetPomodoroRounds),
                                   value: $widget.pomodoroTotalRounds,
                                   range: 1...10,
                                   step: 1,
                                   unit: nil)
                ToggleRow(title: localization.text(.widgetPomodoroAutoStart),
                          isOn: $widget.pomodoroAutoStart)
            }
        }
    }
}

private struct PomodoroStepperRow: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    let step: Int
    let unit: String?
    var increment: ((Int) -> Int)?
    var decrement: ((Int) -> Int)?

    var body: some View {
        WidgetSettingsRow(title: title) {
            HStack(spacing: 6) {
                Button {
                    let next = decrement?(value) ?? (value - step)
                    value = max(range.lowerBound, next)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Text(valueText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(minWidth: 40)

                Button {
                    let next = increment?(value) ?? (value + step)
                    value = min(range.upperBound, next)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var valueText: String {
        if let unit, !unit.isEmpty {
            return "\(value)\(unit)"
        }
        return "\(value)"
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
