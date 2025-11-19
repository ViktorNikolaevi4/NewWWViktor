import Foundation
import Combine

enum LocalizationKey: String {
    case placeholderComingSoon

    case categoryGeneral
    case categoryAppearance
    case categoryPlan
    case categoryBackups
    case categoryScreens
    case categorySupport
    case categoryAbout

    case generalSubtitle
    case launchAtLogin
    case appIconSectionTitle
    case appIconMenuOnly
    case appIconDockOnly
    case appIconBoth
    case languageSectionTitle
    case languageDescription
    case languageEnglishOption
    case mirrorDisplays
    case mirrorSpaces
    case hideWidgets
    case pinWidgets
    case gridSize
    case gridOptionMacOS
    case gridOptionWidgetWall
    case snapToGrid
    case focusOnHover
    case scrollBarsTitle
    case scrollBarsAutomatic
    case scrollBarsAlways
    case notificationsTitle
    case notificationsButton
    case resetTitle
    case resetButton
    case menuLogout
    case panelChooseWidget
    case panelClearWidgets
}

final class LocalizationManager: ObservableObject {
    func text(_ key: LocalizationKey) -> String {
        LocalizationManager.translations[key] ?? key.rawValue
    }
}

extension LocalizationManager {
    private static let translations: [LocalizationKey: String] = [
        .placeholderComingSoon: "Content coming soon",

        .categoryGeneral: "General",
        .categoryAppearance: "Appearance",
        .categoryPlan: "Plan",
        .categoryBackups: "Backups",
        .categoryScreens: "Screens",
        .categorySupport: "Support",
        .categoryAbout: "About",

        .generalSubtitle: "Control how miniWW behaves and tune your workspace.",
        .launchAtLogin: "Launch at login (recommended)",
        .appIconSectionTitle: "App icon",
        .appIconMenuOnly: "Show in menu bar",
        .appIconDockOnly: "Show in Dock",
        .appIconBoth: "Show in menu bar & Dock",
        .languageSectionTitle: "Language",
        .languageDescription: "Switch the interface language.",
        .languageEnglishOption: "English",
        .mirrorDisplays: "Mirror on all displays",
        .mirrorSpaces: "Mirror on all spaces",
        .hideWidgets: "Hide widgets",
        .pinWidgets: "Pin widgets to desktop",
        .gridSize: "Grid size",
        .gridOptionMacOS: "macOS",
        .gridOptionWidgetWall: "WidgetWall",
        .snapToGrid: "Snap to grid",
        .focusOnHover: "Focus on hover",
        .scrollBarsTitle: "Show system scroll bars",
        .scrollBarsAutomatic: "Automatic",
        .scrollBarsAlways: "Always",
        .notificationsTitle: "Notifications",
        .notificationsButton: "Manage notifications",
        .resetTitle: "Reset",
        .resetButton: "Reset all settings",
        .panelChooseWidget: "Choose a widget to add",
        .panelClearWidgets: "Clear all widgets",
        .menuLogout: "Log out"
    ]
}
