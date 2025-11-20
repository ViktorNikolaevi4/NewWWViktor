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

    var body: some View {
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
                            colorPickerRow(title: localization.text(.appearancePrimaryColor),
                                           selection: $primaryColor)
                            colorPickerRow(title: localization.text(.appearanceSecondaryColor),
                                           selection: $secondaryColor)
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

    private func colorPickerRow(title: String, selection: Binding<ColorAccent>) -> some View {
        HStack(spacing: 12) {
            Text(title)
                .font(.headline.weight(.semibold))
            Spacer()
            Picker("", selection: selection) {
                ForEach(ColorAccent.allCases) { accent in
                    Text(localization.text(accent.localizationKey)).tag(accent)
                }
            }
            .frame(width: 180)
        }
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
    case gradient
    case photo

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .solid: return "square.fill"
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
