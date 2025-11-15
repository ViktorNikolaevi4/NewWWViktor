import Foundation
import Combine
import CoreLocation

final class LocationSearchService: ObservableObject {
    
    @Published var results: [LocationSearchResult] = []
    @Published var isSearching: Bool = false

    private let geocoder = CLGeocoder()
    private var pendingWorkItem: DispatchWorkItem?

    func update(query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingWorkItem?.cancel()

        guard trimmed.count >= 2 else {
            DispatchQueue.main.async {
                self.results = []
                self.isSearching = false
            }
            geocoder.cancelGeocode()
            return
        }

        isSearching = true
        let workItem = DispatchWorkItem { [weak self] in
            self?.performSearch(for: trimmed)
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: workItem)
    }

    private func performSearch(for query: String) {
        geocoder.cancelGeocode()
        geocoder.geocodeAddressString(query) { [weak self] placemarks, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.isSearching = false
                self.results = placemarks?.compactMap(LocationSearchResult.init) ?? []
            }
        }
    }
}

struct LocationSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let timeZoneIdentifier: String?
    let coordinate: CLLocationCoordinate2D?

    @MainActor
    init?(placemark: CLPlacemark) {
        guard let name = placemark.locality ?? placemark.name else { return nil }
        self.title = name
        let regionParts = [placemark.administrativeArea, placemark.country].compactMap { $0 }
        self.subtitle = regionParts.joined(separator: ", ")
        self.timeZoneIdentifier = placemark.timeZone?.identifier
        self.coordinate = placemark.location?.coordinate
    }

    var widgetLocation: WidgetLocation {
        WidgetLocation(mode: .custom,
                       city: title,
                       region: subtitle,
                       timeZoneIdentifier: timeZoneIdentifier,
                       latitude: coordinate?.latitude,
                       longitude: coordinate?.longitude)
    }
}
