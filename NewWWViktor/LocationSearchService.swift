import Foundation
import Combine
import CoreLocation
import MapKit

final class LocationSearchService: NSObject, ObservableObject {
    @Published var results: [LocationSearchResult] = []
    @Published var isSearching: Bool = false

    private let completer = MKLocalSearchCompleter()
    private var pendingWorkItem: DispatchWorkItem?
    private var currentLocale: Locale = .current
    private var searchToken = UUID()
    private let collectQueue = DispatchQueue(label: "location.search.collect")
    private var lastQueryFragment: String?

    override init() {
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

        // Avoid re-requesting if the query text didn't meaningfully change (e.g., trailing spaces).
        if normalized == lastQueryFragment {
            return
        }
        lastQueryFragment = normalized

        isSearching = true
        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.searchToken = UUID()
            self.completer.queryFragment = normalized
        }
        pendingWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: workItem)
    }

    private func resetResults() {
        DispatchQueue.main.async {
            self.results = []
            self.isSearching = false
        }
    }

    private func buildResults(from completions: [MKLocalSearchCompletion]) {
        let token = searchToken
        let limited = Array(completions.prefix(8))
        guard !limited.isEmpty else {
            resetResults()
            return
        }

        let group = DispatchGroup()
        var collected: [LocationSearchResult] = []
        let locale = currentLocale

        for completion in limited {
            group.enter()
            let request = MKLocalSearch.Request(completion: completion)
            request.resultTypes = .address

            let search = MKLocalSearch(request: request)
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

                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { placemarks, _ in
                    self.collectQueue.async {
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
            self.results = self.deduplicated(collected)
            self.isSearching = false
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
