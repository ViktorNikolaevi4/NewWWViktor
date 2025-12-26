import Foundation
import CoreLocation
import MapKit

protocol ClockLocationProviding: AnyObject {
    var cityName: String? { get }
    var regionName: String? { get }
    var currentTimeZone: TimeZone? { get }
    var currentCoordinate: CLLocationCoordinate2D? { get }
    func requestLocationIfNeeded()
    func refresh()
    func updatePreferredLocale(_ locale: Locale)
}

protocol LocationManaging: AnyObject {
    var authorizationStatus: CLAuthorizationStatus { get }
    var desiredAccuracy: CLLocationAccuracy { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    func requestWhenInUseAuthorization()
    func requestLocation()
}

extension CLLocationManager: LocationManaging {}

protocol ReverseGeocoding: AnyObject {
    func reverseGeocodeLocation(
        _ location: CLLocation,
        preferredLocale: Locale?,
        completionHandler: @escaping ([CLPlacemark]?, Error?) -> Void
    )
}

extension CLGeocoder: ReverseGeocoding {}

protocol ReverseGeocodingFactory {
    func makeGeocoder() -> ReverseGeocoding
}

struct SystemGeocodingFactory: ReverseGeocodingFactory {
    func makeGeocoder() -> ReverseGeocoding {
        CLGeocoder()
    }
}

protocol LocalSearchCompleting: AnyObject {
    var delegate: MKLocalSearchCompleterDelegate? { get set }
    var resultTypes: MKLocalSearchCompleter.ResultType { get set }
    var results: [MKLocalSearchCompletion] { get }
    func cancel()
}

extension MKLocalSearchCompleter: LocalSearchCompleting {}

protocol LocalSearching {
    func start(completionHandler: @escaping (MKLocalSearch.Response?, Error?) -> Void)
}

extension MKLocalSearch: LocalSearching {}

protocol LocalSearchCreating {
    func makeSearch(request: MKLocalSearch.Request) -> LocalSearching
}

struct SystemLocalSearchFactory: LocalSearchCreating {
    func makeSearch(request: MKLocalSearch.Request) -> LocalSearching {
        MKLocalSearch(request: request)
    }
}
