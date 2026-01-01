import Foundation

struct WidgetInstance: Identifiable, Codable, Equatable {
    let id: UUID
    var type: WidgetType
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isPinned: Bool
    var isPositionLocked: Bool
    var showsDate: Bool
    var showsLocation: Bool
    var prefersTwelveHour: Bool
    var prefersCelsius: Bool
    var location: WidgetLocation
    var mainColorName: String?
    var mainColorIntensity: Double
    var secondaryColorName: String?
    var secondaryColorIntensity: Double
    var backgroundStyle: BackgroundStyle?
    var backgroundColorName: String?
    var backgroundIntensity: Double
    var backgroundImagePath: String?
    var gradientColor1Name: String?
    var gradientColor2Name: String?
    var gradientColor1Opacity: Double
    var gradientColor2Opacity: Double
    var gradientColor1Position: Double
    var gradientColor2Position: Double
    var gradientType: BackgroundGradientType?
    var gradientAngle: Double?
    var isBackgroundHidden: Bool
    var sizeOption: WidgetSizeOption
    var pomodoroPhase: PomodoroPhase
    var pomodoroRound: Int
    var pomodoroIsRunning: Bool
    var pomodoroEndDate: Date?
    var pomodoroRemaining: TimeInterval?
    var pomodoroFocusMinutes: Int
    var pomodoroShortBreakMinutes: Int
    var pomodoroLongBreakMinutes: Int
    var pomodoroTotalRounds: Int
    var pomodoroAutoStart: Bool
    var pomodoroSoundName: String
    var pomodoroNotificationsEnabled: Bool

    init(type: WidgetType,
         origin: CGPoint = CGPoint(x: 100, y: 100)) {
        self.id = UUID()
        self.type = type
        self.x = origin.x
        self.y = origin.y
        let size = type.defaultSize
        self.width = size.width
        self.height = size.height
        self.isPinned = false
        self.isPositionLocked = false
        self.showsDate = true
        self.showsLocation = true
        self.location = .current
        self.prefersTwelveHour = true
        self.prefersCelsius = true
        self.mainColorName = nil
        self.mainColorIntensity = 1.0
        self.secondaryColorName = nil
        self.secondaryColorIntensity = 1.0
        self.backgroundStyle = nil
        self.backgroundColorName = nil
        self.backgroundIntensity = 1.0
        self.backgroundImagePath = nil
        self.gradientColor1Name = nil
        self.gradientColor2Name = nil
        self.gradientColor1Opacity = 1.0
        self.gradientColor2Opacity = 1.0
        self.gradientColor1Position = 0.0
        self.gradientColor2Position = 1.0
        self.gradientType = nil
        self.gradientAngle = nil
        self.isBackgroundHidden = false
        self.sizeOption = .medium
        self.pomodoroPhase = .focus
        self.pomodoroRound = 1
        self.pomodoroIsRunning = false
        self.pomodoroEndDate = nil
        self.pomodoroRemaining = nil
        self.pomodoroFocusMinutes = 25
        self.pomodoroShortBreakMinutes = 1
        self.pomodoroLongBreakMinutes = 20
        self.pomodoroTotalRounds = 4
        self.pomodoroAutoStart = true
        self.pomodoroSoundName = "Glass"
        self.pomodoroNotificationsEnabled = true
        applySizeOption(.medium)
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, x, y, width, height, isPinned, isPositionLocked, showsDate, showsLocation, prefersTwelveHour, prefersCelsius, location, mainColorName, mainColorIntensity, secondaryColorName, secondaryColorIntensity, backgroundStyle, backgroundColorName, backgroundIntensity, backgroundImagePath, gradientColor1Name, gradientColor2Name, gradientColor1Opacity, gradientColor2Opacity, gradientColor1Position, gradientColor2Position, gradientType, gradientAngle, isBackgroundHidden, sizeOption, pomodoroPhase, pomodoroRound, pomodoroIsRunning, pomodoroEndDate, pomodoroRemaining, pomodoroFocusMinutes, pomodoroShortBreakMinutes, pomodoroLongBreakMinutes, pomodoroTotalRounds, pomodoroAutoStart, pomodoroSoundName, pomodoroNotificationsEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        type = try container.decode(WidgetType.self, forKey: .type)
        x = try container.decode(CGFloat.self, forKey: .x)
        y = try container.decode(CGFloat.self, forKey: .y)
        width = try container.decode(CGFloat.self, forKey: .width)
        height = try container.decode(CGFloat.self, forKey: .height)
        isPinned = try container.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isPositionLocked = try container.decodeIfPresent(Bool.self, forKey: .isPositionLocked) ?? false
        showsDate = try container.decodeIfPresent(Bool.self, forKey: .showsDate) ?? true
        showsLocation = try container.decodeIfPresent(Bool.self, forKey: .showsLocation) ?? true
        prefersTwelveHour = try container.decodeIfPresent(Bool.self, forKey: .prefersTwelveHour) ?? true
        prefersCelsius = try container.decodeIfPresent(Bool.self, forKey: .prefersCelsius) ?? true
        location = try container.decodeIfPresent(WidgetLocation.self, forKey: .location) ?? .current
        mainColorName = try container.decodeIfPresent(String.self, forKey: .mainColorName)
        mainColorIntensity = try container.decodeIfPresent(Double.self, forKey: .mainColorIntensity) ?? 1.0
        secondaryColorName = try container.decodeIfPresent(String.self, forKey: .secondaryColorName)
        secondaryColorIntensity = try container.decodeIfPresent(Double.self, forKey: .secondaryColorIntensity) ?? 1.0
        backgroundStyle = try container.decodeIfPresent(BackgroundStyle.self, forKey: .backgroundStyle)
        backgroundColorName = try container.decodeIfPresent(String.self, forKey: .backgroundColorName)
        backgroundIntensity = try container.decodeIfPresent(Double.self, forKey: .backgroundIntensity) ?? 1.0
        backgroundImagePath = try container.decodeIfPresent(String.self, forKey: .backgroundImagePath)
        gradientColor1Name = try container.decodeIfPresent(String.self, forKey: .gradientColor1Name)
        gradientColor2Name = try container.decodeIfPresent(String.self, forKey: .gradientColor2Name)
        gradientColor1Opacity = try container.decodeIfPresent(Double.self, forKey: .gradientColor1Opacity) ?? 1.0
        gradientColor2Opacity = try container.decodeIfPresent(Double.self, forKey: .gradientColor2Opacity) ?? 1.0
        gradientColor1Position = try container.decodeIfPresent(Double.self, forKey: .gradientColor1Position) ?? 0.0
        gradientColor2Position = try container.decodeIfPresent(Double.self, forKey: .gradientColor2Position) ?? 1.0
        gradientType = try container.decodeIfPresent(BackgroundGradientType.self, forKey: .gradientType)
        gradientAngle = try container.decodeIfPresent(Double.self, forKey: .gradientAngle)
        isBackgroundHidden = try container.decodeIfPresent(Bool.self, forKey: .isBackgroundHidden) ?? false
        sizeOption = try container.decodeIfPresent(WidgetSizeOption.self, forKey: .sizeOption) ?? .medium
        pomodoroPhase = try container.decodeIfPresent(PomodoroPhase.self, forKey: .pomodoroPhase) ?? .focus
        pomodoroRound = try container.decodeIfPresent(Int.self, forKey: .pomodoroRound) ?? 1
        pomodoroIsRunning = try container.decodeIfPresent(Bool.self, forKey: .pomodoroIsRunning) ?? false
        pomodoroEndDate = try container.decodeIfPresent(Date.self, forKey: .pomodoroEndDate)
        pomodoroRemaining = try container.decodeIfPresent(TimeInterval.self, forKey: .pomodoroRemaining)
        pomodoroFocusMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroFocusMinutes) ?? 25
        pomodoroShortBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroShortBreakMinutes) ?? 1
        pomodoroLongBreakMinutes = try container.decodeIfPresent(Int.self, forKey: .pomodoroLongBreakMinutes) ?? 20
        pomodoroTotalRounds = try container.decodeIfPresent(Int.self, forKey: .pomodoroTotalRounds) ?? 4
        pomodoroAutoStart = try container.decodeIfPresent(Bool.self, forKey: .pomodoroAutoStart) ?? true
        pomodoroSoundName = try container.decodeIfPresent(String.self, forKey: .pomodoroSoundName) ?? "Glass"
        pomodoroNotificationsEnabled = try container.decodeIfPresent(Bool.self, forKey: .pomodoroNotificationsEnabled) ?? true
        applySizeOption(sizeOption)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(type, forKey: .type)
        try container.encode(x, forKey: .x)
        try container.encode(y, forKey: .y)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(isPinned, forKey: .isPinned)
        try container.encode(isPositionLocked, forKey: .isPositionLocked)
        try container.encode(showsDate, forKey: .showsDate)
        try container.encode(showsLocation, forKey: .showsLocation)
        try container.encode(prefersTwelveHour, forKey: .prefersTwelveHour)
        try container.encode(prefersCelsius, forKey: .prefersCelsius)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(mainColorName, forKey: .mainColorName)
        try container.encode(mainColorIntensity, forKey: .mainColorIntensity)
        try container.encodeIfPresent(secondaryColorName, forKey: .secondaryColorName)
        try container.encode(secondaryColorIntensity, forKey: .secondaryColorIntensity)
        try container.encodeIfPresent(backgroundStyle, forKey: .backgroundStyle)
        try container.encodeIfPresent(backgroundColorName, forKey: .backgroundColorName)
        try container.encode(backgroundIntensity, forKey: .backgroundIntensity)
        try container.encodeIfPresent(backgroundImagePath, forKey: .backgroundImagePath)
        try container.encodeIfPresent(gradientColor1Name, forKey: .gradientColor1Name)
        try container.encodeIfPresent(gradientColor2Name, forKey: .gradientColor2Name)
        try container.encode(gradientColor1Opacity, forKey: .gradientColor1Opacity)
        try container.encode(gradientColor2Opacity, forKey: .gradientColor2Opacity)
        try container.encode(gradientColor1Position, forKey: .gradientColor1Position)
        try container.encode(gradientColor2Position, forKey: .gradientColor2Position)
        try container.encodeIfPresent(gradientType, forKey: .gradientType)
        try container.encodeIfPresent(gradientAngle, forKey: .gradientAngle)
        try container.encode(isBackgroundHidden, forKey: .isBackgroundHidden)
        try container.encode(sizeOption, forKey: .sizeOption)
        try container.encode(pomodoroPhase, forKey: .pomodoroPhase)
        try container.encode(pomodoroRound, forKey: .pomodoroRound)
        try container.encode(pomodoroIsRunning, forKey: .pomodoroIsRunning)
        try container.encodeIfPresent(pomodoroEndDate, forKey: .pomodoroEndDate)
        try container.encodeIfPresent(pomodoroRemaining, forKey: .pomodoroRemaining)
        try container.encode(pomodoroFocusMinutes, forKey: .pomodoroFocusMinutes)
        try container.encode(pomodoroShortBreakMinutes, forKey: .pomodoroShortBreakMinutes)
        try container.encode(pomodoroLongBreakMinutes, forKey: .pomodoroLongBreakMinutes)
        try container.encode(pomodoroTotalRounds, forKey: .pomodoroTotalRounds)
        try container.encode(pomodoroAutoStart, forKey: .pomodoroAutoStart)
        try container.encode(pomodoroSoundName, forKey: .pomodoroSoundName)
        try container.encode(pomodoroNotificationsEnabled, forKey: .pomodoroNotificationsEnabled)
    }

    mutating func applySizeOption(_ option: WidgetSizeOption) {
        sizeOption = option
        let size = option.dimensions
        width = size.width
        height = size.height
    }
}
