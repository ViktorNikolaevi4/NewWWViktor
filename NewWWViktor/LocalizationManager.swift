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
    case languageRussianOption
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
    case widgetSelectedCityFallback
    case widgetLocalTimeFallback
    case widgetCategoryLabel
    case widgetClockDetailTitle
    case widgetClockDetailDescription
    case appearanceSubtitle
    case appearanceColorThemeSection
    case appearanceThemeSystem
    case appearanceThemeDark
    case appearanceThemeLight
    case appearanceLightModeTitle
    case appearanceLightModeDescription
    case appearanceDarkModeTitle
    case appearanceDarkModeDescription
    case appearanceColorsSection
    case appearancePrimaryColor
    case appearanceSecondaryColor
    case appearanceBackgroundSection
    case appearanceAccentSystem
    case appearanceAccentCustom
    case appearanceAccentOrange
    case appearanceAccentPurple
    case appearanceBackgroundSolid
    case appearanceBackgroundGradient
    case appearanceBackgroundPhoto
    case appearanceImageSourceLabel
    case appearanceImageSourcePhotos
    case appearanceImageSourceFiles
    case appearanceImageSourceWidgets
    case appearancePhotoTitle
    case appearancePhotoSubtitle
    case appearanceBrowseButton
    case appearanceBlurBackground
    case appearanceResetSection
    case appearanceResetButton
    case backupsSubtitle
    case backupsManualTitle
    case backupsCreateTitle
    case backupsCreateDescription
    case backupsSaveNowButton
    case supportSubtitle
    case supportCalloutTitle
    case supportCalloutBody
    case supportRowQuestionTitle
    case supportRowQuestionAction
    case supportRowNeedHelpTitle
    case supportRowNeedHelpAction
    case supportRowTourTitle
    case supportRowTourAction
    case supportRowIdeaTitle
    case supportRowIdeaAction
}

final class LocalizationManager: ObservableObject {
    enum Language: String, CaseIterable, Identifiable {
        case english = "en"
        case russian = "ru"

        var id: String { rawValue }

        var locale: Locale {
            Locale(identifier: localeIdentifier)
        }

        private var localeIdentifier: String {
            switch self {
            case .english: return "en_US"
            case .russian: return "ru_RU"
            }
        }
    }

    @Published var selectedLanguage: Language {
        didSet {
            guard oldValue != selectedLanguage else { return }
            bundle = LocalizationManager.bundle(for: selectedLanguage)
            storage.set(selectedLanguage.rawValue, forKey: Self.storageKey)
        }
    }

    private var bundle: Bundle
    private let storage: UserDefaults
    private static let storageKey = "miniww.localization.language"

    init(storage: UserDefaults = .standard) {
        self.storage = storage
        let initialLanguage = LocalizationManager.loadInitialLanguage(from: storage)
        self.selectedLanguage = initialLanguage
        self.bundle = LocalizationManager.bundle(for: initialLanguage)
    }

    func text(_ key: LocalizationKey) -> String {
        bundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
    }

    func setLanguage(_ language: Language) {
        guard language != selectedLanguage else { return }
        selectedLanguage = language
    }

    private static func loadInitialLanguage(from storage: UserDefaults) -> Language {
        if let stored = storage.string(forKey: storageKey),
           let language = Language(rawValue: stored) {
            return language
        }

        if let preferred = Bundle.main.preferredLocalizations.first,
           let language = Language(rawValue: preferred) {
            return language
        }

        return .english
    }

    private static func bundle(for language: Language) -> Bundle {
        guard let path = Bundle.main.path(forResource: language.rawValue, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }
}
