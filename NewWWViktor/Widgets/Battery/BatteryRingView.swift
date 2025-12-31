import SwiftUI

struct BatteryRingView: View {
    let title: String
    let valueText: String
    let valueColor: Color
    let progress: Double
    let ringColor: Color
    let titleParts: [String]?
    let showsChargingIndicator: Bool
    let metrics: BatteryWidgetMetrics
    let secondaryColor: Color

    var body: some View {
        ZStack {
            Circle()
                .stroke(secondaryColor.opacity(0.25), lineWidth: metrics.ringLineWidth)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(ringColor, style: StrokeStyle(lineWidth: metrics.ringLineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text(valueText)
                    .font(.system(size: metrics.valueFontSize, weight: .bold, design: .rounded))
                    .foregroundStyle(valueColor)
                    .monospacedDigit()

                if let titleParts, titleParts.count >= 2 {
                    Text(titleParts[0].uppercased())
                        .font(.system(size: metrics.titleFontSize, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    Text(titleParts[1].uppercased())
                        .font(.system(size: metrics.titleFontSize, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                } else {
                    Text(title.uppercased())
                        .font(.system(size: metrics.titleFontSize, weight: .semibold))
                        .foregroundStyle(secondaryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .overlay(alignment: .top) {
            if showsChargingIndicator {
                Image(systemName: "bolt.fill")
                    .font(.system(size: metrics.ringSize * 0.14, weight: .bold))
                    .foregroundStyle(valueColor)
                    .padding(.top, 4)
            }
        }
        .frame(width: metrics.ringSize, height: metrics.ringSize)
    }
}
