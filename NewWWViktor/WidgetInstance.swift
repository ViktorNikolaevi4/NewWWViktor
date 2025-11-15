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
    }
}
