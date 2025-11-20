import SwiftUI

struct AppearanceSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var selectedTheme: ThemeOption = .system
    @State private var lightModePreview = true
    @State private var darkModePreview = true
    @State private var primaryColor: ColorAccent = .system
    @State private var secondaryColor: ColorAccent = .system
    @State private var backgroundStyle: BackgroundStyle = .photo
    @State private var imageSource: ImageSource = .photos
    @State private var blurBackground = true
    @State private var primaryColorName: String?
    @State private var primaryIntensity: Double = 1.0
    @State private var secondaryColorName: String?
    @State private var secondaryIntensity: Double = 1.0
    @State private var activeColorRole: WidgetColorRole?

    private let primaryColorKey = "appearance.primaryColorName"
    private let primaryIntensityKey = "appearance.primaryIntensity"
    private let secondaryColorKey = "appearance.secondaryColorName"
    private let secondaryIntensityKey = "appearance.secondaryIntensity"
    private let appearanceColorDidChange = Notification.Name("appearance.colors.changed")

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 18) {
                header

                ScrollView {
                    VStack(spacing: 22) {
                        section(title: localization.text(.appearanceColorThemeSection)) {
                            VStack(alignment: .leading, spacing: 14) {
                                Picker("", selection: $selectedTheme) {
                                    ForEach(ThemeOption.allCases) { option in
                                        Text(localization.text(option.localizationKey)).tag(option)
                                    }
                                }
                                .pickerStyle(.segmented)

                                modeToggleRow(title: localization.text(.appearanceLightModeTitle),
                                              description: localization.text(.appearanceLightModeDescription),
                                              isOn: $lightModePreview)

                                modeToggleRow(title: localization.text(.appearanceDarkModeTitle),
                                              description: localization.text(.appearanceDarkModeDescription),
                                              isOn: $darkModePreview)
                            }
                        }

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

                                Picker(localization.text(.appearanceImageSourceLabel), selection: $imageSource) {
                                    ForEach(ImageSource.allCases) { source in
                                        Text(localization.text(source.localizationKey)).tag(source)
                                    }
                                }
                                .frame(width: 220)

                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(localization.text(.appearancePhotoTitle))
                                            .font(.headline.weight(.semibold))
                                        Text(localization.text(.appearancePhotoSubtitle))
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(localization.text(.appearanceBrowseButton)) {}
                                        .buttonStyle(.borderedProminent)
                                        .tint(.orange)
                                }

                                Toggle(localization.text(.appearanceBlurBackground), isOn: $blurBackground)
                                    .toggleStyle(SwitchToggleStyle(tint: .orange))
                            }
                        }

                        section(title: localization.text(.appearanceResetSection)) {
                            Button(localization.text(.appearanceResetButton)) {}
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
            }

            if let role = activeColorRole {
                colorPickerOverlay(for: role)
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

    private func modeToggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .orange))
        }
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
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "system"
    case dark = "dark"
    case light = "light"

    var id: String { rawValue }
}

enum ColorAccent: String, CaseIterable, Identifiable {
    case system = "system"
    case custom = "custom"
    case orange = "orange"
    case purple = "purple"

    var id: String { rawValue }
}

enum BackgroundStyle: String, CaseIterable, Identifiable {
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

enum ImageSource: String, CaseIterable, Identifiable {
    case photos = "photos"
    case files = "files"
    case widgets = "widgets"

    var id: String { rawValue }
}

private extension ThemeOption {
    var localizationKey: LocalizationKey {
        switch self {
        case .system: return .appearanceThemeSystem
        case .dark: return .appearanceThemeDark
        case .light: return .appearanceThemeLight
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

private extension ImageSource {
    var localizationKey: LocalizationKey {
        switch self {
        case .photos: return .appearanceImageSourcePhotos
        case .files: return .appearanceImageSourceFiles
        case .widgets: return .appearanceImageSourceWidgets
        }
    }
}
