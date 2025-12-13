import SwiftUI
import AppKit

struct WidgetPreviewCard: View {
    let type: WidgetType
    let onAdd: (WidgetSizeOption) -> Void

    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var manager: WidgetManager
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
        VStack(alignment: .center, spacing: 8) {
            layoutControls
        }
        .frame(maxWidth: .infinity)
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
        .id(manager.globalColorsVersion) // refresh preview when global appearance changes
    }

    private var roundedPreviewBackground: some View {
        ZStack {
            if manager.globalBackgroundStyle == .photo {
                #if os(macOS)
                if let image = manager.globalBackgroundImage {
                    Image(nsImage: image)
                        .resizable()
                        .scaledToFill()
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                        .fill(.regularMaterial)
                }
                #else
                RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                    .fill(.regularMaterial)
                #endif
            } else {
                RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                    .fill(previewBackgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.25))
                    )
            }
        }
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
                .font(.title3.weight(.semibold))
            Text(localization.text(type.detailDescriptionKey))
                .font(.body.weight(.medium))
                .foregroundColor(.secondary)

            if let linkKey = type.detailLinkTitleKey {
                Text(localization.text(linkKey))
                    .font(.callout.weight(.semibold))
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
        case .weather:
            WeatherWidgetView(widget: previewWidget)
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

    private var previewBackgroundFill: AnyShapeStyle {
        switch effectiveBackgroundStyle {
        case .palette:
            let color = WidgetPaletteColor.color(
                named: manager.globalBackgroundColorName,
                intensity: manager.globalBackgroundIntensity,
                fallback: Color.white.opacity(0.14)
            )
            return AnyShapeStyle(color.opacity(0.96))
        case .solid:
            return AnyShapeStyle(Color.white.opacity(0.12))
        case .gradient:
            return gradientBackgroundStyle()
        case .photo:
            return AnyShapeStyle(.regularMaterial)
        }
    }

    private var effectiveBackgroundStyle: BackgroundStyle {
        if manager.globalBackgroundStyle == .palette,
           (manager.globalBackgroundColorName?.isEmpty ?? true) {
            return .photo // keep preview background unchanged until a palette color is selected
        }
        return manager.globalBackgroundStyle
    }

    private func gradientBackgroundStyle() -> AnyShapeStyle {
        let color1 = WidgetPaletteColor.color(
            named: manager.globalGradientColor1Name,
            intensity: manager.globalGradientColor1Opacity,
            fallback: Color.white.opacity(0.2)
        )
        let color2 = WidgetPaletteColor.color(
            named: manager.globalGradientColor2Name,
            intensity: manager.globalGradientColor2Opacity,
            fallback: Color.black.opacity(0.35)
        )

        let pos1 = max(0, min(1, manager.globalGradientColor1Position))
        let pos2 = max(0, min(1, manager.globalGradientColor2Position))
        let orderedStops = [
            (color: color1, location: pos1),
            (color: color2, location: pos2)
        ]
        .sorted { $0.location < $1.location }

        let stops = Gradient(stops: orderedStops.map {
            .init(color: $0.color, location: CGFloat($0.location))
        })

        switch manager.globalGradientType {
        case .linear:
            let points = anglePoints(degrees: manager.globalGradientAngle)
            return AnyShapeStyle(LinearGradient(gradient: stops,
                                                startPoint: points.start,
                                                endPoint: points.end))
        case .radial:
            return AnyShapeStyle(
                RadialGradient(gradient: stops,
                               center: .center,
                               startRadius: 0,
                               endRadius: 400)
            )
        case .angular:
            return AnyShapeStyle(AngularGradient(gradient: stops, center: .center))
        }
    }

    private func anglePoints(degrees: Double) -> (start: UnitPoint, end: UnitPoint) {
        // Convert angle into start/end points for a linear gradient.
        let radians = degrees * .pi / 180
        let x = cos(radians)
        let y = sin(radians)
        let start = UnitPoint(x: (1 - x) / 2, y: (1 - y) / 2)
        let end = UnitPoint(x: (1 + x) / 2, y: (1 + y) / 2)
        return (start, end)
    }
}

private extension WidgetSizeOption {
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
