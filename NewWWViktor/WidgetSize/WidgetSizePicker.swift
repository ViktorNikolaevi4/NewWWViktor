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
        Image(option.iconAssetName)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 50, height: 32)
            .foregroundColor(isSelected ? .white : .white.opacity(0.55))
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
    }
}
