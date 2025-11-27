import SwiftUI
#if os(macOS)
import AppKit
import UniformTypeIdentifiers
#endif

struct AppearanceSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var manager: WidgetManager
    @State private var primaryColor: ColorAccent = .system
    @State private var secondaryColor: ColorAccent = .system
    @State private var backgroundStyle: BackgroundStyle = .photo
    @State private var blurBackground = false
    @State private var primaryColorName: String?
    @State private var primaryIntensity: Double = 1.0
    @State private var secondaryColorName: String?
    @State private var secondaryIntensity: Double = 1.0
    @State private var activeColorRole: WidgetColorRole?
    @State private var backgroundColorName: String?
    @State private var backgroundIntensity: Double = 1.0
    @State private var isBackgroundPickerPresented = false
    @State private var didAppear = false
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
    @State private var showResetConfirm = false

    private let primaryColorKey = "appearance.primaryColorName"
    private let primaryIntensityKey = "appearance.primaryIntensity"
    private let secondaryColorKey = "appearance.secondaryColorName"
    private let secondaryIntensityKey = "appearance.secondaryIntensity"
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
    private let backgroundHideKey = "appearance.background.hide"
    private let appearanceColorDidChange = Notification.Name("appearance.colors.changed")
    private let appearanceBackgroundDidChange = Notification.Name("appearance.background.changed")
    private let backgroundImageBookmarkKey = "appearance.backgroundImageBookmark"
    private let backgroundImagePathKey = "appearance.backgroundImagePath"

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 18) {
                header

                ScrollView {
                    VStack(spacing: 22) {
                        section(title: localization.text(.appearanceColorsSection)) {
                            VStack(spacing: 12) {
                                colorButtonRow(title: localization.text(.appearancePrimaryColor), role: .main)
                                colorButtonRow(title: localization.text(.appearanceSecondaryColor), role: .secondary)
                            }
                        }

                        section(title: localization.text(.appearanceBackgroundSection)) {
                            VStack(alignment: .leading, spacing: 16) {
                                Picker("", selection: $backgroundStyle) {
                                    ForEach(BackgroundStyle.allCases) { style in
                                        Label(localization.text(style.localizationKey), systemImage: style.systemImage)
                                            .labelStyle(.iconOnly)
                                        .tag(style)
                                    }
                                }
                                .pickerStyle(.segmented)

                                ZStack(alignment: .topLeading) {
                                    backgroundPaletteButton
                                        .opacity(backgroundStyle == .palette ? 1 : 0)
                                        .allowsHitTesting(backgroundStyle == .palette)

                                    photoPickerRow
                                        .opacity(backgroundStyle == .photo ? 1 : 0)
                                        .allowsHitTesting(backgroundStyle == .photo)

                                    gradientControls
                                        .opacity(backgroundStyle == .gradient ? 1 : 0)
                                        .allowsHitTesting(backgroundStyle == .gradient)
                                }

                                Toggle(localization.text(.appearanceBlurBackground), isOn: $blurBackground)
                                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                            }
                        }

                        section(title: localization.text(.appearanceResetSection)) {
                            Button(localization.text(.appearanceResetButton)) {
                                showResetConfirm = true
                            }
                            .frame(maxWidth: .infinity)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.bottom, 12)
                }
            }
            .padding(.horizontal, 24)
            .frame(maxWidth: .infinity)
            .onAppear {
                loadColors()
                loadBackgroundSettings()
                didAppear = true
                blurBackground = manager.globalBackgroundHidden
            }
            .onChange(of: backgroundStyle) { _, newValue in
                guard didAppear else { return }
                if newValue != .palette {
                    isBackgroundPickerPresented = false
                }
                persistBackgroundSettings()
            }
            .onChange(of: blurBackground) { _, newValue in
                guard didAppear else { return }
                manager.setGlobalBackgroundHidden(newValue)
            }
            .onChange(of: gradientColor1Name) { _, _ in persistGradientSettings() }
            .onChange(of: gradientColor2Name) { _, _ in persistGradientSettings() }
            .onChange(of: gradientColor1Opacity) { _, _ in persistGradientSettings() }
            .onChange(of: gradientColor2Opacity) { _, _ in persistGradientSettings() }
            .onChange(of: gradientColor1Position) { _, _ in persistGradientSettings() }
            .onChange(of: gradientColor2Position) { _, _ in persistGradientSettings() }
            .onChange(of: gradientType) { _, _ in persistGradientSettings() }
            .onChange(of: gradientAngle) { _, _ in persistGradientSettings() }
            .alert("Сброс оформления", isPresented: $showResetConfirm) {
                Button("Сбросить глобальные", role: .destructive) {
                    resetGlobalAppearance()
                }
                Button("Сбросить глобальные и виджет настройки", role: .destructive) {
                    resetAllAppearance()
                }
                Button("Отменить", role: .cancel) {}
            } message: {
                Text("Вернуть внешний вид к настройкам по умолчанию. Действие нельзя отменить.")
            }

            if let role = activeColorRole {
                colorPickerOverlay(for: role)
            }

            if isBackgroundPickerPresented && backgroundStyle == .palette {
                backgroundColorPickerOverlay
            }

            if isGradientPicker1Presented && backgroundStyle == .gradient {
                gradientColorPickerOverlay(title: "Фон — цвет №1",
                                           selection: $gradientColor1Name,
                                           intensity: $gradientColor1Opacity,
                                           isPresented: $isGradientPicker1Presented)
            }

            if isGradientPicker2Presented && backgroundStyle == .gradient {
                gradientColorPickerOverlay(title: "Фон — цвет №2",
                                           selection: $gradientColor2Name,
                                           intensity: $gradientColor2Opacity,
                                           isPresented: $isGradientPicker2Presented)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.text(.categoryAppearance))
                .font(.title3.weight(.semibold))
            Text(localization.text(.appearanceSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
        )
    }

    private func colorButtonRow(title: String, role: WidgetColorRole) -> some View {
        Button {
            activeColorRole = role
        } label: {
            HStack(spacing: 12) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                ColorChip(colorName: selectionBinding(for: role).wrappedValue,
                          intensity: intensityBinding(for: role).wrappedValue)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var backgroundPaletteButton: some View {
        Button {
            isBackgroundPickerPresented = true
        } label: {
            HStack(spacing: 12) {
                Text(localization.text(.appearanceBackgroundPalette))
                    .font(.headline.weight(.semibold))
                Spacer()
                ColorChip(colorName: backgroundColorName, intensity: backgroundIntensity)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var gradientControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            gradientColorRow(title: "Цвет №1",
                             colorName: gradientColor1Name,
                             opacity: gradientColor1Opacity,
                             position: gradientColor1Position,
                             onPick: { isGradientPicker1Presented = true },
                             onOpacityChange: { gradientColor1Opacity = $0 },
                             onPositionChange: { gradientColor1Position = $0 })

            gradientColorRow(title: "Цвет №2",
                             colorName: gradientColor2Name,
                             opacity: gradientColor2Opacity,
                             position: gradientColor2Position,
                             onPick: { isGradientPicker2Presented = true },
                             onOpacityChange: { gradientColor2Opacity = $0 },
                             onPositionChange: { gradientColor2Position = $0 })

            if gradientColor2Name != nil {
                VStack(alignment: .leading, spacing: 10) {
                    Picker("Тип", selection: $gradientType) {
                        ForEach(BackgroundGradientType.allCases) { type in
                            Text(type.localizedTitle).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                    HStack {
                        Text("Угол")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(Int(gradientAngle))°")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $gradientAngle, in: 0...360, step: 1)
                }
                .padding(.top, 4)
            }
        }
    }

    private func gradientColorRow(title: String,
                                  colorName: String?,
                                  opacity: Double,
                                  position: Double,
                                  onPick: @escaping () -> Void,
                                  onOpacityChange: @escaping (Double) -> Void,
                                  onPositionChange: @escaping (Double) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                onPick()
            } label: {
                HStack(spacing: 12) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Spacer()
                    ColorChip(colorName: colorName, intensity: opacity)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color.white.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            if colorName != nil {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Прозрачность")
                        .font(.subheadline.weight(.semibold))
                    Slider(value: Binding(
                        get: { opacity },
                        set: { onOpacityChange($0) }
                    ), in: 0...1)
                    HStack {
                        Text("Позиция")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(Int(position * 100)) %")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    Slider(value: Binding(
                        get: { position },
                        set: { onPositionChange($0) }
                    ), in: 0...1)
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private func colorPickerOverlay(for role: WidgetColorRole) -> some View {
        WidgetColorPickerView(title: role.title,
                              isPresented: Binding(
                                get: { activeColorRole != nil },
                                set: { if !$0 { activeColorRole = nil } }
                              ),
                              selection: selectionBinding(for: role),
                              intensity: intensityBinding(for: role)) {
            persistColors()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var backgroundColorPickerOverlay: some View {
        WidgetColorPickerView(title: localization.text(.appearanceBackgroundSection),
                              isPresented: $isBackgroundPickerPresented,
                              selection: $backgroundColorName,
                              intensity: $backgroundIntensity) {
            persistBackgroundSettings()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var photoPickerRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.text(.appearancePhotoTitle))
                        .font(.headline.weight(.semibold))
                    if let url = backgroundImageURL {
                        Text(url.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    } else {
                        Text(localization.text(.appearancePhotoSubtitle))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button(localization.text(.appearanceBrowseButton)) {
                    pickBackgroundPhoto()
                }
                .buttonStyle(.borderedProminent)
                .tint(.orange)
            }
        }
    }

    private func gradientColorPickerOverlay(title: String,
                                            selection: Binding<String?>,
                                            intensity: Binding<Double>,
                                            isPresented: Binding<Bool>) -> some View {
        WidgetColorPickerView(title: title,
                              isPresented: isPresented,
                              selection: selection,
                              intensity: intensity) {
            persistGradientSettings()
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private func selectionBinding(for role: WidgetColorRole) -> Binding<String?> {
        switch role {
        case .main:
            return Binding(
                get: { primaryColorName },
                set: { newValue in
                    primaryColorName = newValue
                    persistColors()
                }
            )
        case .secondary:
            return Binding(
                get: { secondaryColorName },
                set: { newValue in
                    secondaryColorName = newValue
                    persistColors()
                }
            )
        }
    }

    private func intensityBinding(for role: WidgetColorRole) -> Binding<Double> {
        switch role {
        case .main:
            return Binding(
                get: { primaryIntensity },
                set: { newValue in
                    primaryIntensity = newValue
                    persistColors()
                }
            )
        case .secondary:
            return Binding(
                get: { secondaryIntensity },
                set: { newValue in
                    secondaryIntensity = newValue
                    persistColors()
                }
            )
        }
    }

    private func persistColors() {
        let defaults = UserDefaults.standard
        defaults.set(primaryColorName, forKey: primaryColorKey)
        defaults.set(primaryIntensity, forKey: primaryIntensityKey)
        defaults.set(secondaryColorName, forKey: secondaryColorKey)
        defaults.set(secondaryIntensity, forKey: secondaryIntensityKey)
        NotificationCenter.default.post(name: appearanceColorDidChange, object: nil)
    }

    private func loadColors() {
        let defaults = UserDefaults.standard
        primaryColorName = defaults.string(forKey: primaryColorKey)
        secondaryColorName = defaults.string(forKey: secondaryColorKey)
        primaryIntensity = defaults.object(forKey: primaryIntensityKey) as? Double ?? 1.0
        secondaryIntensity = defaults.object(forKey: secondaryIntensityKey) as? Double ?? 1.0
    }

    private func persistBackgroundSettings() {
        let defaults = UserDefaults.standard
        defaults.set(backgroundStyle.rawValue, forKey: backgroundStyleKey)
        defaults.set(backgroundColorName, forKey: backgroundColorKey)
        defaults.set(backgroundIntensity, forKey: backgroundIntensityKey)
        NotificationCenter.default.post(name: appearanceBackgroundDidChange, object: nil)
    }

    private func loadBackgroundSettings() {
        let defaults = UserDefaults.standard
        if let stored = defaults.string(forKey: backgroundStyleKey),
           let style = BackgroundStyle(rawValue: stored) {
            backgroundStyle = style
        }
        backgroundColorName = defaults.string(forKey: backgroundColorKey)
        backgroundIntensity = defaults.object(forKey: backgroundIntensityKey) as? Double ?? 1.0
        blurBackground = manager.globalBackgroundHidden
        loadBackgroundImage()
        gradientColor1Name = defaults.string(forKey: gradientColor1Key)
        gradientColor2Name = defaults.string(forKey: gradientColor2Key)
        gradientColor1Opacity = defaults.object(forKey: gradientColor1OpacityKey) as? Double ?? 1.0
        gradientColor2Opacity = defaults.object(forKey: gradientColor2OpacityKey) as? Double ?? 1.0
        gradientColor1Position = defaults.object(forKey: gradientColor1PositionKey) as? Double ?? 0.0
        gradientColor2Position = defaults.object(forKey: gradientColor2PositionKey) as? Double ?? 1.0
        if let storedType = defaults.string(forKey: gradientTypeKey),
           let loadedType = BackgroundGradientType(rawValue: storedType) {
            gradientType = loadedType
        }
        gradientAngle = defaults.object(forKey: gradientAngleKey) as? Double ?? 0.0
    }

    private func persistGradientSettings() {
        let defaults = UserDefaults.standard
        defaults.set(gradientColor1Name, forKey: gradientColor1Key)
        defaults.set(gradientColor2Name, forKey: gradientColor2Key)
        defaults.set(gradientColor1Opacity, forKey: gradientColor1OpacityKey)
        defaults.set(gradientColor2Opacity, forKey: gradientColor2OpacityKey)
        defaults.set(gradientColor1Position, forKey: gradientColor1PositionKey)
        defaults.set(gradientColor2Position, forKey: gradientColor2PositionKey)
        defaults.set(gradientType.rawValue, forKey: gradientTypeKey)
        defaults.set(gradientAngle, forKey: gradientAngleKey)
        NotificationCenter.default.post(name: appearanceBackgroundDidChange, object: nil)
    }

    private func pickBackgroundPhoto() {
        #if os(macOS)
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image]
        panel.prompt = localization.text(.appearanceBrowseButton)
        if panel.runModal() == .OK, let url = panel.url {
            let copied = copyToAppSupport(url: url)
            backgroundImageURL = copied ?? url
            saveBackgroundImageBookmark(url)
            if let copied {
                UserDefaults.standard.set(copied.path, forKey: backgroundImagePathKey)
            }
            NotificationCenter.default.post(name: appearanceBackgroundDidChange, object: nil)
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
            if stale, let refreshed = try? url.bookmarkData(options: .withSecurityScope,
                                                            includingResourceValuesForKeys: nil,
                                                            relativeTo: nil) {
                defaults.set(refreshed, forKey: backgroundImageBookmarkKey)
            }
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

    private func resetGlobalAppearance() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: primaryColorKey)
        defaults.removeObject(forKey: primaryIntensityKey)
        defaults.removeObject(forKey: secondaryColorKey)
        defaults.removeObject(forKey: secondaryIntensityKey)
        defaults.removeObject(forKey: backgroundStyleKey)
        defaults.removeObject(forKey: backgroundColorKey)
        defaults.removeObject(forKey: backgroundIntensityKey)
        defaults.removeObject(forKey: backgroundImageBookmarkKey)
        defaults.removeObject(forKey: backgroundImagePathKey)
        defaults.removeObject(forKey: gradientColor1Key)
        defaults.removeObject(forKey: gradientColor2Key)
        defaults.removeObject(forKey: gradientColor1OpacityKey)
        defaults.removeObject(forKey: gradientColor2OpacityKey)
        defaults.removeObject(forKey: gradientColor1PositionKey)
        defaults.removeObject(forKey: gradientColor2PositionKey)
        defaults.removeObject(forKey: gradientTypeKey)
        defaults.removeObject(forKey: gradientAngleKey)
        defaults.removeObject(forKey: backgroundHideKey)
        manager.setGlobalBackgroundHidden(false)
        NotificationCenter.default.post(name: appearanceColorDidChange, object: nil)
        NotificationCenter.default.post(name: appearanceBackgroundDidChange, object: nil)
        loadColors()
        loadBackgroundSettings()
    }

    private func resetAllAppearance() {
        resetGlobalAppearance()
        NotificationCenter.default.post(name: Notification.Name("widgets.reset.appearance"), object: nil)
    }
}

enum ColorAccent: String, CaseIterable, Identifiable {
    case system = "system"
    case custom = "custom"
    case orange = "orange"
    case purple = "purple"

    var id: String { rawValue }
}

enum BackgroundStyle: String, CaseIterable, Identifiable, Codable {
    case solid
    case palette
    case gradient
    case photo

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .solid: return "square.fill"
        case .palette: return "paintpalette"
        case .gradient: return "square.split.2x1"
        case .photo: return "photo"
        }
    }
}

private extension ColorAccent {
    var localizationKey: LocalizationKey {
        switch self {
        case .system: return .appearanceAccentSystem
        case .custom: return .appearanceAccentCustom
        case .orange: return .appearanceAccentOrange
        case .purple: return .appearanceAccentPurple
        }
    }
}

private extension BackgroundStyle {
    var localizationKey: LocalizationKey {
        switch self {
        case .solid: return .appearanceBackgroundSolid
        case .palette: return .appearanceBackgroundPalette
        case .gradient: return .appearanceBackgroundGradient
        case .photo: return .appearanceBackgroundPhoto
        }
    }
}

enum BackgroundGradientType: String, CaseIterable, Identifiable, Codable {
    case linear
    case radial
    case angular

    var id: String { rawValue }

    var localizedTitle: String {
        switch self {
        case .linear: return "Линейный"
        case .radial: return "Радиальный"
        case .angular: return "Круговой"
        }
    }
}
