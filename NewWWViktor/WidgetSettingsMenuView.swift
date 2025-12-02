import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
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
    @State private var showWeather = false
    @State private var isPinnedTop = false
    @State private var lockPosition = false
    @State private var showBackgroundPicker = false
    @State private var backgroundStyle: BackgroundStyle = .photo
    @State private var backgroundColorName: String?
    @State private var backgroundIntensity: Double = 1.0
    @State private var isPalettePickerPresented = false
    @State private var gradientColor1Name: String?
    @State private var gradientColor2Name: String?
    @State private var gradientColor1Opacity: Double = 1.0
    @State private var gradientColor2Opacity: Double = 1.0
    @State private var gradientColor1Position: Double = 0.0
    @State private var gradientColor2Position: Double = 1.0
    @State private var gradientType: BackgroundGradientType = .linear
    @State private var gradientAngle: Double = 0.0
    @State private var isGradientPicker1Presented = false
    @State private var isGradientPicker2Presented = false
    @State private var backgroundImageURL: URL?
    @State private var useGlobalBackground = true

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
        let isOverlayPresented = showLocationPicker || isColorPickerPresented || showBackgroundPicker

        return ZStack {
            panelContent
                .disabled(isOverlayPresented)
                // Оставляем фон без затемнения при показе оверлеев, чтобы не было темной подложки позади палитры.
                .blur(radius: 0)
                .opacity(1)

            if showLocationPicker {
                WidgetLocationPickerView(isPresented: $showLocationPicker,
                                         selection: $workingWidget.location) { newLocation in
                    apply(location: newLocation)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if let colorRole = activeColorRole {
                WidgetColorPickerView(title: colorRole.title(using: localization),
                                      isPresented: Binding(
                                        get: { activeColorRole != nil },
                                        set: { shouldShow in
                                            if !shouldShow { activeColorRole = nil }
                                        }
                                      ),
                                      selection: colorSelectionBinding(for: colorRole),
                                      intensity: colorIntensityBinding(for: colorRole)) {
                    onUpdate(workingWidget)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showBackgroundPicker {
                WidgetBackgroundPickerSheet(isPresented: $showBackgroundPicker,
                                            backgroundStyle: Binding(
                                                get: { workingWidget.backgroundStyle ?? manager.globalBackgroundStyle },
                                                set: { workingWidget.backgroundStyle = $0; onUpdate(workingWidget) }
                                            ),
                                            backgroundColorName: Binding(
                                                get: { workingWidget.backgroundColorName ?? manager.globalBackgroundColorName },
                                                set: { workingWidget.backgroundColorName = $0; onUpdate(workingWidget) }
                                            ),
                                            backgroundIntensity: Binding(
                                                get: { workingWidget.backgroundIntensity },
                                                set: { workingWidget.backgroundIntensity = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientColor1Name: Binding(
                                                get: { workingWidget.gradientColor1Name ?? manager.globalGradientColor1Name },
                                                set: { workingWidget.gradientColor1Name = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientColor2Name: Binding(
                                                get: { workingWidget.gradientColor2Name ?? manager.globalGradientColor2Name },
                                                set: { workingWidget.gradientColor2Name = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientColor1Opacity: Binding(
                                                get: { workingWidget.gradientColor1Opacity },
                                                set: { workingWidget.gradientColor1Opacity = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientColor2Opacity: Binding(
                                                get: { workingWidget.gradientColor2Opacity },
                                                set: { workingWidget.gradientColor2Opacity = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientColor1Position: Binding(
                                                get: { workingWidget.gradientColor1Position },
                                                set: { workingWidget.gradientColor1Position = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientColor2Position: Binding(
                                                get: { workingWidget.gradientColor2Position },
                                                set: { workingWidget.gradientColor2Position = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientType: Binding(
                                                get: { workingWidget.gradientType ?? manager.globalGradientType },
                                                set: { workingWidget.gradientType = $0; onUpdate(workingWidget) }
                                            ),
                                            gradientAngle: Binding(
                                                get: { workingWidget.gradientAngle ?? manager.globalGradientAngle },
                                                set: { workingWidget.gradientAngle = $0; onUpdate(workingWidget) }
                                            ),
                                            backgroundImageURL: Binding(
                                                get: { workingWidget.backgroundImagePath.flatMap { URL(fileURLWithPath: $0) } },
                                                set: { workingWidget.backgroundImagePath = $0?.path; onUpdate(workingWidget) }
                                            ),
                                            isUsingGlobalBackground: Binding(
                                                get: { workingWidget.backgroundStyle == nil },
                                                set: { useGlobal in
                                                    if useGlobal {
                                                        workingWidget.backgroundStyle = nil
                                                        workingWidget.backgroundColorName = nil
                                                        workingWidget.backgroundIntensity = manager.globalBackgroundIntensity
                                                        workingWidget.backgroundImagePath = nil
                                                        workingWidget.gradientColor1Name = nil
                                                        workingWidget.gradientColor2Name = nil
                                                        workingWidget.gradientColor1Opacity = manager.globalGradientColor1Opacity
                                                        workingWidget.gradientColor2Opacity = manager.globalGradientColor2Opacity
                                                        workingWidget.gradientColor1Position = manager.globalGradientColor1Position
                                                        workingWidget.gradientColor2Position = manager.globalGradientColor2Position
                                                        workingWidget.gradientType = manager.globalGradientType
                                                        workingWidget.gradientAngle = manager.globalGradientAngle
                                                    } else {
                                                        workingWidget.backgroundStyle = manager.globalBackgroundStyle
                                                        workingWidget.backgroundIntensity = manager.globalBackgroundIntensity
                                                        workingWidget.backgroundColorName = manager.globalBackgroundColorName
                                                        workingWidget.gradientColor1Name = manager.globalGradientColor1Name
                                                        workingWidget.gradientColor2Name = manager.globalGradientColor2Name
                                                        workingWidget.gradientColor1Opacity = manager.globalGradientColor1Opacity
                                                        workingWidget.gradientColor2Opacity = manager.globalGradientColor2Opacity
                                                        workingWidget.gradientColor1Position = manager.globalGradientColor1Position
                                                        workingWidget.gradientColor2Position = manager.globalGradientColor2Position
                                                        workingWidget.gradientType = manager.globalGradientType
                                                        workingWidget.gradientAngle = manager.globalGradientAngle
                                                    }
                                                    onUpdate(workingWidget)
                                                }
                                            ),
                                            isGlobalContext: false,
                                            onApply: applyBackground)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showLocationPicker)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: isColorPickerPresented)
        .animation(.spring(response: 0.32, dampingFraction: 0.88), value: showBackgroundPicker)
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
        .onChange(of: workingWidget.isBackgroundHidden) { _, _ in
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
            WidgetGeneralSettingsSection(widget: $workingWidget,
                                         isLocationPickerPresented: $showLocationPicker,
                                         showWeather: $showWeather)
                WidgetAppearanceSettingsSection(widget: $workingWidget,
                                                onColorPicker: { activeColorRole = $0 },
                                                onBackgroundPicker: { showBackgroundPicker = true })
                    WidgetBehaviorSettingsSection(sizeSelection: sizeSelectionBinding,
                                                  isPinnedTop: pinnedBinding,
                                                  lockPosition: lockedBinding,
                                                  snapToGrid: snapToGridBinding)
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

    private var snapToGridBinding: Binding<Bool> {
        Binding(
            get: { manager.snapToGrid },
            set: { manager.snapToGrid = $0 }
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

    private func applyBackground() {
        onUpdate(workingWidget)
    }

    private func openSidePanel() {
        manager.showSidePanel()
    }

    private func openGeneralSettings() {
        manager.showGeneralSettings()
    }

    private func deleteWidget() {
        onDeleteCallback?(workingWidget.id)
    }
}

// MARK: - Location Picker
// Background Picker (global settings reuse)
private struct WidgetBackgroundPickerSheet: View {
    @EnvironmentObject private var localization: LocalizationManager
    @Binding var isPresented: Bool
    @Binding var backgroundStyle: BackgroundStyle
    @Binding var backgroundColorName: String?
    @Binding var backgroundIntensity: Double
    @Binding var gradientColor1Name: String?
    @Binding var gradientColor2Name: String?
    @Binding var gradientColor1Opacity: Double
    @Binding var gradientColor2Opacity: Double
    @Binding var gradientColor1Position: Double
    @Binding var gradientColor2Position: Double
    @Binding var gradientType: BackgroundGradientType
    @Binding var gradientAngle: Double
    @Binding var backgroundImageURL: URL?
    @Binding var isUsingGlobalBackground: Bool
    let isGlobalContext: Bool
    var onApply: () -> Void = {}

    private let backgroundStyleKey = "appearance.backgroundStyle"
    private let backgroundColorKey = "appearance.backgroundColorName"
    private let backgroundIntensityKey = "appearance.backgroundColorIntensity"
    private let gradientColor1Key = "appearance.gradient.color1"
    private let gradientColor2Key = "appearance.gradient.color2"
    private let gradientColor1OpacityKey = "appearance.gradient.color1.opacity"
    private let gradientColor2OpacityKey = "appearance.gradient.color2.opacity"
    private let gradientColor1PositionKey = "appearance.gradient.color1.position"
    private let gradientColor2PositionKey = "appearance.gradient.color2.position"
    private let gradientTypeKey = "appearance.gradient.type"
    private let gradientAngleKey = "appearance.gradient.angle"
    private let backgroundImageBookmarkKey = "appearance.backgroundImageBookmark"
    private let backgroundImagePathKey = "appearance.backgroundImagePath"

    @State private var showPalettePicker = false
    @State private var showGradientPicker1 = false
    @State private var showGradientPicker2 = false

    var body: some View {
        ZStack {
            content
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
                .shadow(color: .black.opacity(0.35), radius: 25, x: 0, y: 20)

            if showPalettePicker {
                WidgetColorPickerView(title: "Фон",
                                      isPresented: $showPalettePicker,
                                      selection: $backgroundColorName,
                                      intensity: $backgroundIntensity) {
                    persistBackgroundSettings()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showGradientPicker1 {
                WidgetColorPickerView(title: "Фон — цвет №1",
                                      isPresented: $showGradientPicker1,
                                      selection: $gradientColor1Name,
                                      intensity: $gradientColor1Opacity) {
                    persistGradientSettings()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }

            if showGradientPicker2 {
                WidgetColorPickerView(title: "Фон — цвет №2",
                                      isPresented: $showGradientPicker2,
                                      selection: $gradientColor2Name,
                                      intensity: $gradientColor2Opacity) {
                    persistGradientSettings()
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .onAppear { loadBackgroundSettings() }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 12) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isGlobalContext {
                        Toggle("Использовать глобальный фон", isOn: $isUsingGlobalBackground)
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                            .onChange(of: isUsingGlobalBackground) { _, newValue in
                                if newValue {
                                    // Reset to global
                                    backgroundStyle = .photo
                                    backgroundColorName = nil
                                    backgroundImageURL = nil
                                    gradientColor1Name = nil
                                    gradientColor2Name = nil
                                }
                                onApply()
                            }
                            .padding(.bottom, 4)
                    }

                    Picker("", selection: $backgroundStyle) {
                        ForEach(BackgroundStyle.allCases) { style in
                            Label(styleTitle(style), systemImage: style.systemImage)
                                .labelStyle(.iconOnly)
                                .tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .disabled(isGlobalContext ? isUsingGlobalBackground : false)

                    if backgroundStyle == .palette && !(isGlobalContext ? isUsingGlobalBackground : false) {
                        backgroundPaletteButton
                    } else if backgroundStyle == .gradient && !(isGlobalContext ? isUsingGlobalBackground : false) {
                        gradientControls
                    } else if backgroundStyle == .photo && !(isGlobalContext ? isUsingGlobalBackground : false) {
                        photoControls
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 6)
                .padding(.bottom, 4)
            }
        }
        .padding(18)
    }

    private var header: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Label(localization.text(.back), systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundColor(.primary)

            Spacer()
            Text("Фон")
                .font(.headline.weight(.semibold))
            Spacer()
            Spacer().frame(width: 60)
        }
    }

    private var backgroundPaletteButton: some View {
        Button {
            showPalettePicker = true
        } label: {
            HStack(spacing: 12) {
                Text(localization.text(.paletteTitle))
                    .font(.headline.weight(.semibold))
                Spacer()
                ColorChip(colorName: backgroundColorName, intensity: backgroundIntensity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var gradientControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            gradientRow(title: "Цвет №1",
                        selection: $gradientColor1Name,
                        opacity: $gradientColor1Opacity,
                        position: $gradientColor1Position,
                        onPick: { showGradientPicker1 = true })

            gradientRow(title: "Цвет №2",
                        selection: $gradientColor2Name,
                        opacity: $gradientColor2Opacity,
                        position: $gradientColor2Position,
                        onPick: { showGradientPicker2 = true })

            if gradientColor2Name != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Тип")
                        .font(.subheadline.weight(.semibold))
                    Picker("", selection: $gradientType) {
                        ForEach(BackgroundGradientType.allCases) { type in
                            Text(type.localizedTitle).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Угол")
                        Spacer()
                        Text("\(Int(gradientAngle))°")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $gradientAngle, in: 0...360, step: 1) {
                        Text("Угол")
                    }
                }
            }
        }
    }

    private var photoControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Фото")
                        .font(.headline.weight(.semibold))
                    if let url = backgroundImageURL {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text("Выберите изображение для фона")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Обзор") {
                    pickBackgroundPhoto()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .onChange(of: backgroundImageURL) { _, _ in
                    persistBackgroundSettings()
                }
            }
        }
    }

    private func gradientRow(title: String,
                             selection: Binding<String?>,
                             opacity: Binding<Double>,
                             position: Binding<Double>,
                             onPick: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onPick) {
                HStack {
                    Text(title)
                    Spacer()
                    ColorChip(colorName: selection.wrappedValue, intensity: opacity.wrappedValue)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if selection.wrappedValue != nil {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Прозрачность")
                        .font(.subheadline.weight(.semibold))
                    Slider(value: opacity, in: 0...1)
                    HStack {
                        Text("Позиция")
                        Spacer()
                        Text("\(Int(position.wrappedValue * 100))%")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: position, in: 0...1)
                }
            }
        }
    }

    private func styleTitle(_ style: BackgroundStyle) -> String {
        switch style {
        case .solid: return "Цвет"
        case .palette: return "Палитра"
        case .gradient: return "Градиент"
        case .photo: return "Фото"
        }
    }

    private func persistBackgroundSettings() {
        guard isGlobalContext else {
            onApply()
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(backgroundStyle.rawValue, forKey: backgroundStyleKey)
        defaults.set(backgroundColorName, forKey: backgroundColorKey)
        defaults.set(backgroundIntensity, forKey: backgroundIntensityKey)
        NotificationCenter.default.post(name: Notification.Name("appearance.background.changed"), object: nil)
        onApply()
    }

    private func persistGradientSettings() {
        guard isGlobalContext else {
            onApply()
            return
        }
        let defaults = UserDefaults.standard
        defaults.set(gradientColor1Name, forKey: gradientColor1Key)
        defaults.set(gradientColor2Name, forKey: gradientColor2Key)
        defaults.set(gradientColor1Opacity, forKey: gradientColor1OpacityKey)
        defaults.set(gradientColor2Opacity, forKey: gradientColor2OpacityKey)
        defaults.set(gradientColor1Position, forKey: gradientColor1PositionKey)
        defaults.set(gradientColor2Position, forKey: gradientColor2PositionKey)
        defaults.set(gradientType.rawValue, forKey: gradientTypeKey)
        defaults.set(gradientAngle, forKey: gradientAngleKey)
        NotificationCenter.default.post(name: Notification.Name("appearance.background.changed"), object: nil)
        onApply()
    }

    private func loadBackgroundSettings() {
        guard isGlobalContext else { return }
        let defaults = UserDefaults.standard
        if let stored = defaults.string(forKey: backgroundStyleKey),
           let style = BackgroundStyle(rawValue: stored) {
            backgroundStyle = style
        }
        backgroundColorName = defaults.string(forKey: backgroundColorKey)
        backgroundIntensity = defaults.object(forKey: backgroundIntensityKey) as? Double ?? 1.0
        gradientColor1Name = defaults.string(forKey: gradientColor1Key)
        gradientColor2Name = defaults.string(forKey: gradientColor2Key)
        gradientColor1Opacity = defaults.object(forKey: gradientColor1OpacityKey) as? Double ?? 1.0
        gradientColor2Opacity = defaults.object(forKey: gradientColor2OpacityKey) as? Double ?? 1.0
        gradientColor1Position = defaults.object(forKey: gradientColor1PositionKey) as? Double ?? 0.0
        gradientColor2Position = defaults.object(forKey: gradientColor2PositionKey) as? Double ?? 1.0
        if let storedType = defaults.string(forKey: gradientTypeKey),
           let type = BackgroundGradientType(rawValue: storedType) {
            gradientType = type
        }
        gradientAngle = defaults.object(forKey: gradientAngleKey) as? Double ?? 0.0
        loadBackgroundImage()
    }

    private func pickBackgroundPhoto() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.prompt = "Выбрать"
        if panel.runModal() == .OK, let url = panel.url {
            let copied = copyToAppSupport(url: url)
            backgroundImageURL = copied ?? url
            if isGlobalContext {
                saveBackgroundImageBookmark(url)
                if let copied {
                    UserDefaults.standard.set(copied.path, forKey: backgroundImagePathKey)
                }
                NotificationCenter.default.post(name: Notification.Name("appearance.background.changed"), object: nil)
            }
            onApply()
        }
        #endif
    }

    private func saveBackgroundImageBookmark(_ url: URL) {
        #if os(macOS)
        do {
            let data = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
            UserDefaults.standard.set(data, forKey: backgroundImageBookmarkKey)
        } catch {
            print("Failed to save background image bookmark: \(error)")
        }
        #endif
    }

    private func loadBackgroundImage() {
        #if os(macOS)
        guard isGlobalContext else { return }
        let defaults = UserDefaults.standard
        if let storedPath = defaults.string(forKey: backgroundImagePathKey) {
            let url = URL(fileURLWithPath: storedPath)
            if FileManager.default.fileExists(atPath: url.path) {
                backgroundImageURL = url
                return
            }
        }
        guard let data = defaults.data(forKey: backgroundImageBookmarkKey) else { return }
        var stale = false
        if let url = try? URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &stale) {
            backgroundImageURL = url
        }
        #endif
    }

    private func copyToAppSupport(url: URL) -> URL? {
        #if os(macOS)
        do {
            let fm = FileManager.default
            let base = try fm.url(for: .applicationSupportDirectory,
                                  in: .userDomainMask,
                                  appropriateFor: nil,
                                  create: true)
            let dir = base.appendingPathComponent("NewWWViktorBackgrounds", isDirectory: true)
            if !fm.fileExists(atPath: dir.path) {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let dest = dir.appendingPathComponent(url.lastPathComponent)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            return dest
        } catch {
            print("Failed to copy background image: \(error)")
            return nil
        }
        #else
        return nil
        #endif
    }
}

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
                    LocationOptionRow(title: "Current Location",
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
                        Text("No results")
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
        .frame(width: 320, height: 440)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 25, x: 0, y: 20)
        .onChange(of: searchText) { _, newValue in
            searchService.update(query: newValue)
        }
    }

    private var pickerHeader: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Label("Back", systemImage: "chevron.left")
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

            TextField("Search city...", text: $searchText)
                .textFieldStyle(.plain)
                .foregroundColor(.white)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.white.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var searchPlaceholder: some View {
        Text("Enter a city name to change the zone.")
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
                    .shadow(color: .black.opacity(0.4), radius: 2)
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
