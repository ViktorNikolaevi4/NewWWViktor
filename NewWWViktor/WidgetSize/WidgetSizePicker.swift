import SwiftUI

struct WidgetSizePicker: View {
    @Binding var selection: WidgetSizeOption

    var body: some View {
        HStack(spacing: 10) {
            ForEach(WidgetSizeOption.allCases) { option in
                Button {
                    selection = option
                } label: {
                    sizeChip(for: option, isSelected: selection == option)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func sizeChip(for option: WidgetSizeOption, isSelected: Bool) -> some View {
        VStack(spacing: 6) {
            GeometryReader { proxy in
                let rect = shapeRect(in: proxy.size, option: option)
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white : Color.white.opacity(0.3))
                    .frame(width: rect.width, height: rect.height)
                    .position(x: proxy.size.width / 2, y: proxy.size.height / 2)
            }
            .frame(width: 50, height: 36)

            Text(option.title)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.7))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.white.opacity(0.15) : Color.white.opacity(0.08))
        )
    }

    private func shapeRect(in availableSize: CGSize, option: WidgetSizeOption) -> CGSize {
        let maxWidth = availableSize.width
        let maxHeight = availableSize.height
        let size = option.dimensions
        let widthScale = maxWidth / size.width
        let heightScale = maxHeight / size.height
        let scale = min(widthScale, heightScale)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}
