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
        .overlay(alignment: .topTrailing) {
            addButton
                .opacity(showAddButton ? 1 : 0)
                .scaleEffect(showAddButton ? 1 : 0.8)
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: showAddButton)
                .padding(12)
                .allowsHitTesting(showAddButton)
        }
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
            onAdd()
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
