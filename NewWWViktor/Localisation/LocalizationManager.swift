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
    case planSubtitle
    case planPremiumTitle
    case planPremiumBody
    case planPremiumTag
    case planUpgradeButton
    case planRestorePrompt
    case planRestoreButton
    case planBundleTitle
    case planBundleBody
    case planBundleButton
    case aboutSubtitle
    case aboutVersionFormat
    case aboutTermsOfUse
    case aboutPrivacyPolicy
    case aboutWelcomeTitle
    case aboutWelcomeBody
    case aboutCopyrightFormat

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
    case widgetWeatherDetailTitle
    case widgetWeatherDetailDescription
    case widgetPomodoroDetailTitle
    case widgetPomodoroDetailDescription
    case widgetBatteryDetailTitle
    case widgetBatteryDetailDescription
    case widgetSystemDetailTitle
    case widgetSystemDetailDescription
    case widgetEisenhowerDetailTitle
    case widgetEisenhowerDetailDescription
    case widgetBatteryLabel
    case widgetBatteryRemainingLabel
    case widgetBatteryTimeToFull
    case widgetBatteryMaximumCapacity
    case widgetBatteryDesignCapacity
    case widgetBatteryOptimization
    case widgetBatteryCurrentCapacity
    case widgetBatteryHealth
    case widgetBatteryHealthGood
    case widgetBatteryHealthFair
    case widgetBatteryHealthPoor
    case widgetBatteryHealthUnknown
    case widgetBatteryStatusOn
    case widgetBatteryStatusOff
    case widgetBatteryEstimateUnavailable
    case widgetSystemCPU
    case widgetSystemRAM
    case widgetSystemDisk
    case widgetEisenhowerImportantUrgent
    case widgetEisenhowerImportantNotUrgent
    case widgetEisenhowerNotImportantUrgent
    case widgetEisenhowerNotImportantNotUrgent
    case widgetEisenhowerTasksTitle
    case widgetEisenhowerEmpty
    case widgetEisenhowerManageTasks
    case widgetEisenhowerShowCompleted
    case widgetEisenhowerAddTask
    case widgetEisenhowerEditTask
    case widgetEisenhowerDeleteTask
    case widgetEisenhowerTaskTitlePlaceholder
    case widgetEisenhowerQuadrantLabel
    case widgetEisenhowerDone
    case widgetEisenhowerSave
    case widgetEisenhowerCancel
    case widgetHabitsDetailTitle
    case widgetHabitsDetailDescription
    case widgetHabitsTitle
    case widgetHabitsDaysLabel
    case widgetHabitsDoneLabel
    case widgetHabitsStreakLabel
    case widgetHabitsSectionTitle
    case widgetHabitsHabitLabel
    case widgetHabitsNewHabitLabel
    case widgetHabitsNewHabitPlaceholder
    case widgetHabitsAddCustom
    case widgetHabitsDefaultSection
    case widgetHabitsCustomSection
    case widgetHabitsDeleteCustom
    case widgetHabitsManageTitle
    case widgetHabitsManageAction
    case widgetHabitsManageSearch
    case widgetHabitsManageEmpty
    case widgetHabitsStreakDaysLabel
    case widgetHabitsResetProgress
    case widgetHabitsLoading
    case widgetHabitsWater
    case widgetHabitsWorkout
    case widgetHabitsReading
    case widgetHabitsMeditation
    case widgetHabitsSleep
    case widgetHabitsWalk
    case widgetHabitsJournal
    case widgetHabitsVitamins
    case widgetHabitsStretch
    case widgetHabitsLanguage
    case widgetCryptoDetailTitle
    case widgetCryptoDetailDescription
    case widgetCryptoTitle
    case widgetCryptoSectionTitle
    case widgetCryptoSymbolLabel
    case widgetCryptoSearchLabel
    case widgetCryptoSearchPlaceholder
    case widgetCryptoResultsLabel
    case widgetCryptoNoResults
    case widgetCryptoSearchAction
    case widgetCryptoSearchTitle
    case widgetCryptoSearchHint
    case widgetCryptoSuggestionsTitle
    case widgetCryptoLoadingSymbols
    case widgetCryptoTickersTitle
    case widgetCryptoAddTicker
    case widgetCryptoNoTickers
    case widgetInvestmentDetailTitle
    case widgetInvestmentDetailDescription
    case widgetInvestmentTitle
    case widgetInvestmentComputeLabel
    case widgetInvestmentComputeIncome
    case widgetInvestmentComputeRate
    case widgetInvestmentComputeStartCapital
    case widgetInvestmentComputeTime
    case widgetInvestmentComputeContribution
    case widgetInvestmentTargetLabel
    case widgetInvestmentStartCapitalLabel
    case widgetInvestmentRateLabel
    case widgetInvestmentTimeLabel
    case widgetInvestmentContributionLabel
    case widgetInvestmentContributionFrequencyLabel
    case widgetInvestmentCompoundingFrequencyLabel
    case widgetInvestmentIncomeLabel
    case widgetInvestmentFinalAmountLabel
    case widgetInvestmentTaxLabel
    case widgetInvestmentTaxRateLabel
    case widgetInvestmentInflationLabel
    case widgetInvestmentInflationRateLabel
    case widgetInvestmentFrequencyMonthly
    case widgetInvestmentFrequencyQuarterly
    case widgetInvestmentFrequencyYearly
    case widgetInvestmentResultTitle
    case widgetInvestmentYearsUnit
    case widgetInvestmentMonthsUnit
    case widgetInvestmentManageAction
    case widgetInvestmentManageTitle
    case widgetInvestmentCalculateAction
    case widgetInvestmentHideBreakdownAction
    case widgetInvestmentBreakdownYear
    case widgetInvestmentBreakdownMonth
    case widgetInvestmentBreakdownStart
    case widgetInvestmentBreakdownIncome
    case widgetInvestmentBreakdownContributions
    case widgetInvestmentBreakdownFinal
    case widgetInvestmentMonthlyTitle
    case widgetLinksDetailTitle
    case widgetLinksDetailDescription
    case widgetLinksTitle
    case widgetLinksSectionTitle
    case widgetTopMissionDetailTitle
    case widgetTopMissionDetailDescription
    case widgetTopMissionTitle
    case widgetTopMissionSubtitle
    case widgetTopMissionTaskPlaceholder
    case widgetTopMissionManageAction
    case widgetTopMissionCTA
    case widgetTopMissionSubtasksTitle
    case widgetTopMissionSubtaskPlaceholder
    case widgetTopMissionAddSubtask
    case widgetClientsDetailTitle
    case widgetClientsDetailDescription
    case widgetClientsTitle
    case widgetClientsMonthLabel
    case widgetClientsPayByLabel
    case widgetClientsTotalLabel
    case widgetClientsOverdueFormat
    case widgetClientsTodayFormat
    case widgetClientsUnpaidFormat
    case widgetClientsPaidFormat
    case widgetClientsPaidShortFormat
    case widgetClientsExpectedAmountTitle
    case widgetClientsCollectedAmountTitle
    case widgetClientsNextTitle
    case widgetClientsTodayTitle
    case widgetClientsTomorrowTitle
    case widgetClientsSectionTitle
    case widgetClientsManageAction
    case widgetClientsManageTitle
    case widgetClientsManageSearch
    case widgetClientsManageEmpty
    case widgetClientsNamePlaceholder
    case widgetClientsPayDayPlaceholder
    case widgetClientsVisitsPlaceholder
    case widgetClientsAddAction
    case widgetClientsEditAction
    case widgetClientsPayDayFormat
    case widgetClientsVisitsFormat
    case widgetClientsEmpty
    case widgetClientsPaidToggle
    case widgetClientsAmountPlaceholder
    case widgetClientsAmountFormat
    case widgetLinksTitlePlaceholder
    case widgetLinksURLPlaceholder
    case widgetLinksEmpty
    case widgetLinksManageAction
    case widgetLinksManageTitle
    case widgetLinksManageSearch
    case widgetLinksManageEmpty
    case widgetLinksAddGroup
    case widgetLinksAddLink
    case widgetLinksGroupPlaceholder
    case widgetLinksUngrouped
    case widgetLinksEmptyGroup
    case widgetLinksDeleteGroupTitle
    case widgetLinksDeleteGroupMessage
    case widgetLinksInvalidURL
    case widgetPomodoroFocusLabel
    case widgetPomodoroShortBreakLabel
    case widgetPomodoroLongBreakLabel
    case widgetPomodoroTimeDefault
    case widgetPomodoroStart
    case widgetPomodoroPause
    case widgetPomodoroRestart
    case widgetPomodoroNext
    case widgetPomodoroSettingsTitle
    case widgetPomodoroFocusDuration
    case widgetPomodoroShortBreakDuration
    case widgetPomodoroLongBreakDuration
    case widgetPomodoroRounds
    case widgetPomodoroMinutesUnit
    case widgetPomodoroAutoStart
    case widgetPomodoroSoundLabel
    case widgetPomodoroNotificationsLabel
    case widgetPomodoroNotificationFocusComplete
    case widgetPomodoroNotificationBreakComplete
    case widgetPomodoroNotificationFocusStart
    case widgetPomodoroNotificationBreakStart
    case widgetWeatherPlaceholderCondition
    case widgetWeatherPlaceholderHiLow
    case appearanceSubtitle
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
    case appearanceBackgroundPalette
    case appearanceImageSourceLabel
    case appearanceImageSourcePhotos
    case appearanceImageSourceFiles
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
    case supportEmailSubject
    case supportIdeaEmailSubject
    case backupsRestoreButton
    case widgetLocationSection
    case widgetNameLabel
    case widgetPlaceholderDash
    case widgetShowDate
    case widgetShowLocation
    case widgetShowWeather
    case widgetTemperatureLabel
    case widgetTimeLabel
    case widgetTimeFormat12h
    case widgetTimeFormat24h
    case widgetColorsSection
    case widgetBackgroundGlobal
    case widgetBackgroundCustom
    case widgetBehaviorSection
    case widgetSizeLabel
    case widgetPinToTop
    case widgetLockPosition
    case widgetSnapToGrid
    case widgetActionsSection
    case widgetAddWidgets
    case widgetGeneralSettings
    case widgetDelete
    case paletteTitle
    case paletteSelected
    case noColorSelected
    case opacity
    case back
    case clear
    case global
    case locationTitle
    case locationSearchPlaceholder
    case locationSearchHelp
    case locationCurrentLocation
    case locationNoResults
    case widgetSizeSmall
    case widgetSizeMedium
    case widgetSizeSmallSubtitle
    case widgetSizeMediumSubtitle
    case widgetSizeLarge
    case widgetSizeExtraLarge
    case widgetSizeLargeSubtitle
    case widgetSizeExtraLargeSubtitle
    case widgetWeatherFeelsLike
    case widgetWeatherHumidity
    case widgetWeatherPressure
    case widgetWeatherSunrise
    case widgetWeatherSunset
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
    static let shared = LocalizationManager()

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
