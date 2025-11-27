import SwiftUI
import AppKit

struct SettingsWindowContent: View {
    @EnvironmentObject var settings: SettingsCoordinator
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.05))
                )
                .padding(12)
                .overlay(
                    content
                        .padding(24)
                )
        }
        .frame(minWidth: 760, minHeight: 540)
    }

    private var content: some View {
        HStack(spacing: 0) {
            sidebar
            Divider()
                .overlay(Color.white.opacity(0.08))
                .padding(.vertical, -24)
                .frame(width: 1)
                .padding(.horizontal, 24)
            detail
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(SettingsCategory.allCases) { category in
                sidebarRow(for: category)
            }

            Spacer()

            HStack(spacing: 8) {
                Image(systemName: "rectangle.grid.2x2")
                    .foregroundColor(.secondary)
                Text("MyWigjets")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Spacer()
                Text(appVersion)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 12)
        }
        .frame(width: 180)
    }

    @ViewBuilder
    private func sidebarRow(for category: SettingsCategory) -> some View {
        let isSelected = settings.selectedCategory == category
        Button {
            settings.selectedCategory = category
        } label: {
            HStack(spacing: 12) {
                Image(systemName: category.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                Text(localization.text(category.titleKey))
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.orange.opacity(0.15) : Color.clear)
            )
            .foregroundColor(isSelected ? Color.orange : Color.primary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var detail: some View {
        switch settings.selectedCategory {
        case .general:
            GeneralSettingsDetailView()
        case .appearance:
            AppearanceSettingsDetailView()
        case .plan:
            PlanSettingsDetailView()
        case .backups:
            BackupsSettingsDetailView()
        case .support:
            SupportSettingsDetailView()
        case .about:
            AboutSettingsDetailView()
        default:
            placeholderDetail(for: settings.selectedCategory)
        }
    }

    private func placeholderDetail(for category: SettingsCategory) -> some View {
        VStack {
            Spacer()
            Text(localization.text(category.titleKey))
                .font(.title3.weight(.semibold))
            Text(localization.text(.placeholderComingSoon))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct GeneralSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var appIconController: AppIconController
    @EnvironmentObject private var manager: WidgetManager
    @StateObject private var launchAtLoginManager = LaunchAtLoginManager()
    @State private var languageSelection: LocalizationManager.Language = .english
    @State private var pinWidgets = true
    @State private var gridSize = 0
    @State private var snapToGrid = true

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 22) {
                    toggleSection(title: localization.text(.launchAtLogin),
                                  isOn: Binding(
                                    get: { launchAtLoginManager.isEnabled },
                                    set: { launchAtLoginManager.setEnabled($0) }
                                  ))

                    section(title: localization.text(.appIconSectionTitle), inline: true) {
                        Picker("",
                               selection: Binding(
                                get: { appIconController.mode },
                                set: { appIconController.updateMode($0) }
                               )) {
                            Text(localization.text(.appIconMenuOnly))
                                .tag(AppIconMode.menuOnly)

                            Text(localization.text(.appIconDockOnly))
                                .tag(AppIconMode.dockOnly)

                            Text(localization.text(.appIconBoth))
                                .tag(AppIconMode.menuAndDock)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 260)
                    }

                    languageSection

                    toggleSection(
                        title: localization.text(.hideWidgets),
                        isOn: Binding(
                            get: { manager.areWidgetsHidden },
                            set: { manager.areWidgetsHidden = $0 }
                        )
                    )

                    toggleSection(title: localization.text(.pinWidgets),
                                  isOn: $pinWidgets)

                    section(title: localization.text(.gridSize), inline: true) {
                        Picker("", selection: Binding(
                            get: { manager.gridMode.rawValue },
                            set: { newValue in
                                gridSize = newValue
                                if let mode = WidgetGridMode(rawValue: newValue) {
                                    manager.gridMode = mode
                                }
                            }
                        )) {
                            Text(localization.text(.gridOptionMacOS)).tag(0)
                            Text(localization.text(.gridOptionWidgetWall)).tag(1)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }

                    toggleSection(title: localization.text(.snapToGrid),
                                  isOn: Binding(
                                    get: { manager.snapToGrid },
                                    set: { manager.snapToGrid = $0 }
                                  ))

                    section(title: localization.text(.notificationsTitle), inline: true) {
                        Button(localization.text(.notificationsButton)) {}
                            .buttonStyle(.borderedProminent)
                            .tint(.orange)
                    }

                    section(title: localization.text(.resetTitle), inline: true) {
                        Button(localization.text(.resetButton)) {}
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
            languageSelection = localization.selectedLanguage
            gridSize = manager.gridMode.rawValue
            snapToGrid = manager.snapToGrid
        }
        .onChange(of: localization.selectedLanguage) { newValue in
            guard languageSelection != newValue else { return }
            languageSelection = newValue
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(localization.text(.categoryGeneral))
                .font(.title3.weight(.semibold))
            Text(localization.text(.generalSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var languageSection: some View {
        section(title: localization.text(.languageSectionTitle), inline: true) {
            Picker(selection: $languageSelection) {
                Text(localization.text(.languageEnglishOption))
                    .tag(LocalizationManager.Language.english)
                Text(localization.text(.languageRussianOption))
                    .tag(LocalizationManager.Language.russian)
            } label: {
                ValuePill(text: selectedLanguageTitle, icon: "globe")
            }
            .pickerStyle(.menu)
            .frame(width: 200, alignment: .leading)
        }
        .onChange(of: languageSelection) { newValue in
            localization.setLanguage(newValue)
        }
    }

    private var selectedLanguageTitle: String {
        switch languageSelection {
        case .english: return localization.text(.languageEnglishOption)
        case .russian: return localization.text(.languageRussianOption)
        }
    }

    private func toggleSection(title: String, isOn: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline.weight(.semibold))
                Spacer()
                Toggle("", isOn: isOn)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
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

    private func section<Content: View>(
        title: String,
        inline: Bool = false,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if inline {
                HStack {
                    Text(title)
                        .font(.headline.weight(.semibold))
                    Spacer()
                    content()
                }
            } else {
                Text(title)
                    .font(.headline.weight(.semibold))
                HStack {
                    content()
                    Spacer()
                }
            }
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

}

struct AboutSettingsDetailView: View {
    @EnvironmentObject private var localization: LocalizationManager
    private let termsURL = URL(string: "https://amicoapps.com/terms")
    private let privacyURL = URL(string: "https://amicoapps.com/privacy")

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            ScrollView {
                VStack(spacing: 18) {
                    infoCard
                    welcomeCard
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
            Text(localization.text(.categoryAbout))
                .font(.title3.weight(.semibold))
            Text(localization.text(.aboutSubtitle))
                .font(.footnote)
                .foregroundColor(.secondary)
        }
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.orange.opacity(0.16))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Image(systemName: "rectangle.grid.2x2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text("MyWigjets")
                        .font(.headline.weight(.semibold))
                    Text(versionText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(copyrightText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            if let termsURL, let privacyURL {
                HStack(spacing: 12) {
                    Link(localization.text(.aboutTermsOfUse), destination: termsURL)
                        .font(.footnote.weight(.semibold))

                    Text("•")
                        .foregroundColor(.secondary)

                    Link(localization.text(.aboutPrivacyPolicy), destination: privacyURL)
                        .font(.footnote.weight(.semibold))
                }
                .foregroundColor(.orange)
            }
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

    private var welcomeCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Circle()
                .fill(Color.orange.opacity(0.16))
                .frame(width: 46, height: 46)
                .overlay(
                    Image(systemName: "sparkles")
                        .foregroundColor(.orange)
                        .font(.system(size: 18, weight: .semibold))
                )

            VStack(alignment: .leading, spacing: 8) {
                Text(localization.text(.aboutWelcomeTitle))
                    .font(.headline.weight(.semibold))
                Text(localization.text(.aboutWelcomeBody))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var versionText: String {
        String(format: localization.text(.aboutVersionFormat), appVersion)
    }

    private var copyrightText: String {
        let year = Calendar.current.component(.year, from: Date())
        return String(format: localization.text(.aboutCopyrightFormat), year)
    }

}

private var appVersion: String {
    Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
}
