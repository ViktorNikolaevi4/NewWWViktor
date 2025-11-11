import SwiftUI
import AppKit

struct WidgetPreviewCard: View {
    let type: WidgetType
    let onAdd: () -> Void

    @State private var isHovered = false
    @State private var isPressed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header

            previewContainer
                .frame(height: 110)
                #if os(macOS)
                .onHover { hover in
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.9)) {
                        isHovered = hover
                    }
                }
                #endif
        }
        .padding(10)
        .background(cardBackground)
    }

    // MARK: - Subviews

    private var header: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(type.title)
                .font(.subheadline.weight(.semibold))
            Text(type.subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var previewContainer: some View {
        ZStack(alignment: .topLeading) {
            roundedPreviewBackground
                .scaleEffect(scale)
                .animation(.spring(response: 0.22, dampingFraction: 0.9), value: isHovered)
                .animation(.spring(response: 0.16, dampingFraction: 0.8), value: isPressed)

            preview
                .padding(.top, 10)
                .padding(.horizontal, 10)
                .frame(maxWidth: .infinity,
                       maxHeight: 72,          // было 80 — чуть меньше, фон снизу больше
                       alignment: .top)

            if isHovered {
                addButton
                    .padding(8)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(height: 110)                      // можно 130–140, подбирай по вкусу
    }



    private var roundedPreviewBackground: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(Color.white.opacity(0.18))
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

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Color.white.opacity(0.02))
            .overlay(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(Color.white.opacity(0.04))
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
