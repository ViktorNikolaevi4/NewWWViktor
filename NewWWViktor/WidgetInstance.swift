import Foundation

struct WidgetInstance: Identifiable, Codable, Equatable {
    let id: UUID
    var type: WidgetType
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat
    var isPinned: Bool
    var showsDate: Bool
    var showsLocation: Bool
    var prefersTwelveHour: Bool
    var location: WidgetLocation
    var mainColorName: String?
    var mainColorIntensity: Double
    var secondaryColorName: String?
    var secondaryColorIntensity: Double
    var sizeOption: WidgetSizeOption

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
        self.showsDate = true
        self.showsLocation = true
        self.location = .current
        self.prefersTwelveHour = true
        self.mainColorName = nil
        self.mainColorIntensity = 1.0
        self.secondaryColorName = nil
        self.secondaryColorIntensity = 1.0
        self.sizeOption = .medium
        applySizeOption(.medium)
    }

    private enum CodingKeys: String, CodingKey {
        case id, type, x, y, width, height, isPinned, showsDate, showsLocation, prefersTwelveHour, location, mainColorName, mainColorIntensity, secondaryColorName, secondaryColorIntensity, sizeOption
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
        showsDate = try container.decodeIfPresent(Bool.self, forKey: .showsDate) ?? true
        showsLocation = try container.decodeIfPresent(Bool.self, forKey: .showsLocation) ?? true
        prefersTwelveHour = try container.decodeIfPresent(Bool.self, forKey: .prefersTwelveHour) ?? true
        location = try container.decodeIfPresent(WidgetLocation.self, forKey: .location) ?? .current
        mainColorName = try container.decodeIfPresent(String.self, forKey: .mainColorName)
        mainColorIntensity = try container.decodeIfPresent(Double.self, forKey: .mainColorIntensity) ?? 1.0
        secondaryColorName = try container.decodeIfPresent(String.self, forKey: .secondaryColorName)
        secondaryColorIntensity = try container.decodeIfPresent(Double.self, forKey: .secondaryColorIntensity) ?? 1.0
        sizeOption = try container.decodeIfPresent(WidgetSizeOption.self, forKey: .sizeOption) ?? .medium
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
        try container.encode(showsDate, forKey: .showsDate)
        try container.encode(showsLocation, forKey: .showsLocation)
        try container.encode(prefersTwelveHour, forKey: .prefersTwelveHour)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(mainColorName, forKey: .mainColorName)
        try container.encode(mainColorIntensity, forKey: .mainColorIntensity)
        try container.encodeIfPresent(secondaryColorName, forKey: .secondaryColorName)
        try container.encode(secondaryColorIntensity, forKey: .secondaryColorIntensity)
        try container.encode(sizeOption, forKey: .sizeOption)
    }

    mutating func applySizeOption(_ option: WidgetSizeOption) {
        sizeOption = option
        let size = option.dimensions
        width = size.width
        height = size.height
    }
}
