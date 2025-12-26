import Foundation

struct WidgetLocation: Codable, Equatable {
    enum Mode: String, Codable {
        case current
        case custom
    }

    private enum Constants {
        static let currentLocationTitle = "Current location"
        static let selectedCityTitle = "Selected city"
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

    // MARK: - Display
    var displayName: String {
        switch mode {
        case .current:
            return Constants.currentLocationTitle
        case .custom:
            return city ?? Constants.selectedCityTitle
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

    // MARK: - System
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
