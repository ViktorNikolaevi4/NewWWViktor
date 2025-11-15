import SwiftUI
import AppKit

struct WidgetPreviewCard: View {
    let type: WidgetType
    let onAdd: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerSection

            previewContainer
                .frame(height: 140)
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
                Text(type.categoryLabel.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Spacer()
                layoutControls
            }

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(type.heroTitle)
                        .font(.title3.weight(.semibold))
                    Text(type.heroSubtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                addButton
            }
        }
    }

    private var previewContainer: some View {
        ZStack(alignment: .bottomLeading) {
            roundedPreviewBackground
                .scaleEffect(scale)
                .animation(.spring(response: 0.22, dampingFraction: 0.9), value: isHovered)
                .animation(.spring(response: 0.16, dampingFraction: 0.8), value: isPressed)

            preview
                .padding(.horizontal, 14)
                .padding(.vertical, 18)
        }
    }

    private var roundedPreviewBackground: some View {
        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
            .fill(LinearGradient(colors: [Color(hex: 0x1f1f23), Color(hex: 0x111111)],
                                 startPoint: .topLeading,
                                 endPoint: .bottomTrailing))
            .overlay(
                RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.15))
            )
    }

    private var addButton: some View {
        Button {
            isPressed = true
            onAdd()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                isPressed = false
            }
        } label: {
            Label("Add", systemImage: "plus.circle.fill")
                .labelStyle(.iconOnly)
                .font(.system(size: 20, weight: .semibold))
        }
        .buttonStyle(.plain)
    }

    private var layoutControls: some View {
        HStack(spacing: 6) {
            ForEach(WidgetLayoutControl.allCases) { control in
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(control == .active ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: control.size.width, height: control.size.height)
            }
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(type.detailTitle)
                .font(.headline.weight(.semibold))
            Text(type.detailDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Text(type.detailLinkTitle)
                .font(.footnote.weight(.semibold))
                .foregroundColor(.primary)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 30, style: .continuous)
            .fill(Color.black.opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: 30, style: .continuous)
                    .stroke(Color.white.opacity(0.02))
            )
    }

    // MARK: - Preview Content

    private var scale: CGFloat {
        (isHovered || isPressed) ? 1.04 : 1.0
    }

    @ViewBuilder
    private var preview: some View {
        switch type {
        case .clock:
            ClockWidgetView()
        }
    }
}

private enum WidgetLayoutControl: CaseIterable, Identifiable {
    case active, medium, large

    var id: Self { self }

    var size: CGSize {
        switch self {
        case .active: return CGSize(width: 22, height: 14)
        case .medium: return CGSize(width: 28, height: 14)
        case .large: return CGSize(width: 34, height: 14)
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
