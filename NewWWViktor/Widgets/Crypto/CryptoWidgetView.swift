import SwiftUI

struct CryptoWidgetView: View {
    let widget: WidgetInstance

    @EnvironmentObject private var manager: WidgetManager
    @EnvironmentObject private var localization: LocalizationManager

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header
            priceRow
            changeRow
            chartView
            Spacer(minLength: 0)
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
