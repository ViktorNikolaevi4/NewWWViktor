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

    init(session: URLSession = .shared) {
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
        var components = URLComponents(string: "https://api.binance.com/api/v3/exchangeInfo")
        let symbolsValue = encodedSymbolsParameter(symbols)
        components?.queryItems = [
            URLQueryItem(name: "symbols", value: symbolsValue)
        ]
        guard let url = components?.url else { return }

        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data else { return }
            if let response = try? JSONDecoder().decode(BinanceExchangeInfo.self, from: data) {
                let info = response.symbols.reduce(into: [String: CryptoSymbolInfo]()) { dict, symbol in
                    dict[symbol.symbol] = CryptoSymbolInfo(base: symbol.baseAsset, quote: symbol.quoteAsset)
                }
                DispatchQueue.main.async {
                    self.symbolInfo = info
                }
            }
        }.resume()
    }

    private func fetchAllSymbols() {
        guard let url = URL(string: "https://api.binance.com/api/v3/exchangeInfo") else { return }
        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data else { return }
            if let response = try? JSONDecoder().decode(BinanceExchangeInfo.self, from: data) {
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
                DispatchQueue.main.async {
                    self.isFetchingAllSymbols = false
                }
            }
        }.resume()
    }

    private func fetchTickers() {
        guard !symbols.isEmpty else { return }
        var components = URLComponents(string: "https://api.binance.com/api/v3/ticker/24hr")
        let symbolsValue = encodedSymbolsParameter(symbols)
        components?.queryItems = [
            URLQueryItem(name: "symbols", value: symbolsValue)
        ]
        guard let url = components?.url else { return }

        session.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data else { return }
            if let array = try? JSONDecoder().decode([Binance24hTicker].self, from: data) {
                self.storeTickers(array)
            } else if let single = try? JSONDecoder().decode(Binance24hTicker.self, from: data) {
                self.storeTickers([single])
            }
        }.resume()
    }

    private func fetchKlines() {
        guard !symbols.isEmpty else { return }
        for symbol in symbols {
            var components = URLComponents(string: "https://api.binance.com/api/v3/klines")
            components?.queryItems = [
                URLQueryItem(name: "symbol", value: symbol),
                URLQueryItem(name: "interval", value: "15m"),
                URLQueryItem(name: "limit", value: "4")
            ]
            guard let url = components?.url else { continue }

            session.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data else { return }
                guard let json = try? JSONSerialization.jsonObject(with: data) as? [[Any]] else { return }
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
            }.resume()
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
