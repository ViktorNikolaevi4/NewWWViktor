import SwiftUI

struct WidgetSizePicker: View {
    @Binding var selection: WidgetSizeOption
    var availableSizes: [WidgetSizeOption] = WidgetSizeOption.allCases

    var body: some View {
        HStack(spacing: 0) {
            ForEach(availableSizes) { option in
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
            .frame(width: 40, height: 26)
            .foregroundColor(isSelected ? .white : .white.opacity(0.55))
            .padding(.vertical, 0)
            .padding(.horizontal, 0)
            .contentShape(Rectangle())
    }
}
