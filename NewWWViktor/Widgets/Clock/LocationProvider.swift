import Foundation
import CoreLocation
import Combine

final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var cityName: String?
    @Published private(set) var regionName: String?
    @Published private(set) var currentTimeZone: TimeZone?
    @Published private(set) var currentCoordinate: CLLocationCoordinate2D?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastRequestDate: Date?
    private var preferredLocale: Locale = .current
    private var lastKnownLocation: CLLocation?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

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

    private func requestLocation(forced: Bool) {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            if forced || shouldRequestLocation {
                manager.requestLocation()
                lastRequestDate = Date()
            }
        case .restricted, .denied:
            DispatchQueue.main.async {
                self.cityName = "Location disabled"
                self.regionName = nil
                self.currentTimeZone = .current
            }
        @unknown default:
            break
        }
    }

    private var shouldRequestLocation: Bool {
        guard let last = lastRequestDate else { return true }
        return Date().timeIntervalSince(last) > 180 // refresh every 3 minutes max
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
            self.cityName = "Location unavailable"
            self.regionName = nil
            self.currentTimeZone = .current
        }
    }

    private func geocode(location: CLLocation) {
        geocoder.reverseGeocodeLocation(location, preferredLocale: preferredLocale) { placemarks, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.cityName = "Location unavailable"
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
                self.cityName = city ?? "Current location"
                self.regionName = region
                self.currentTimeZone = bestMatch?.timeZone ?? .current
            }
        }
    }
}
