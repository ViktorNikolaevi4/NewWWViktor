import SwiftUI

struct CryptoWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        Group {
            if widget.sizeOption == .extraLarge {
                extraLargeLayout
            } else {
                smallLayout
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.top, 6)
    }

    private var symbol: String {
        widget.cryptoSymbol
    }

    private var symbolLabel: String {
        if let info = manager.cryptoProvider.symbolInfo[symbol] {
            return "\(info.base)/\(info.quote)"
        }
        return symbol
    }

    private var ticker: CryptoTickerSnapshot? {
        manager.cryptoProvider.tickers[symbol]
    }

    private var header: some View {
        HStack {
            Text(symbolLabel)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.primary)
            Spacer()
            Text(localization.text(.widgetCryptoTitle))
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var priceRow: some View {
        Text(formattedPrice)
            .font(.system(size: 26, weight: .bold))
            .foregroundStyle(.primary)
    }

    private var changeRow: some View {
        HStack(spacing: 6) {
            Image(systemName: changeIsPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(formattedChange)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(changeIsPositive ? Color.green : Color.red)
    }

    private var chartView: some View {
        CryptoSparkline(values: manager.cryptoProvider.chartData[symbol] ?? [],
                        lineColor: changeIsPositive ? Color.green : Color.red)
            .frame(height: 36)
            .padding(.top, 4)
    }

    private var smallLayout: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            priceRow
            changeRow
            chartView
            Spacer(minLength: 0)
        }
    }

    private var extraLargeLayout: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(localization.text(.widgetCryptoTitle))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(displaySymbols, id: \.self) { item in
                        CryptoTickerRow(symbol: item,
                                        info: manager.cryptoProvider.allSymbolInfo[item] ?? manager.cryptoProvider.symbolInfo[item],
                                        ticker: manager.cryptoProvider.tickers[item],
                                        chart: manager.cryptoProvider.chartData[item] ?? [])
                    }
                }
            }
        }
        .padding(.horizontal, 2)
    }

    private var displaySymbols: [String] {
        let list = widget.cryptoSymbols.isEmpty ? [widget.cryptoSymbol] : widget.cryptoSymbols
        return Array(list.prefix(8))
    }

    private var formattedPrice: String {
        guard let ticker else { return localization.text(.widgetPlaceholderDash) }
        return priceFormatter.string(from: NSNumber(value: ticker.lastPrice)) ?? localization.text(.widgetPlaceholderDash)
    }

    private var formattedChange: String {
        guard let ticker else { return localization.text(.widgetPlaceholderDash) }
        let value = ticker.changePercent
        let sign = value > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", value))%"
    }

    private var changeIsPositive: Bool {
        (ticker?.changePercent ?? 0) >= 0
    }

    private var priceFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = priceFractionDigits
        formatter.maximumFractionDigits = priceFractionDigits
        return formatter
    }

    private var priceFractionDigits: Int {
        guard let price = ticker?.lastPrice else { return 2 }
        if price >= 1000 { return 0 }
        if price >= 1 { return 2 }
        return 4
    }
}

private struct CryptoTickerRow: View {
    let symbol: String
    let info: CryptoSymbolInfo?
    let ticker: CryptoTickerSnapshot?
    let chart: [Double]

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(subtitle)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 90, alignment: .leading)

            CryptoSparkline(values: chart, lineColor: changeIsPositive ? Color.green : Color.red)
                .frame(height: 22)

            VStack(alignment: .trailing, spacing: 2) {
                Text(priceText)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.primary)
                Text(changeText)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(changeIsPositive ? Color.green : Color.red)
            }
            .frame(width: 70, alignment: .trailing)
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 6)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private var label: String {
        info.map { "\($0.base)/\($0.quote)" } ?? symbol
    }

    private var subtitle: String {
        info?.base ?? ""
    }

    private var priceText: String {
        guard let price = ticker?.lastPrice else { return "—" }
        return formatPrice(price)
    }

    private var changeText: String {
        guard let change = ticker?.changePercent else { return "—" }
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", change))%"
    }

    private var changeIsPositive: Bool {
        (ticker?.changePercent ?? 0) >= 0
    }

    private func formatPrice(_ price: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = price >= 1000 ? 0 : (price >= 1 ? 2 : 4)
        formatter.maximumFractionDigits = formatter.minimumFractionDigits
        return formatter.string(from: NSNumber(value: price)) ?? "—"
    }
}

private struct CryptoSparkline: View {
    let values: [Double]
    let lineColor: Color

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size
            let points = normalizedPoints(in: size)
            if points.count > 1 {
                Path { path in
                    path.addLines(points)
                }
                .stroke(lineColor, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            } else {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            }
        }
    }

    private func normalizedPoints(in size: CGSize) -> [CGPoint] {
        guard values.count > 1 else { return [] }
        let minValue = values.min() ?? 0
        let maxValue = values.max() ?? 0
        let range = max(maxValue - minValue, 0.0001)
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let normalized = (value - minValue) / range
            let y = size.height * (1 - CGFloat(normalized))
            return CGPoint(x: x, y: y)
        }
    }
}
