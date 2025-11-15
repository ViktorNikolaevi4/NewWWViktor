import Foundation
import CoreLocation
import Combine

final class LocationProvider: NSObject, ObservableObject {
    @Published private(set) var cityName: String?

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastRequestDate: Date?

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
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            if error != nil {
                DispatchQueue.main.async {
                    self.cityName = "Location unavailable"
                }
                return
            }

            let bestMatch = placemarks?.first
            let city = bestMatch?.locality ??
                bestMatch?.subAdministrativeArea ??
                bestMatch?.administrativeArea

            DispatchQueue.main.async {
                self.cityName = city ?? "Current location"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.cityName = "Location unavailable"
        }
    }
}
