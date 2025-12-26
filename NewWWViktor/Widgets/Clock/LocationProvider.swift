import Foundation
import CoreLocation
import Combine

final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var cityName: String?
    @Published private(set) var regionName: String?
    @Published private(set) var currentTimeZone: TimeZone?
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?

    private enum Constants {
        static let refreshInterval: TimeInterval = 180
        static let locationDisabledMessage = "Location disabled"
        static let locationUnavailableMessage = "Location unavailable"
        static let currentLocationMessage = "Current location"
    }

    private let locationManager: LocationManaging
    private let geocoder: ReverseGeocoding
    private var lastRequestDate: Date?
    private var preferredLocale: Locale = .current
    private var lastKnownLocation: CLLocation?

    override init() {
        self.locationManager = CLLocationManager()
        self.geocoder = CLGeocoder()
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    init(locationManager: LocationManaging, geocoder: ReverseGeocoding) {
        self.locationManager = locationManager
        self.geocoder = geocoder
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    // MARK: - Public
    func requestLocationIfNeeded() {
        requestLocation(forced: false)
    }

    func refresh() {
        requestLocation(forced: true)
    }

    func updatePreferredLocale(_ locale: Locale) {
        guard preferredLocale.identifier != locale.identifier else { return }
        preferredLocale = locale
        if let lastKnownLocation {
            geocode(location: lastKnownLocation)
        }
    }

    // MARK: - Private
    private func requestLocation(forced: Bool) {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if forced || shouldRequestLocation {
                locationManager.requestLocation()
                lastRequestDate = Date()
            }
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.cityName = Constants.locationDisabledMessage
                self.regionName = nil
                self.currentTimeZone = .current
            }
        @unknown default:
            break
        }
    }

    private var shouldRequestLocation: Bool {
        guard let last = lastRequestDate else { return true }
        return Date().timeIntervalSince(last) > Constants.refreshInterval // refresh every 3 minutes max
    }
}

extension LocationProvider: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        requestLocation(forced: true)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentCoordinate = location.coordinate
        lastKnownLocation = location
        geocode(location: location)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.cityName = Constants.locationUnavailableMessage
            self.regionName = nil
            self.currentTimeZone = .current
        }
    }

    private func geocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location, preferredLocale: preferredLocale) { placemarks, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.cityName = Constants.locationUnavailableMessage
                    self.currentTimeZone = .current
                }
                return
            }

            let bestMatch = placemarks?.first
            let city = bestMatch?.locality ??
                bestMatch?.subAdministrativeArea ??
                bestMatch?.administrativeArea
            let region = bestMatch?.administrativeArea ?? bestMatch?.subAdministrativeArea

            DispatchQueue.main.async {
                self.cityName = city ?? Constants.currentLocationMessage
                self.regionName = region
                self.currentTimeZone = bestMatch?.timeZone ?? .current
            }
        }
    }
}

extension LocationProvider: ClockLocationProviding {}
