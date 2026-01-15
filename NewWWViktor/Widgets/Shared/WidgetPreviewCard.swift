import SwiftUI
import AppKit
import SwiftData

struct WidgetPreviewCard: View {
    let type: WidgetType
    let onAdd: (WidgetSizeOption) -> Void

    @EnvironmentObject private var localization: LocalizationManager
    @EnvironmentObject private var manager: WidgetManager
    @State private var isHovered = false
    @State private var isPressed = false
    @State private var previewSizeOption: WidgetSizeOption
    @State private var previewInstance: WidgetInstance

    init(type: WidgetType, onAdd: @escaping (WidgetSizeOption) -> Void) {
        self.type = type
        self.onAdd = onAdd
        let initialSize = type.availableSizes.first ?? .medium
        _previewSizeOption = State(initialValue: initialSize)
        _previewInstance = State(initialValue: {
            var instance = WidgetInstance(type: type)
            instance.location = .current
            instance.applySizeOption(initialSize)
            if type == .links {
                instance.linkGroups = WidgetLinkGroup.sampleGroups
            }
            return instance
        }())
    }

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
                .padding(.top, infoTopPadding)
                .animation(.spring(response: 0.32, dampingFraction: 0.82), value: previewSizeOption)

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
        RoundedRectangle(cornerRadius: WidgetStyle.cornerRadius, style: .continuous)
            .fill(Color.white.opacity(0.08))
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
            ForEach(allowedSizes) { option in
                let isSelected = previewSizeOption == option
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                        previewSizeOption = option
                        previewInstance.applySizeOption(option)
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

    private var allowedSizes: [WidgetSizeOption] {
        type.availableSizes
    }

    @ViewBuilder
    private var preview: some View {
        switch type {
        case .clock:
            ClockWidgetView(widget: previewInstance)
        case .weather:
            WeatherWidgetView(widget: previewInstance)
        case .pomodoro:
            PomodoroWidgetView(widget: previewInstance)
        case .battery:
            BatteryWidgetView(widget: previewInstance)
        case .system:
            SystemMetricsWidgetView(widget: previewInstance, metrics: SystemMetricsProvider(preview: true))
        case .eisenhower:
            EisenhowerWidgetView(widget: previewInstance)
                .modelContainer(EisenhowerDataStore.previewContainer)
        case .habits:
            HabitsWidgetView(widget: previewInstance)
                .modelContainer(EisenhowerDataStore.previewContainer)
        case .crypto:
            CryptoWidgetView(widget: previewInstance)
        case .links:
            LinksWidgetView(widget: previewInstance)
        case .investment:
            InvestmentCalculatorWidgetView(widget: previewInstance)
        }
    }

    private var previewDisplaySize: CGSize {
        let targetWidth: CGFloat = {
            switch previewSizeOption {
            case .small:
                return 180
            case .medium, .large, .extraLarge:
                return 300
            }
        }()
        let size = previewSizeOption.dimensions
        // Scale purely by width so пропорции совпадают с реальным виджетом.
        let scale = targetWidth / size.width
        return CGSize(width: size.width * scale, height: size.height * scale)
    }

    private var infoTopPadding: CGFloat {
        let isWeather = type == .weather
        switch (isWeather, previewSizeOption) {
        case (true, .small):
            return 28
        case (true, .medium):
            return 42
        case (true, .large):
            return 68
        case (true, .extraLarge):
            return 88
        case (false, .small):
            return 6
        case (false, .medium):
            return 10
        case (false, .large):
            return 14
        case (false, .extraLarge):
            return 18
        }
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
