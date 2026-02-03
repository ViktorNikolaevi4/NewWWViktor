import Foundation
import SwiftUI
import Combine

final class CryptoPriceProvider: ObservableObject {
    @Published private(set) var tickers: [String: CryptoTickerSnapshot] = [:]
    @Published private(set) var symbolInfo: [String: CryptoSymbolInfo] = [:]
    @Published private(set) var chartData: [String: [Double]] = [:]
    @Published private(set) var allSymbols: [String] = []
    @Published private(set) var allSymbolInfo: [String: CryptoSymbolInfo] = [:]

    private var timer: Timer?
    private var symbols: [String] = []
    private var isFetchingAllSymbols = false
    private let session: URLSession
    private let baseURLOverrideKey = "cryptoBinanceBaseURL"
    private let defaultBaseURLs: [URL] = [
        URL(string: "https://api.binance.com")!,
        URL(string: "https://api1.binance.com")!,
        URL(string: "https://api2.binance.com")!,
        URL(string: "https://api3.binance.com")!,
        URL(string: "https://api4.binance.com")!,
        URL(string: "https://api-gcp.binance.com")!
    ]
    private let coinGeckoBaseURL = URL(string: "https://api.coingecko.com/api/v3")!
    private let defaultSymbols: [String] = ["BTCUSDT", "ETHUSDT", "SOLUSDT", "BNBUSDT", "XRPUSDT", "DOGEUSDT"]
    private let coinGeckoOverrides: [String: String] = [
        "BTC": "bitcoin",
        "ETH": "ethereum",
        "SOL": "solana",
        "BNB": "binancecoin",
        "XRP": "ripple",
        "DOGE": "dogecoin",
        "USDT": "tether"
    ]
    private var coinGeckoSymbolToId: [String: String] = [:]
    private var isFetchingCoinGeckoList = false
    private var binanceBlockedUntil: Date?
    private var coinGeckoBlockedUntil: Date?
    private var coinGeckoChartLastUpdated: [String: Date] = [:]
    private var coinGeckoChartInFlight: Set<String> = []
    private let coinGeckoChartMinInterval: TimeInterval = 300
    private let binanceBlockInterval: TimeInterval = 600
    private let coinGeckoBlockInterval: TimeInterval = 300

    init(session: URLSession = CryptoPriceProvider.makeSession()) {
        self.session = session
    }

    func start(interval: TimeInterval, symbols: [String]) {
        updateSymbols(symbols)
        if !self.symbols.isEmpty {
            scheduleTimer(interval: interval)
        }
    }

    func loadAllSymbolsIfNeeded() {
        guard allSymbols.isEmpty else { return }
        guard !isFetchingAllSymbols else { return }
        isFetchingAllSymbols = true
        fetchAllSymbols()
    }

    func updateSymbols(_ symbols: [String]) {
        let unique = Array(Set(symbols)).sorted()
        guard unique != self.symbols else { return }
        self.symbols = unique
        if unique.isEmpty {
            DispatchQueue.main.async {
                self.tickers.removeAll()
                self.symbolInfo.removeAll()
                self.chartData.removeAll()
            }
            timer?.invalidate()
            return
        }
        fetchExchangeInfo()
        fetchTickers()
        fetchKlines()
    }

    private func scheduleTimer(interval: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.fetchTickers()
            self?.fetchKlines()
        }
        timer?.tolerance = interval * 0.1
    }

    private func fetchExchangeInfo() {
        guard !symbols.isEmpty else { return }
        if isBinanceBlocked() { return }
        let symbolsValue = encodedSymbolsParameter(symbols)
        let queryItems = [
            URLQueryItem(name: "symbols", value: symbolsValue)
        ]
        requestBinance(path: "/api/v3/exchangeInfo", queryItems: queryItems) { [weak self] data, response, _ in
            guard let self else { return }
            if let data, let response = try? JSONDecoder().decode(BinanceExchangeInfo.self, from: data) {
                let info = response.symbols.reduce(into: [String: CryptoSymbolInfo]()) { dict, symbol in
                    dict[symbol.symbol] = CryptoSymbolInfo(base: symbol.baseAsset, quote: symbol.quoteAsset)
                }
                DispatchQueue.main.async {
                    self.symbolInfo = info
                }
            } else {
                // Intentionally no logging on decode failure to keep console clean.
                if response?.statusCode == 451 {
                    self.setBinanceBlocked()
                    self.applyFallbackSymbolInfo(for: self.symbols)
                }
            }
        }
    }

    private func fetchAllSymbols() {
        if isBinanceBlocked() {
            applyFallbackAllSymbols()
            loadCoinGeckoListIfNeeded { [weak self] in
                self?.applyCoinGeckoAllSymbols()
            }
            return
        }
        requestBinance(path: "/api/v3/exchangeInfo", queryItems: []) { [weak self] data, response, _ in
            guard let self else { return }
            if let data, let response = try? JSONDecoder().decode(BinanceExchangeInfo.self, from: data) {
                let info = response.symbols.reduce(into: [String: CryptoSymbolInfo]()) { dict, symbol in
                    dict[symbol.symbol] = CryptoSymbolInfo(base: symbol.baseAsset, quote: symbol.quoteAsset)
                }
                let symbols = response.symbols.map { $0.symbol }.sorted()
                DispatchQueue.main.async {
                    self.allSymbols = symbols
                    self.allSymbolInfo = info
                    self.isFetchingAllSymbols = false
                }
            } else {
                // Intentionally no logging on decode failure to keep console clean.
                DispatchQueue.main.async {
                    self.isFetchingAllSymbols = false
                }
                if response?.statusCode == 451 {
                    self.setBinanceBlocked()
                    self.applyFallbackAllSymbols()
                    self.loadCoinGeckoListIfNeeded { [weak self] in
                        self?.applyCoinGeckoAllSymbols()
                    }
                }
            }
        }
    }

    private func fetchTickers() {
        guard !symbols.isEmpty else { return }
        if isBinanceBlocked() {
            fetchCoinGeckoTickers(for: symbols)
            return
        }
        let symbolsValue = encodedSymbolsParameter(symbols)
        let queryItems = [
            URLQueryItem(name: "symbols", value: symbolsValue)
        ]
        requestBinance(path: "/api/v3/ticker/24hr", queryItems: queryItems) { [weak self] data, response, _ in
            guard let self else { return }
            if let data, let array = try? JSONDecoder().decode([Binance24hTicker].self, from: data) {
                self.storeTickers(array)
            } else if let data, let single = try? JSONDecoder().decode(Binance24hTicker.self, from: data) {
                self.storeTickers([single])
            } else {
                // Intentionally no logging on decode failure to keep console clean.
                if response?.statusCode == 451 {
                    self.setBinanceBlocked()
                    self.fetchCoinGeckoTickers(for: self.symbols)
                }
            }
        }
    }

    private func fetchKlines() {
        guard !symbols.isEmpty else { return }
        if isBinanceBlocked() {
            symbols.forEach { fetchCoinGeckoChart(for: $0) }
            return
        }
        for symbol in symbols {
            let queryItems = [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "interval", value: "15m"),
                URLQueryItem(name: "limit", value: "4")
            ]
            requestBinance(path: "/api/v3/klines", queryItems: queryItems) { [weak self] data, response, _ in
                guard let self else { return }
                guard let data else {
                    if response?.statusCode == 451 {
                        // Intentionally no logging on blocked klines to keep console clean.
                        self.setBinanceBlocked()
                        self.fetchCoinGeckoChart(for: symbol)
                    }
                    return
                }
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else {
                    // Intentionally no logging on decode failure to keep console clean.
                    return
                }
                let closes: [Double] = json.compactMap { item in
                    guard item.count > 4 else { return nil }
                    if let closeString = item[4] as? String {
                        return Double(closeString)
                    }
                    if let closeNumber = item[4] as? Double {
                        return closeNumber
                    }
                    return nil
                }
                DispatchQueue.main.async {
                    self.chartData[symbol] = closes
                }
            }
        }
    }

    private func storeTickers(_ items: [Binance24hTicker]) {
        let mapped = items.reduce(into: [String: CryptoTickerSnapshot]()) { dict, item in
            dict[item.symbol] = CryptoTickerSnapshot(
                symbol: item.symbol,
                lastPrice: Double(item.lastPrice) ?? 0,
                changePercent: Double(item.priceChangePercent) ?? 0
            )
        }
        DispatchQueue.main.async {
            self.tickers.merge(mapped) { _, new in new }
        }
    }

    private func encodedSymbolsParameter(_ symbols: [String]) -> String {
        let json = try? JSONSerialization.data(withJSONObject: symbols)
        if let data = json, let raw = String(data: data, encoding: .utf8) {
            return raw
        }
        return "[\"\(symbols.joined(separator: "\",\""))\"]"
    }

    private func requestBinance(path: String,
                                queryItems: [URLQueryItem],
                                completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        let baseURLs = candidateBaseURLs()
        let urls = baseURLs.compactMap { makeURL(base: $0, path: path, queryItems: queryItems) }
        fetchData(from: urls, completion: completion)
    }

    private static func makeSession() -> URLSession {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 8
        config.timeoutIntervalForResource = 15
        config.waitsForConnectivity = true
        return URLSession(configuration: config)
    }

    private func candidateBaseURLs() -> [URL] {
        if let override = UserDefaults.standard.string(forKey: baseURLOverrideKey),
           let url = normalizedOverrideURL(override) {
            return [url] + defaultBaseURLs.filter { $0 != url }
        }
        return defaultBaseURLs
    }

    private func normalizedOverrideURL(_ raw: String) -> URL? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }
        return URL(string: "https://\(trimmed)")
    }

    private func makeURL(base: URL, path: String, queryItems: [URLQueryItem]) -> URL? {
        var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
        components?.path = path
        components?.queryItems = queryItems.isEmpty ? nil : queryItems
        return components?.url
    }

    private func fetchData(from urls: [URL], completion: @escaping (Data?, HTTPURLResponse?, Error?) -> Void) {
        guard let first = urls.first else {
            completion(nil, nil, nil)
            return
        }
        session.dataTask(with: first) { [weak self] data, response, error in
            let http = response as? HTTPURLResponse
            if let data, let http, (200..<300).contains(http.statusCode) {
                completion(data, http, nil)
            } else if let self {
                let status = http?.statusCode
                // Intentionally no logging on request failure to keep console clean.
                if urls.count > 1 {
                    self.fetchData(from: Array(urls.dropFirst()), completion: completion)
                } else {
                    completion(nil, http, error)
                }
            } else {
                completion(nil, http, error)
            }
        }.resume()
    }

    private func fetchCoinGeckoTickers(for symbols: [String]) {
        guard !isCoinGeckoBlocked() else { return }
        let coinIds = coinGeckoIds(for: symbols)
        if !coinIds.missing.isEmpty {
            loadCoinGeckoListIfNeeded { [weak self] in
                guard let self else { return }
                let refreshed = self.coinGeckoIds(for: symbols)
                self.fetchCoinGeckoPrice(ids: refreshed.ids, symbolMap: refreshed.map)
            }
            return
        }
        fetchCoinGeckoPrice(ids: coinIds.ids, symbolMap: coinIds.map)
    }

    private func fetchCoinGeckoChart(for symbol: String) {
        guard !isCoinGeckoBlocked() else { return }
        if let last = coinGeckoChartLastUpdated[symbol],
           Date().timeIntervalSince(last) < coinGeckoChartMinInterval {
            return
        }
        if coinGeckoChartInFlight.contains(symbol) {
            return
        }
        let coinIds = coinGeckoIds(for: [symbol])
        if let id = coinIds.map[symbol] {
            fetchCoinGeckoChartData(id: id, symbol: symbol)
            return
        }
        if !coinIds.missing.isEmpty {
            loadCoinGeckoListIfNeeded { [weak self] in
                guard let self else { return }
                let refreshed = self.coinGeckoIds(for: [symbol])
                if let id = refreshed.map[symbol] {
                    self.fetchCoinGeckoChartData(id: id, symbol: symbol)
                }
            }
        }
    }

    private func fetchCoinGeckoChartData(id: String, symbol: String) {
        var components = URLComponents(url: coinGeckoBaseURL.appendingPathComponent("/coins/\(id)/market_chart"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "vs_currency", value: "usd"),
            URLQueryItem(name: "days", value: "1")
        ]
        guard let url = components?.url else { return }
        coinGeckoChartInFlight.insert(symbol)
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            defer { self.coinGeckoChartInFlight.remove(symbol) }
            if let data,
               let http = response as? HTTPURLResponse,
               (200..<300).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let prices = json["prices"] as? [[Any]] {
                let values: [Double] = prices.compactMap { item in
                    guard item.count > 1 else { return nil }
                    if let price = item[1] as? Double { return price }
                    if let priceString = item[1] as? String { return Double(priceString) }
                    return nil
                }
                let trimmed = values.suffix(12)
                DispatchQueue.main.async {
                    self.chartData[symbol] = Array(trimmed)
                    self.coinGeckoChartLastUpdated[symbol] = Date()
                }
            } else {
                let status = (response as? HTTPURLResponse)?.statusCode
                // Intentionally no logging on CoinGecko errors to keep console clean.
                if status == 429 {
                    self.setCoinGeckoBlocked()
                }
            }
        }.resume()
    }

    private func fetchCoinGeckoPrice(ids: [String], symbolMap: [String: String]) {
        guard !ids.isEmpty else { return }
        var components = URLComponents(url: coinGeckoBaseURL.appendingPathComponent("/simple/price"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "ids", value: ids.joined(separator: ",")),
            URLQueryItem(name: "vs_currencies", value: "usd"),
            URLQueryItem(name: "include_24hr_change", value: "true")
        ]
        guard let url = components?.url else { return }
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            if let data,
               let http = response as? HTTPURLResponse,
               (200..<300).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Double]] {
                let mapped = symbolMap.reduce(into: [String: CryptoTickerSnapshot]()) { dict, item in
                    let symbol = item.key
                    let id = item.value
                    guard let payload = json[id], let price = payload["usd"] else { return }
                    let change = payload["usd_24h_change"] ?? 0
                    dict[symbol] = CryptoTickerSnapshot(symbol: symbol, lastPrice: price, changePercent: change)
                }
                DispatchQueue.main.async {
                    self.tickers.merge(mapped) { _, new in new }
                }
            } else {
                let status = (response as? HTTPURLResponse)?.statusCode
                // Intentionally no logging on CoinGecko errors to keep console clean.
                if status == 429 {
                    self.setCoinGeckoBlocked()
                }
            }
        }.resume()
    }

    private func loadCoinGeckoListIfNeeded(completion: @escaping () -> Void) {
        if !coinGeckoSymbolToId.isEmpty {
            completion()
            return
        }
        guard !isFetchingCoinGeckoList else { return }
        isFetchingCoinGeckoList = true
        let url = coinGeckoBaseURL.appendingPathComponent("/coins/list")
        session.dataTask(with: url) { [weak self] data, response, error in
            guard let self else { return }
            defer {
                DispatchQueue.main.async {
                    self.isFetchingCoinGeckoList = false
                }
            }
            if let data,
               let http = response as? HTTPURLResponse,
               (200..<300).contains(http.statusCode),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                var mapping: [String: String] = [:]
                for item in json {
                    guard let symbol = item["symbol"] as? String,
                          let id = item["id"] as? String else { continue }
                    if mapping[symbol.lowercased()] == nil {
                        mapping[symbol.lowercased()] = id
                    }
                }
                DispatchQueue.main.async {
                    self.coinGeckoSymbolToId = mapping
                    completion()
                }
            } else {
                let status = (response as? HTTPURLResponse)?.statusCode
                // Intentionally no logging on CoinGecko errors to keep console clean.
                if status == 429 {
                    self.setCoinGeckoBlocked()
                }
            }
        }.resume()
    }

    private func coinGeckoIds(for symbols: [String]) -> (ids: [String], map: [String: String], missing: [String]) {
        var ids: [String] = []
        var map: [String: String] = [:]
        var missing: [String] = []
        for symbol in symbols {
            guard let parts = baseAndQuote(for: symbol), parts.quote == "USDT" else { continue }
            let base = parts.base
            if let override = coinGeckoOverrides[base] {
                ids.append(override)
                map[symbol] = override
                continue
            }
            if let id = coinGeckoSymbolToId[base.lowercased()] {
                ids.append(id)
                map[symbol] = id
            } else {
                missing.append(base)
            }
        }
        return (Array(Set(ids)), map, missing)
    }

    private func baseAndQuote(for symbol: String) -> (base: String, quote: String)? {
        if symbol.hasSuffix("USDT") {
            let base = String(symbol.dropLast(4))
            return (base: base, quote: "USDT")
        }
        return nil
    }

    private func applyFallbackSymbolInfo(for symbols: [String]) {
        let info = symbols.reduce(into: [String: CryptoSymbolInfo]()) { dict, symbol in
            if let parts = baseAndQuote(for: symbol) {
                dict[symbol] = CryptoSymbolInfo(base: parts.base, quote: parts.quote)
            }
        }
        DispatchQueue.main.async {
            if !info.isEmpty {
                self.symbolInfo.merge(info) { _, new in new }
            }
        }
    }

    private func applyFallbackAllSymbols() {
        let info = defaultSymbols.reduce(into: [String: CryptoSymbolInfo]()) { dict, symbol in
            if let parts = baseAndQuote(for: symbol) {
                dict[symbol] = CryptoSymbolInfo(base: parts.base, quote: parts.quote)
            }
        }
        DispatchQueue.main.async {
            self.allSymbols = self.defaultSymbols
            self.allSymbolInfo = info
            self.isFetchingAllSymbols = false
        }
    }

    private func applyCoinGeckoAllSymbols() {
        guard !coinGeckoSymbolToId.isEmpty else { return }
        let symbols = coinGeckoSymbolToId.keys
            .map { $0.uppercased() + "USDT" }
            .sorted()
        let info = symbols.reduce(into: [String: CryptoSymbolInfo]()) { dict, symbol in
            if let parts = baseAndQuote(for: symbol) {
                dict[symbol] = CryptoSymbolInfo(base: parts.base, quote: parts.quote)
            }
        }
        DispatchQueue.main.async {
            self.allSymbols = symbols
            self.allSymbolInfo = info
            self.isFetchingAllSymbols = false
        }
    }

    private func isBinanceBlocked() -> Bool {
        if let until = binanceBlockedUntil, until > Date() {
            return true
        }
        return false
    }

    private func setBinanceBlocked() {
        binanceBlockedUntil = Date().addingTimeInterval(binanceBlockInterval)
    }

    private func isCoinGeckoBlocked() -> Bool {
        if let until = coinGeckoBlockedUntil, until > Date() {
            return true
        }
        return false
    }

    private func setCoinGeckoBlocked() {
        coinGeckoBlockedUntil = Date().addingTimeInterval(coinGeckoBlockInterval)
    }

    // Logging removed per request.
}

struct CryptoTickerSnapshot {
    let symbol: String
    let lastPrice: Double
    let changePercent: Double
}

struct CryptoSymbolInfo {
    let base: String
    let quote: String
}

private struct Binance24hTicker: Decodable {
    let symbol: String
    let lastPrice: String
    let priceChangePercent: String
}

private struct BinanceExchangeInfo: Decodable {
    let symbols: [BinanceSymbolInfo]
}

private struct BinanceSymbolInfo: Decodable {
    let symbol: String
    let baseAsset: String
    let quoteAsset: String
}
