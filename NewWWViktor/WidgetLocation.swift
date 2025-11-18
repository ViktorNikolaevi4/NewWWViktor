import Foundation

struct WidgetLocation: Codable, Equatable {
    enum Mode: String, Codable {
        case current
        case custom
    }

    var mode: Mode
    var city: String?
    var region: String?
    var timeZoneIdentifier: String?
    var latitude: Double?
    var longitude: Double?

    init(mode: Mode,
         city: String? = nil,
         region: String? = nil,
         timeZoneIdentifier: String? = nil,
         latitude: Double? = nil,
         longitude: Double? = nil) {
        self.mode = mode
        self.city = city
        self.region = region
        self.timeZoneIdentifier = timeZoneIdentifier
        self.latitude = latitude
        self.longitude = longitude
    }

    static var current: WidgetLocation {
        WidgetLocation(mode: .current)
    }

    var displayName: String {
        switch mode {
        case .current:
            return "Current location"
        case .custom:
            return city ?? "Selected city"
        }
    }

    var subtitle: String? {
        switch mode {
        case .current:
            return nil
        case .custom:
            return region
        }
    }

    var iconName: String {
        switch mode {
        case .current:
            return "location.fill"
        case .custom:
            return "mappin.and.ellipse"
        }
    }

    var timeZone: TimeZone {
        if mode == .custom,
           let identifier = timeZoneIdentifier,
           let tz = TimeZone(identifier: identifier) {
            return tz
        }
        return TimeZone.current
    }
}
