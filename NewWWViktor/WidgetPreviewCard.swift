import SwiftUI
import AppKit

struct WidgetPreviewCard: View {
    let type: WidgetType
    let onAdd: (WidgetSizeOption) -> Void

    @EnvironmentObject private var localization: LocalizationManager
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var previewSizeOption: WidgetSizeOption = .medium

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            previewContainer
                #if os(macOS)
                .onHover { hover in
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                        isHovered = hover
                    }
                }
                #endif

            infoSection

            Divider()
                .background(Color.white.opacity(0.08))
        }
        .padding(18)
        .background(cardBackground)
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.08))
        )
    }

    // MARK: - Subviews

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(localization.text(type.categoryLabelKey).uppercased())
                    .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                Spacer()
                layoutControls
            }
        }
    }

    private var previewContainer: some View {
        let size = previewDisplaySize
        return ZStack(alignment: .bottomLeading) {
            roundedPreviewBackground

            preview
                .padding(.horizontal, 14)
                .padding(.vertical, 18)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(scale, anchor: .topLeading)
        .animation(.spring(response: 0.22, dampingFraction: 0.9), value: isHovered)
        .animation(.spring(response: 0.16, dampingFraction: 0.8), value: isPressed)
        .overlay(alignment: .topTrailing) {
            addButton
                .opacity(showAddButton ? 1 : 0)
                .scaleEffect(showAddButton ? 1 : 0.8)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showAddButton)
                .padding(12)
                .allowsHitTesting(showAddButton)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 4)
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: previewSizeOption)
    }

    private var roundedPreviewBackground: some View {
        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x3b3f4b), Color(hex: 0x2a2d36)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.25))
            )
    }

    private var addButton: some View {
        Button {
            isPressed = true
            onAdd(previewSizeOption)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                isPressed = false
            }
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.black)
                .padding(8)
                .background(
                    Circle()
                        .fill(LinearGradient(colors: [Color(hex: 0x81fbb8), Color(hex: 0x28c76f)],
                                             startPoint: .topLeading,
                                             endPoint: .bottomTrailing))
                )
                .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }

    private var layoutControls: some View {
        HStack(spacing: 8) {
            ForEach(WidgetSizeOption.allCases) { option in
                let isSelected = previewSizeOption == option
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        previewSizeOption = option
                    }
                } label: {
                    Image(option.iconAssetName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 20)
                        .foregroundColor(isSelected ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.text(type.detailTitleKey))
                .font(.headline.weight(.semibold))
            Text(localization.text(type.detailDescriptionKey))
                .font(.subheadline)
                .foregroundColor(.secondary)

            if let linkKey = type.detailLinkTitleKey {
                Text(localization.text(linkKey))
                    .font(.footnote.weight(.semibold))
                    .foregroundColor(.primary)
            }
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.black.opacity(0.7))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.05))
            )
    }

    // MARK: - Preview Content

    private var scale: CGFloat {
        (isHovered || isPressed) ? 1.04 : 1.0
    }

    private var showAddButton: Bool {
        #if os(macOS)
        return isHovered || isPressed
        #else
        return true
        #endif
    }

    @ViewBuilder
    private var preview: some View {
        switch type {
        case .clock:
            ClockWidgetView(widget: previewWidget)
        }
    }

    private var previewWidget: WidgetInstance {
        var instance = WidgetInstance(type: type)
        instance.location = .current
        instance.applySizeOption(previewSizeOption)
        return instance
    }

    private var previewDisplaySize: CGSize {
        let maxWidth: CGFloat = 300
        let maxHeight: CGFloat = 170
        let size = previewSizeOption.dimensions
        let widthScale = maxWidth / size.width
        let heightScale = maxHeight / size.height
        let scale = min(widthScale, heightScale)
        return CGSize(width: size.width * scale, height: size.height * scale)
    }
}

private extension WidgetSizeOption {
    var iconAssetName: String {
        switch self {
        case .small:
            return "widget size s"
        case .medium:
            return "widget size m"
        }
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xff) / 255,
                  green: Double((hex >> 8) & 0xff) / 255,
                  blue: Double(hex & 0xff) / 255,
                  opacity: alpha)
    }
}
