import Foundation
import Combine

enum AppLanguage: String, CaseIterable, Identifiable {
    case english = "en"
    case russian = "ru"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .english: return "English"
        case .russian: return "Русский"
        }
    }
}

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
    case languageRestartTitle
    case languageRestartMessage
    case languageRestartLater
    case languageRestartNow
}

final class LocalizationManager: ObservableObject {
    @Published private(set) var language: AppLanguage
    @Published var pendingLanguage: AppLanguage
    @Published var showingRestartPrompt = false

    private static let languageStorageKey = "miniww.language"

    init() {
        let resolvedLanguage: AppLanguage
        if let stored = UserDefaults.standard.string(forKey: Self.languageStorageKey),
           let savedLanguage = AppLanguage(rawValue: stored) {
            resolvedLanguage = savedLanguage
        } else {
            resolvedLanguage = .english
        }
        self.language = resolvedLanguage
        self.pendingLanguage = resolvedLanguage
    }

    func text(_ key: LocalizationKey) -> String {
        let table = LocalizationManager.translations[language] ?? [:]
        if let value = table[key] {
            return value
        }
        let fallback = LocalizationManager.translations[.english] ?? [:]
        return fallback[key] ?? key.rawValue
    }

    func requestLanguageChange(to newLanguage: AppLanguage) {
        guard newLanguage != language else { return }
        DispatchQueue.main.async {
            self.pendingLanguage = newLanguage
            self.showingRestartPrompt = true
        }
    }

    func confirmLanguageChange() {
        DispatchQueue.main.async {
            self.language = self.pendingLanguage
            self.persistLanguage()
        }
    }

    private func persistLanguage() {
        UserDefaults.standard.set(language.rawValue, forKey: Self.languageStorageKey)
    }
}

extension LocalizationManager {
    private static let translations: [AppLanguage: [LocalizationKey: String]] = [
        .english: [
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
            .menuLogout: "Log out",
            .languageRestartTitle: "Language change",
            .languageRestartMessage: "Restart miniWW to apply the new language?",
            .languageRestartLater: "Not now",
            .languageRestartNow: "Restart"
        ],
        .russian: [
            .placeholderComingSoon: "Контент появится позже",

            .categoryGeneral: "Основные",
            .categoryAppearance: "Оформление",
            .categoryPlan: "План",
            .categoryBackups: "Резервные копии",
            .categoryScreens: "Экраны",
            .categorySupport: "Поддержка",
            .categoryAbout: "О нас",

            .generalSubtitle: "Управляйте поведением miniWW и настройте рабочее пространство.",
            .launchAtLogin: "Открывать при входе в систему (рекомендуется)",
            .appIconSectionTitle: "Иконка приложения",
            .appIconMenuOnly: "Показывать в строке меню",
            .appIconDockOnly: "Показывать в Dock",
            .appIconBoth: "Показывать в строке и в Dock",
            .languageSectionTitle: "Язык",
            .languageDescription: "Выберите язык интерфейса.",
            .mirrorDisplays: "Дублировать на всех мониторах",
            .mirrorSpaces: "Дублировать на всех пространствах",
            .hideWidgets: "Скрыть виджеты",
            .pinWidgets: "Закрепить виджеты на рабочем столе",
            .gridSize: "Размер сетки",
            .gridOptionMacOS: "macOS",
            .gridOptionWidgetWall: "WidgetWall",
            .snapToGrid: "Привязать к сетке",
            .focusOnHover: "Фокус при наведении",
            .scrollBarsTitle: "Показать системные полосы прокрутки",
            .scrollBarsAutomatic: "Автоматический",
            .scrollBarsAlways: "Всегда",
            .notificationsTitle: "Уведомления",
            .notificationsButton: "Управление уведомлениями",
            .resetTitle: "Сброс",
            .resetButton: "Сбросить все настройки",
            .panelChooseWidget: "Выберите виджет для добавления",
            .panelClearWidgets: "Удалить все виджеты",
            .menuLogout: "Выйти",
            .languageRestartTitle: "Изменение языка",
            .languageRestartMessage: "Перезапустить miniWW, чтобы применить новый язык?",
            .languageRestartLater: "Не сейчас",
            .languageRestartNow: "Перезапустить"
        ]
    ]
}
