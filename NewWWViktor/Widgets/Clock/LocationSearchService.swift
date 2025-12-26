import Foundation
import Combine
import CoreLocation
import MapKit

final class LocationSearchService: NSObject, ObservableObject {
    @Published var results: [LocationSearchResult] = []
    @Published var isSearching: Bool = false

    private enum Constants {
        static let maxResults = 8
        static let debounceInterval: TimeInterval = 0.25
        static let collectionQueueLabel = "location.search.collect"
    }

    private let completer: LocalSearchCompleting
    private let searchFactory: LocalSearchCreating
    private let geocoderFactory: ReverseGeocodingFactory
    private var pendingWorkItem: DispatchWorkItem?
    private var currentLocale: Locale = .current
    private var searchToken = UUID()
    private let collectionQueue = DispatchQueue(label: Constants.collectionQueueLabel)
    private var lastQueryFragment: String?

    override init() {
        self.completer = MKLocalSearchCompleter()
        self.searchFactory = SystemLocalSearchFactory()
        self.geocoderFactory = SystemGeocodingFactory()
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
    }

    init(
        completer: LocalSearchCompleting,
        searchFactory: LocalSearchCreating,
        geocoderFactory: ReverseGeocodingFactory
    ) {
        self.completer = completer
        self.searchFactory = searchFactory
        self.geocoderFactory = geocoderFactory
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address]
    }

    func update(query: String, locale: Locale) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized = normalizedQuery(from: trimmed)
        pendingWorkItem?.cancel()
        currentLocale = locale

        guard normalized.count >= 2 else {
            lastQueryFragment = nil
            resetResults()
            completer.cancel()
            return
        }

        lastQueryFragment = normalized

        isSearching = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            let token = UUID()
            self.searchToken = token
            self.performDirectSearch(query: normalized, token: token)
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.debounceInterval, execute: workItem)
    }

    func reset() {
        pendingWorkItem?.cancel()
        pendingWorkItem = nil
        lastQueryFragment = nil
        searchToken = UUID()
        resetResults()
    }

    private func resetResults() {
        DispatchQueue.main.async {
            self.results = []
            self.isSearching = false
        }
    }

    private func buildResults(from completions: [MKLocalSearchCompletion]) {
        let token = searchToken
        let limited = Array(completions.prefix(Constants.maxResults))
        guard !limited.isEmpty else { return }

        let group = DispatchGroup()
        var collected: [LocationSearchResult] = []
        let locale = currentLocale

        for completion in limited {
            group.enter()
            let request = MKLocalSearch.Request(completion: completion)
            request.resultTypes = .address

            let search = searchFactory.makeSearch(request: request)
            search.start { [weak self] response, _ in
                guard let self else {
                    group.leave()
                    return
                }
                guard self.searchToken == token else {
                    group.leave()
                    return
                }
                guard let item = response?.mapItems.first,
                      let location = item.placemark.location else {
                    group.leave()
                    return
                }

                let geocoder = geocoderFactory.makeGeocoder()
                geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, _ in
                    self.collectionQueue.async {
                        if self.searchToken == token {
                            if let placemark = placemarks?.first,
                               let result = LocationSearchResult(placemark: placemark) {
                                collected.append(result)
                            } else if let result = LocationSearchResult(placemark: item.placemark) {
                                collected.append(result)
                            }
                        }
                        group.leave()
                    }
                }
            }
        }

        group.notify(queue: .main) { [weak self] in
            guard let self else { return }
            guard self.searchToken == token else { return }
            let merged = self.deduplicated(self.results + collected)
            self.results = merged
        }
    }

    private func performDirectSearch(query: String, token: UUID) {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.resultTypes = .address
        let search = searchFactory.makeSearch(request: request)

        search.start { [weak self] response, _ in
            guard let self else { return }
            guard self.searchToken == token else { return }

            let items = response?.mapItems.prefix(Constants.maxResults) ?? []
            let locale = currentLocale
            let group = DispatchGroup()
            var collected: [LocationSearchResult] = []

            for item in items {
                group.enter()
                let location = item.placemark.location
                let geocoder = geocoderFactory.makeGeocoder()
                if let location {
                    geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, _ in
                        self.collectionQueue.async {
                            if self.searchToken == token {
                                if let placemark = placemarks?.first,
                                   let result = LocationSearchResult(placemark: placemark) {
                                    collected.append(result)
                                } else if let result = LocationSearchResult(placemark: item.placemark) {
                                    collected.append(result)
                                }
                            }
                            group.leave()
                        }
                    }
                } else {
                    self.collectionQueue.async {
                        if let result = LocationSearchResult(placemark: item.placemark) {
                            collected.append(result)
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) { [weak self] in
                guard let self else { return }
                guard self.searchToken == token else { return }
                self.results = self.deduplicated(collected)
                self.isSearching = false
            }
        }
    }

    private func deduplicated(_ items: [LocationSearchResult]) -> [LocationSearchResult] {
        var seen: Set<String> = []
        var output: [LocationSearchResult] = []

        for item in items {
            let titleKey = item.title.lowercased()
            let subtitleKey = item.subtitle.lowercased()
            let coordKey: String
            if let coordinate = item.coordinate {
                let lat = String(format: "%.3f", coordinate.latitude)
                let lon = String(format: "%.3f", coordinate.longitude)
                coordKey = "\(lat)|\(lon)"
            } else {
                coordKey = "nocoord"
            }

            let key = "\(titleKey)|\(subtitleKey)|\(coordKey)"
            if seen.contains(key) { continue }
            seen.insert(key)
            output.append(item)
        }
        return output
    }

    private func normalizedQuery(from text: String) -> String {
        let components = text.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        return components.joined(separator: " ")
    }
}

extension LocationSearchService: MKLocalSearchCompleterDelegate {
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        buildResults(from: completer.results)
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        resetResults()
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
