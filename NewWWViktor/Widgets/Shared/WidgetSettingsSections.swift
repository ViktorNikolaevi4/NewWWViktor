import SwiftUI
import SwiftData
#if os(macOS)
import AppKit
#endif

struct WidgetGeneralSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var widget: WidgetInstance
    @Binding var isLocationPickerPresented: Bool
    @Binding var showWeather: Bool
    @Binding var showManageHabits: Bool
    @Binding var showCryptoSearch: Bool

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
                WidgetSettingsRow(title: localization.text(.widgetPomodoroSoundLabel)) {
                    Menu {
                        ForEach(pomodoroSoundOptions, id: \.self) { name in
                            Button(name) {
                                widget.pomodoroSoundName = name
                                playPomodoroSound(name)
                            }
                        }
                    } label: {
                        ValuePill(text: widget.pomodoroSoundName)
                    }
                    .menuStyle(.borderlessButton)
                    .buttonStyle(.plain)
                }
                ToggleRow(title: localization.text(.widgetPomodoroNotificationsLabel),
                          isOn: $widget.pomodoroNotificationsEnabled)
                ToggleRow(title: localization.text(.widgetPomodoroAutoStart),
                          isOn: $widget.pomodoroAutoStart)
            }
        }

        if widget.type == .crypto {
            CryptoSettingsSection(widget: $widget, showCryptoSearch: $showCryptoSearch)
        }

        if widget.type == .habits {
            HabitSettingsSection(widgetID: widget.id, showManageHabits: $showManageHabits)
        }
    }
}

struct HabitSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [HabitEntry]
    @Query private var customHabits: [CustomHabit]
    let widgetID: UUID
    @State private var newHabitTitle = ""
    @Binding var showManageHabits: Bool

    init(widgetID: UUID, showManageHabits: Binding<Bool>) {
        self.widgetID = widgetID
        self._showManageHabits = showManageHabits
        _entries = Query(filter: #Predicate<HabitEntry> { $0.widgetID == widgetID })
        _customHabits = Query()
    }

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetHabitsSectionTitle)) {
            if let entry = entries.first {
                WidgetSettingsRow(title: localization.text(.widgetHabitsHabitLabel)) {
                    Picker("", selection: habitSelectionBinding(entry)) {
                        Section(localization.text(.widgetHabitsDefaultSection)) {
                            ForEach(HabitKind.allCases) { habit in
                                Text(localization.text(habit.titleKey))
                                    .tag(presetTag(for: habit))
                            }
                        }
                        if !customHabits.isEmpty {
                            Section(localization.text(.widgetHabitsCustomSection)) {
                                ForEach(sortedCustomHabits) { habit in
                                    Text(habit.title)
                                        .tag(customTag(for: habit))
                                }
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }

                WidgetSettingsRow(title: localization.text(.widgetHabitsNewHabitLabel)) {
                    HStack(spacing: 8) {
                        TextField(localization.text(.widgetHabitsNewHabitPlaceholder), text: $newHabitTitle)
                            .textFieldStyle(.roundedBorder)

                        Button(localization.text(.widgetHabitsAddCustom)) {
                            addCustomHabit(for: entry)
                        }
                        .buttonStyle(.plain)
                        .disabled(newHabitTitle.trimmed.isEmpty)
                    }
                }

                WidgetSettingsRowButton(title: localization.text(.widgetHabitsManageAction)) {
                    showManageHabits = true
                } content: {
                    IconButton(systemName: "slider.horizontal.3", isSelected: true)
                }

                WidgetSettingsRow(title: localization.text(.widgetHabitsStreakDaysLabel)) {
                    HStack(spacing: 8) {
                        Text("\(entry.streakDays)")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(minWidth: 36, alignment: .trailing)

                        Stepper("", value: streakDaysBinding(entry), in: 0...999)
                            .labelsHidden()
                    }
                }

                WidgetSettingsRowButton(title: localization.text(.widgetHabitsResetProgress)) {
                    entry.progressDays = 0
                    entry.updatedAt = Date()
                } content: {
                    IconButton(systemName: "arrow.counterclockwise", isSelected: true)
                }
            } else {
                WidgetSettingsRow(title: localization.text(.widgetHabitsHabitLabel)) {
                    Text(localization.text(.widgetHabitsLoading))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear(perform: ensureEntry)
    }

    private func ensureEntry() {
        guard entries.isEmpty else { return }
        let entry = HabitEntry(widgetID: widgetID)
        modelContext.insert(entry)
    }

    private var sortedCustomHabits: [CustomHabit] {
        customHabits.sorted { $0.createdAt < $1.createdAt }
    }

    private func presetTag(for habit: HabitKind) -> String {
        "preset:\(habit.rawValue)"
    }

    private func customTag(for habit: CustomHabit) -> String {
        "custom:\(habit.id.uuidString)"
    }

    private func habitSelectionBinding(_ entry: HabitEntry) -> Binding<String> {
        Binding(
            get: {
                if let customID = entry.customHabitID,
                   customHabits.contains(where: { $0.id == customID }) {
                    return "custom:\(customID.uuidString)"
                }
                return "preset:\(entry.habitKind.rawValue)"
            },
            set: { newValue in
                if newValue.hasPrefix("custom:") {
                    let raw = newValue.replacingOccurrences(of: "custom:", with: "")
                    entry.customHabitID = UUID(uuidString: raw)
                } else if newValue.hasPrefix("preset:") {
                    let raw = newValue.replacingOccurrences(of: "preset:", with: "")
                    entry.customHabitID = nil
                    entry.habitKind = HabitKind(rawValue: raw) ?? .drinkWater
                }
                entry.updatedAt = Date()
            }
        )
    }

    private func streakDaysBinding(_ entry: HabitEntry) -> Binding<Int> {
        Binding(
            get: { entry.streakDays },
            set: { newValue in
                entry.streakDays = newValue
                if entry.progressDays > newValue {
                    entry.progressDays = newValue
                }
                entry.updatedAt = Date()
            }
        )
    }
    private func addCustomHabit(for entry: HabitEntry) {
        let trimmed = newHabitTitle.trimmed
        guard !trimmed.isEmpty else { return }
        let existing = customHabits.contains { $0.title.compare(trimmed, options: .caseInsensitive) == .orderedSame }
        guard !existing else { return }
        let habit = CustomHabit(title: trimmed)
        modelContext.insert(habit)
        entry.customHabitID = habit.id
        entry.updatedAt = Date()
        newHabitTitle = ""
    }
}

private struct CryptoSettingsSection: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var manager: WidgetManager
    @Binding var widget: WidgetInstance
    @Binding var showCryptoSearch: Bool

    var body: some View {
        WidgetSettingsGroup(title: localization.text(.widgetCryptoSectionTitle)) {
            WidgetSettingsRow(title: localization.text(.widgetCryptoSymbolLabel)) {
                Text(currentSymbolLabel)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white)
            }

            WidgetSettingsRowButton(title: localization.text(.widgetCryptoSearchAction)) {
                showCryptoSearch = true
            } content: {
                IconButton(systemName: "magnifyingglass", isSelected: true)
            }
        }
        .onAppear {
            manager.cryptoProvider.loadAllSymbolsIfNeeded()
        }
    }

    private var currentSymbolLabel: String {
        symbolLabel(for: widget.cryptoSymbol)
    }

    private func symbolLabel(for symbol: String) -> String {
        if let info = manager.cryptoProvider.allSymbolInfo[symbol] {
            return "\(info.base)/\(info.quote)"
        }
        return symbol
    }
}

struct CryptoSearchView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var manager: WidgetManager
    @Binding var isPresented: Bool
    @State private var searchText = ""
    let onSelect: (String) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.82))
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.08))
                )
                .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 10)

            VStack(spacing: 12) {
                HStack {
                    Text(localization.text(.widgetCryptoSearchTitle))
                        .font(.system(size: 16, weight: .semibold))
                    Spacer()
                    Button {
                        isPresented = false
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.12))
                            )
                    }
                    .buttonStyle(.plain)
                }

                TextField(localization.text(.widgetCryptoSearchPlaceholder), text: $searchText)
                    .textFieldStyle(.roundedBorder)

                if searchText.trimmed.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.text(.widgetCryptoSuggestionsTitle))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(.secondary)

                        FlowCapsuleRow(items: suggestedSymbols) { symbol in
                            onSelect(symbol)
                            isPresented = false
                        }
                    }
                }

                if manager.cryptoProvider.allSymbols.isEmpty {
                    Text(localization.text(.widgetCryptoLoadingSymbols))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredSymbols.isEmpty {
                    Text(localization.text(.widgetCryptoNoResults))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(filteredSymbols, id: \.self) { symbol in
                            WidgetSettingsRowButton(title: symbolLabel(for: symbol)) {
                                onSelect(symbol)
                                isPresented = false
                            } content: {
                                IconButton(systemName: "arrow.right", isSelected: false)
                            }
                            .listRowBackground(Color.clear)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .padding(16)
        }
        .frame(width: 320, height: 360)
        .onAppear {
            manager.cryptoProvider.loadAllSymbolsIfNeeded()
        }
    }

    private var filteredSymbols: [String] {
        let query = searchText.trimmed.uppercased()
        let symbols = manager.cryptoProvider.allSymbols
        guard !query.isEmpty else { return Array(symbols.prefix(30)) }
        return symbols
            .filter { matchesQuery($0, query: query) }
            .prefix(50)
            .map { $0 }
    }

    private func symbolLabel(for symbol: String) -> String {
        if let info = manager.cryptoProvider.allSymbolInfo[symbol] {
            return "\(info.base)/\(info.quote)"
        }
        return symbol
    }

    private func matchesQuery(_ symbol: String, query: String) -> Bool {
        if symbol.contains(query) {
            return true
        }
        if let info = manager.cryptoProvider.allSymbolInfo[symbol] {
            let base = info.base.uppercased()
            let quote = info.quote.uppercased()
            if base.contains(query) || quote.contains(query) {
                return true
            }
            if query.contains(base) || query.contains(quote) {
                return true
            }
            if let alias = baseAlias[base], query.contains(alias) || alias.contains(query) {
                return true
            }
        }
        return false
    }

    private var baseAlias: [String: String] {
        [
            "BTC": "BITCOIN",
            "ETH": "ETHEREUM",
            "USDT": "TETHER",
            "BNB": "BINANCE",
            "SOL": "SOLANA",
            "XRP": "RIPPLE",
            "DOGE": "DOGECOIN",
            "ADA": "CARDANO"
        ]
    }

    private var suggestedSymbols: [String] {
        let defaults = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT", "DOGEUSDT"]
        let available = manager.cryptoProvider.allSymbols
        if available.isEmpty {
            return defaults
        }
        return defaults.filter { available.contains($0) }
    }
}

private struct FlowCapsuleRow: View {
    let items: [String]
    let onTap: (String) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(items, id: \.self) { symbol in
                Button(symbol) {
                    onTap(symbol)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.12))
                )
            }
        }
    }
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
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

private let pomodoroSoundOptions: [String] = [
    "Basso",
    "Blow",
    "Bottle",
    "Frog",
    "Funk",
    "Glass",
    "Hero",
    "Morse",
    "Ping",
    "Pop",
    "Purr",
    "Sosumi",
    "Submarine",
    "Tink"
]

private func playPomodoroSound(_ name: String) {
#if os(macOS)
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    NSSound(named: NSSound.Name(trimmed))?.play()
#endif
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
