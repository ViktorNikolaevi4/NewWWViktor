import SwiftUI
import SwiftData
#if os(macOS)
import UserNotifications
#endif
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct WidgetSettingsMenuView: View {
    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager
    let widget: WidgetInstance
    let onUpdate: (WidgetInstance) -> Void
    let onDeleteCallback: ((UUID) -> Void)?

    @State private var workingWidget: WidgetInstance
    @State private var showLocationPicker = false
    @State private var activeColorRole: WidgetColorRole?
    @State private var showBackgroundPicker = false
    @State private var showManageHabits = false
    @State private var showCryptoSearch = false
    @State private var showWeather = false
    @State private var isPinnedTop = false
    @State private var lockPosition = false

    init(widget: WidgetInstance,
         onUpdate: @escaping (WidgetInstance) -> Void,
         onDelete: ((UUID) -> Void)? = nil) {
        self.widget = widget
        self.onUpdate = onUpdate
        self.onDeleteCallback = onDelete
        _workingWidget = State(initialValue: widget)
        _isPinnedTop = State(initialValue: widget.isPinned)
        _lockPosition = State(initialValue: widget.isPositionLocked)
    }

    var body: some View {
        let isColorPickerPresented = activeColorRole != nil
        let isOverlayPresented = showLocationPicker || isColorPickerPresented || showBackgroundPicker || showManageHabits || showCryptoSearch

        return ZStack {
            panelContent
                .disabled(isOverlayPresented)
                // Оставляем фон без затемнения при показе оверлеев, чтобы не было темной подложки позади палитры.
                .blur(radius: 0)
                .opacity(1)
                .onAppear {
                    let allowed = workingWidget.type.availableSizes
                    if !allowed.contains(workingWidget.sizeOption), let first = allowed.first {
                        workingWidget.applySizeOption(first)
                        onUpdate(workingWidget)
                    }
                }

            if showLocationPicker {
                WidgetLocationPickerView(isPresented: $showLocationPicker,
                                         selection: $workingWidget.location) { newLocation in
                    apply(location: newLocation)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if let colorRole = activeColorRole {
                WidgetColorPickerView(
                    title: colorRole.title(using: localization),
                    isPresented: Binding(
                        get: { activeColorRole != nil },
                        set: { shouldShow in
                            if !shouldShow { activeColorRole = nil }
                        }
                    ),
                    selection: colorSelectionBinding(for: colorRole),
                    intensity: colorIntensityBinding(for: colorRole)
                ) {
                    onUpdate(workingWidget)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showBackgroundPicker {
                WidgetColorPickerView(
                    title: localization.text(.appearanceBackgroundSection),
                    isPresented: $showBackgroundPicker,
                    selection: Binding(
                        get: { workingWidget.backgroundColorName },
                        set: { newValue in
                            workingWidget.backgroundColorName = newValue
                            onUpdate(workingWidget)
                        }
                    ),
                    intensity: Binding(
                        get: { workingWidget.backgroundIntensity },
                        set: { workingWidget.backgroundIntensity = $0; onUpdate(workingWidget) }
                    ),
                    backgroundStyle: backgroundStyleBinding,
                    gradientColor1Name: $workingWidget.gradientColor1Name,
                    gradientColor1Opacity: $workingWidget.gradientColor1Opacity,
                    gradientColor2Name: $workingWidget.gradientColor2Name,
                    gradientColor2Opacity: $workingWidget.gradientColor2Opacity,
                    gradientColor1Position: $workingWidget.gradientColor1Position,
                    gradientColor2Position: $workingWidget.gradientColor2Position,
                    gradientType: gradientTypeBinding,
                    gradientAngle: gradientAngleBinding
                ) {
                    onUpdate(workingWidget)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showManageHabits {
                ManageHabitsView(isPresented: $showManageHabits, onDelete: deleteCustomHabit)
                    .environmentObject(localization)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showCryptoSearch {
                CryptoSearchView(isPresented: $showCryptoSearch) { symbol in
                    workingWidget.cryptoSymbol = symbol
                    onUpdate(workingWidget)
                }
                .environmentObject(localization)
                .environmentObject(manager)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showLocationPicker)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: isColorPickerPresented)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showBackgroundPicker)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showManageHabits)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showCryptoSearch)
        .frame(width: 360, height: 520)
        .onChange(of: widget) { _, newValue in
            workingWidget = newValue
            isPinnedTop = newValue.isPinned
            lockPosition = newValue.isPositionLocked
        }
        .onChange(of: workingWidget.showsDate) { _, _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.showsLocation) { _, _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.prefersTwelveHour) { _, _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.prefersCelsius) { _, _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.isBackgroundHidden) { _, _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.cryptoSymbol) { _, _ in
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.pomodoroFocusMinutes) { _, newValue in
            applyPomodoroDurationChange(phase: .focus, minutes: newValue)
        }
        .onChange(of: workingWidget.pomodoroShortBreakMinutes) { _, newValue in
            applyPomodoroDurationChange(phase: .shortBreak, minutes: newValue)
        }
        .onChange(of: workingWidget.pomodoroLongBreakMinutes) { _, newValue in
            applyPomodoroDurationChange(phase: .longBreak, minutes: newValue)
        }
        .onChange(of: workingWidget.pomodoroTotalRounds) { _, _ in
            guard workingWidget.type == .pomodoro else { return }
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.pomodoroAutoStart) { _, _ in
            guard workingWidget.type == .pomodoro else { return }
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.pomodoroSoundName) { _, _ in
            guard workingWidget.type == .pomodoro else { return }
            onUpdate(workingWidget)
        }
        .onChange(of: workingWidget.pomodoroNotificationsEnabled) { _, isEnabled in
            guard workingWidget.type == .pomodoro else { return }
            if isEnabled {
                requestPomodoroNotificationAuthorization()
            }
            onUpdate(workingWidget)
        }
    }

    private func apply(location: WidgetLocation) {
        workingWidget.location = location
        onUpdate(workingWidget)
    }

    private var panelContent: some View {
        VStack(spacing: 16) {
            handle

            ScrollView {
                VStack(spacing: 12) {
                    if workingWidget.type == .eisenhower {
                        WidgetSettingsGroup(title: localization.text(.widgetActionsSection)) {
                            WidgetSettingsRowButton(title: localization.text(.widgetEisenhowerManageTasks), action: openEisenhowerTasks) {
                                IconButton(systemName: "checklist", isSelected: true)
                            }
                        }
                    }
                    WidgetGeneralSettingsSection(widget: $workingWidget,
                                                 isLocationPickerPresented: $showLocationPicker,
                                                 showWeather: $showWeather,
                                                 showManageHabits: $showManageHabits,
                                                 showCryptoSearch: $showCryptoSearch)
                    WidgetAppearanceSettingsSection(widget: $workingWidget,
                                                    onColorPicker: { activeColorRole = $0 },
                                                    onBackgroundPicker: { showBackgroundPicker = true })
                                                    WidgetBehaviorSettingsSection(sizeSelection: sizeSelectionBinding,
                                                                              isPinnedTop: pinnedBinding,
                                                                              lockPosition: lockedBinding,
                                                                              availableSizes: workingWidget.type.availableSizes)
                    WidgetManagementSettingsSection(onAddWidgets: openSidePanel,
                                                    onShowGeneralSettings: openGeneralSettings,
                                                    onDelete: deleteWidget)
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(maxHeight: 520)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .frame(minHeight: 400)
    }

    private var handle: some View {
        Capsule()
            .fill(Color.white.opacity(0.4))
            .frame(width: 38, height: 5)
            .padding(.top, 4)
    }

    private var sizeSelectionBinding: Binding<WidgetSizeOption> {
        Binding(
            get: { workingWidget.sizeOption },
            set: { newValue in
                workingWidget.applySizeOption(newValue)
                onUpdate(workingWidget)
            }
        )
    }

    private var pinnedBinding: Binding<Bool> {
        Binding(
            get: { isPinnedTop },
            set: { newValue in
                isPinnedTop = newValue
                workingWidget.isPinned = newValue
                onUpdate(workingWidget)
            }
        )
    }

    private var lockedBinding: Binding<Bool> {
        Binding(
            get: { lockPosition },
            set: { newValue in
                lockPosition = newValue
                workingWidget.isPositionLocked = newValue
                onUpdate(workingWidget)
            }
        )
    }

    private func colorSelectionBinding(for role: WidgetColorRole) -> Binding<String?> {
        switch role {
        case .main:
            return $workingWidget.mainColorName
        case .secondary:
            return $workingWidget.secondaryColorName
        }
    }

    private func colorIntensityBinding(for role: WidgetColorRole) -> Binding<Double> {
        switch role {
        case .main:
            return $workingWidget.mainColorIntensity
        case .secondary:
            return $workingWidget.secondaryColorIntensity
        }
    }

    private var backgroundStyleBinding: Binding<BackgroundStyle> {
        Binding(
            get: { workingWidget.backgroundStyle ?? .palette },
            set: { newValue in
                workingWidget.backgroundStyle = newValue
                onUpdate(workingWidget)
            }
        )
    }

    private var gradientTypeBinding: Binding<BackgroundGradientType> {
        Binding(
            get: { workingWidget.gradientType ?? .linear },
            set: { newValue in
                workingWidget.gradientType = newValue
                onUpdate(workingWidget)
            }
        )
    }

    private var gradientAngleBinding: Binding<Double> {
        Binding(
            get: { workingWidget.gradientAngle ?? 0 },
            set: { newValue in
                workingWidget.gradientAngle = newValue
                onUpdate(workingWidget)
            }
        )
    }

    private func openSidePanel() {
        manager.showSidePanel()
    }

    private func openGeneralSettings() {
        manager.showGeneralSettings()
    }

    private func openEisenhowerTasks() {
        manager.showEisenhowerTasks(for: workingWidget.id)
    }

    private func deleteWidget() {
        onDeleteCallback?(workingWidget.id)
    }

    private func requestPomodoroNotificationAuthorization() {
#if os(macOS)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
#endif
    }

    private func applyPomodoroDurationChange(phase: PomodoroPhase, minutes: Int) {
        guard workingWidget.type == .pomodoro else { return }
        let duration = TimeInterval(minutes * 60)
        let now = manager.sharedDate

        if workingWidget.pomodoroPhase == phase {
            if workingWidget.pomodoroIsRunning {
                workingWidget.pomodoroEndDate = now.addingTimeInterval(duration)
                workingWidget.pomodoroRemaining = nil
            } else {
                workingWidget.pomodoroEndDate = nil
                workingWidget.pomodoroRemaining = duration
            }
        }

        onUpdate(workingWidget)
    }

    private func deleteCustomHabit(_ habit: CustomHabit) {
        let context = manager.modelContainer.mainContext
        let descriptor = FetchDescriptor<HabitEntry>()
        let linked = (try? context.fetch(descriptor)) ?? []
        let affected = linked.filter { $0.customHabitID == habit.id }
        affected.forEach { entry in
            entry.customHabitID = nil
            entry.habitKind = .drinkWater
            entry.updatedAt = Date()
        }
        context.delete(habit)
    }
}

// MARK: - Location Picker
private struct WidgetLocationPickerView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Binding var selection: WidgetLocation
    let onSelect: (WidgetLocation) -> Void

    @State private var searchText = ""
    @StateObject private var searchService = LocationSearchService()

    var body: some View {
        VStack(spacing: 12) {
            pickerHeader
            searchField

            ScrollView {
                VStack(spacing: 10) {
                    LocationOptionRow(title: localization.text(.locationCurrentLocation),
                                      subtitle: nil,
                                      icon: "location.fill",
                                      isSelected: selection.mode == .current) {
                        select(.current)
                    }

                    if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        searchPlaceholder
                    } else if searchService.isSearching {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                            .padding(.top, 30)
                    } else if searchService.results.isEmpty {
                        Text(localization.text(.locationNoResults))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.top, 20)
                    } else {
                        ForEach(searchService.results) { result in
                            LocationOptionRow(title: result.title,
                                              subtitle: result.subtitle,
                                              icon: "mappin.and.ellipse",
                                              isSelected: isResultSelected(result)) {
                                select(result.widgetLocation)
                            }
                        }
                    }
                }
                .padding(.vertical, 6)
            }
        }
        .padding(18)
        .frame(width: 360, height: 520)
        .background(
            RoundedRectangle(cornerRadius: 36, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 36, style: .continuous)
                        .stroke(Color.white.opacity(0.12))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .onChange(of: searchText) { _, newValue in
            searchService.update(query: newValue, locale: localization.selectedLanguage.locale)
        }
        .onAppear {
            searchText = ""
            searchService.reset()
        }
        .onDisappear {
            searchService.reset()
        }
    }

    private var pickerHeader: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Label(localization.text(.back), systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text(localization.text(.widgetLocationSection))
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Spacer()
                .frame(width: 60)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.6))

            TextField(localization.text(.locationSearchPlaceholder), text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var searchPlaceholder: some View {
        Text(localization.text(.locationSearchHelp))
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white.opacity(0.65))
            .multilineTextAlignment(.center)
            .padding(.top, 24)
            .padding(.horizontal, 8)
    }

    private func isResultSelected(_ result: LocationSearchResult) -> Bool {
        selection.mode == .custom &&
        selection.city == result.title &&
        selection.region == result.subtitle
    }

    private func select(_ location: WidgetLocation) {
        selection = location
        onSelect(location)
        isPresented = false
    }
}

private struct LocationOptionRow: View {
    let title: String
    let subtitle: String?
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.yellow)
                }
            }
            .foregroundColor(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(Color.black.opacity(0.18))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Color Picker

//private struct WidgetColorPickerView: View {
//    ...
//}

private struct PaletteColorOption: Identifiable {
    let id = UUID()
    let assetName: String

    static let defaultPalette: [PaletteColorOption] = [
        "PaletteYellow", "PaletteYellow2", "PaletteYellow3", "PaletteYellow4",
        "PaletteGreen", "PaletteGreen2", "PaletteGreen3", "PaletteGreen4",
        "PaletteCyan", "PaletteCyan2", "PaletteCyan3", "PaletteCyan4",
        "PaletteTeal", "PaletteTeal2", "PaletteTeal3", "PaletteTeal4",
        "PalettePink", "PalettePink2", "PalettePink3", "PalettePink4",
        "PaletteRed", "PaletteRed2", "PaletteRed3", "PaletteRed4",
        "PaletteGrey", "PaletteGrey2", "PaletteGrey3", "PaletteGrey4",
        "PaletteBlack", "PaletteWhite", "AppYellow"
    ].map { PaletteColorOption(assetName: $0) }
}

// MARK: - Color Wheel

private struct ColorWheelControl: View {
    @Binding var color: Color
    @State private var hsb = HSBColor(hue: 0, saturation: 0, brightness: 1, alpha: 1)

    private static let hueGradient: [Color] = [
        .red, .yellow, .green, .cyan, .blue, .purple, .red
    ]

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = diameter / 2
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let indicator = indicatorPosition(center: center, radius: radius)

            ZStack {
                Circle()
                    .fill(
                        AngularGradient(gradient: Gradient(colors: Self.hueGradient),
                                        center: .center)
                    )
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [.white, .clear]),
                                               center: .center,
                                               startRadius: 0,
                                               endRadius: radius)
                            )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateColor(at: value.location, center: center, radius: radius)
                            }
                            .onEnded { value in
                                updateColor(at: value.location, center: center, radius: radius)
                            }
                    )

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(Circle().fill(color))
                    .shadow(color: .clear, radius: 0)
                    .frame(width: 18, height: 18)
                    .position(indicator)
            }
            .onAppear {
                hsb = HSBColor(color: color)
            }
            .onChange(of: color) { _, newValue in
                hsb = HSBColor(color: newValue)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func indicatorPosition(center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = 2 * .pi * CGFloat(hsb.hue)
        let distance = CGFloat(hsb.saturation) * radius
        return CGPoint(
            x: center.x + distance * cos(angle),
            y: center.y + distance * sin(angle)
        )
    }

    private func updateColor(at point: CGPoint, center: CGPoint, radius: CGFloat) {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        var hue = atan2(dy, dx) / (2 * .pi)
        if hue < 0 { hue += 1 }
        let distance = min(max(Double(hypot(dx, dy)), 0), Double(radius))
        let saturation = distance / Double(radius)

        hsb = HSBColor(hue: hue, saturation: saturation, brightness: hsb.brightness, alpha: 1)
        color = hsb.color
    }
}

private struct HSBColor {
    var hue: Double
    var saturation: Double
    var brightness: Double
    var alpha: Double

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }

    init(hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }

    init(color: Color) {
#if os(macOS)
        let native = NSColor(color).usingColorSpace(.sRGB)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        native?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
#else
        let native = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        native.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
#endif
        self.hue = Double(hue)
        self.saturation = Double(saturation)
        self.brightness = Double(brightness)
        self.alpha = Double(alpha)
    }
}
