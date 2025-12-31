import SwiftUI

struct BatteryDetailItem: Identifiable, Equatable {
    let title: String
    let value: String

    var id: String { title }
}

struct BatteryDetailsView: View {
    let items: [BatteryDetailItem]
    let secondaryColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(items) { item in
                BatteryDetailRow(title: item.title,
                                 value: item.value,
                                 color: secondaryColor)
            }
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(secondaryColor.opacity(0.9))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct BatteryDetailRow: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .foregroundStyle(color.opacity(0.75))
            Spacer()
            Text(value)
                .foregroundStyle(color)
        }
    }
}
