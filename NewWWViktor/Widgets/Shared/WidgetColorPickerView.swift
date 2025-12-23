import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct WidgetColorPickerView: View {
    enum Tab: String, CaseIterable {
        case palette
        case selected
    }

    let title: String
    @Binding var isPresented: Bool
    @Binding var selection: String?
    @Binding var intensity: Double
    var backgroundStyle: Binding<BackgroundStyle>? = nil
    var gradientColor1Name: Binding<String?>? = nil
    var gradientColor1Opacity: Binding<Double>? = nil
    var gradientColor2Name: Binding<String?>? = nil
    var gradientColor2Opacity: Binding<Double>? = nil
    var gradientColor1Position: Binding<Double>? = nil
    var gradientColor2Position: Binding<Double>? = nil
    var gradientType: Binding<BackgroundGradientType>? = nil
    var gradientAngle: Binding<Double>? = nil
    let onChange: () -> Void

    @State private var tab: Tab = .palette
    @State private var customColorHex: String = "#FFFFFFFF"
    @State private var activeGradientChannel: Int = 1

    // Более плотная сетка палитры: больше столбцов, меньше отступы.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
    private let palette = PaletteColorOption.defaultPalette

    private var shouldShowColorTabs: Bool {
        guard let style = backgroundStyle?.wrappedValue else { return true }
        return style != .photo
    }

    var body: some View {
        VStack(spacing: 16) {
            header

            if let styleBinding = backgroundStyle {
                Picker("", selection: styleBinding) {
                    Text(localization.text(.appearanceBackgroundPalette)).tag(BackgroundStyle.palette)
                    Text(localization.text(.appearanceBackgroundGradient)).tag(BackgroundStyle.gradient)
                    Text(localization.text(.appearanceBackgroundPhoto)).tag(BackgroundStyle.photo)
                }
                .pickerStyle(.segmented)
            }

            if shouldShowColorTabs {
                Picker("", selection: $tab) {
                    ForEach(Tab.allCases, id: \.self) { tab in
                        Text(title(for: tab))
                    }
                }
                .pickerStyle(.segmented)
            }

            if isGradientMode {
                gradientChannelSwitcher

                if tab == .palette {
                    paletteGrid
                } else {
                    ScrollView {
                        selectedSection
                            .padding(.bottom, 8)
                    }
                    .frame(maxHeight: .infinity)
                }
                intensitySection
                positionSection
                gradientTypeSection
            } else if isPhotoMode {
                photoPlaceholder
            } else {
                if tab == .palette {
                    paletteGrid
                } else {
                    ScrollView {
                        selectedSection
                            .padding(.bottom, 8)
                    }
                    .frame(maxHeight: .infinity)
                }

                intensitySection

                Button {
                    select(nil)
                } label: {
                    HStack {
                        Image(systemName: selection == nil ? "checkmark.circle.fill" : "circle")
                        Text(localization.text(.global))
                            .font(.system(size: 13, weight: .semibold))
                        Spacer()
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .background(Color.white.opacity(0.12))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(width: 360, height: 520)
        // Возвращаем материал, но с жёсткой маской, чтобы фон позади панели не выглядывал.
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .mask(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .onAppear {
            syncCustomColorHex(with: effectiveSelection.wrappedValue)
        }
        .onChange(of: effectiveSelection.wrappedValue) { _, newValue in
            syncCustomColorHex(with: newValue)
        }
        .onChange(of: backgroundStyle?.wrappedValue) { _, _ in
            onChange()
        }
    }

    private var header: some View {
        HStack {
            Button {
                isPresented = false
            } label: {
                Label(localization.text(.back), systemImage: "chevron.left")
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(0.9))

            Spacer()

            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundColor(.white)

            Spacer()

            Button {
                isPresented = false
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.14))
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(0.9))
        }
    }

    private var paletteGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(palette) { option in
                    Button {
                        select(option.assetName)
                    } label: {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(Color(option.assetName))
                            .frame(height: 24)
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(Color.white.opacity(effectiveSelection.wrappedValue == option.assetName ? 1 : 0.2),
                                            lineWidth: effectiveSelection.wrappedValue == option.assetName ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var selectedSection: some View {
        VStack(spacing: 10) {
            ColorWheelControl(color: customColorBinding)
                .frame(height: 220)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

            Button(localization.text(.clear)) {
                select(nil)
            }
            .buttonStyle(.plain)
            .foregroundColor(.white.opacity(effectiveSelection.wrappedValue == nil ? 0.4 : 0.9))
            .disabled(effectiveSelection.wrappedValue == nil)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
    }

    private var intensitySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.text(.opacity))
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.7))

            GradientSlider(
                value: effectiveIntensity,
                gradient: opacityGradient,
                thumbColor: .white,
                height: 10,
                onChange: onChange
            )
        }
    }

    @ViewBuilder
    private var positionSection: some View {
        if let posBinding = activePositionBinding {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Позиция")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("\(Int(posBinding.wrappedValue * 100))%")
                        .font(.footnote)
                        .foregroundColor(.white.opacity(0.6))
                }
                Slider(value: posBinding, in: 0...1, onEditingChanged: { _ in onChange() })
            }
        }
    }

    @ViewBuilder
    private var gradientTypeSection: some View {
        if isGradientMode, let type = gradientType, let angle = gradientAngle {
            VStack(alignment: .leading, spacing: 8) {
                Picker("Тип", selection: type) {
                    ForEach(BackgroundGradientType.allCases) { gType in
                        Text(gType.localizedTitle).tag(gType)
                    }
                }
                .pickerStyle(.menu)

                if type.wrappedValue == .linear || type.wrappedValue == .angular {
                    HStack {
                        Text("Угол")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.white.opacity(0.7))
                        Spacer()
                        Text("\(Int(angle.wrappedValue))°")
                            .font(.footnote)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Slider(value: angle, in: 0...360, step: 1, onEditingChanged: { _ in onChange() })
                }
            }
            .padding(.top, 8)
        }
    }

    private func title(for tab: Tab) -> String {
        switch tab {
        case .palette:
            return localization.text(.paletteTitle)
        case .selected:
            return localization.text(.paletteSelected)
        }
    }

    @EnvironmentObject private var localization: LocalizationManager

    private var opacityGradient: [Color] {
        let base = HexColor.color(from: customColorHex)
        ?? WidgetPaletteColor.color(named: effectiveSelection.wrappedValue, intensity: 1.0, fallback: .white)
        return [base.opacity(0), base.opacity(1)]
    }

    private var customColorBinding: Binding<Color> {
        Binding(
            get: {
                HexColor.color(from: customColorHex)
                ?? WidgetPaletteColor.color(named: effectiveSelection.wrappedValue, intensity: 1.0, fallback: .white)
            },
            set: { newColor in
                guard let hex = HexColor.hexString(from: newColor) else { return }
                customColorHex = hex
                effectiveSelection.wrappedValue = hex
                onChange()
            }
        )
    }

    private func select(_ colorName: String?) {
        if let style = backgroundStyle {
            if style.wrappedValue == .gradient {
                effectiveSelection.wrappedValue = colorName
            } else {
                style.wrappedValue = .palette
                selection = colorName
            }
        } else {
            selection = colorName
        }
        onChange()
        if colorName == nil {
            isPresented = false
        }
    }

    private func syncCustomColorHex(with newValue: String?) {
        guard let newValue else {
            customColorHex = "#FFFFFFFF"
            return
        }

        if let normalized = HexColor.normalizedHex(from: newValue) {
            customColorHex = normalized
        } else if let resolved = HexColor.hexStringForNamedColor(newValue) {
            customColorHex = resolved
        }
    }

    private var isGradientMode: Bool {
        backgroundStyle?.wrappedValue == .gradient &&
        gradientColor1Name != nil && gradientColor2Name != nil &&
        gradientColor1Opacity != nil && gradientColor2Opacity != nil &&
        gradientColor1Position != nil && gradientColor2Position != nil
    }

    private var isPhotoMode: Bool {
        backgroundStyle?.wrappedValue == .photo
    }

    private var effectiveSelection: Binding<String?> {
        if isGradientMode {
            if activeGradientChannel == 1, let g1 = gradientColor1Name {
                return g1
            } else if activeGradientChannel == 2, let g2 = gradientColor2Name {
                return g2
            }
        }
        return $selection
    }

    private var effectiveIntensity: Binding<Double> {
        if isGradientMode {
            if activeGradientChannel == 1, let g1 = gradientColor1Opacity {
                return g1
            } else if activeGradientChannel == 2, let g2 = gradientColor2Opacity {
                return g2
            }
        }
        return $intensity
    }

    private var activePositionBinding: Binding<Double>? {
        guard isGradientMode else { return nil }
        if activeGradientChannel == 1 {
            return gradientColor1Position
        } else {
            return gradientColor2Position
        }
    }

    private var gradientChannelSwitcher: some View {
        HStack(spacing: 8) {
            gradientChip(title: "Цвет 1", isActive: activeGradientChannel == 1) { activeGradientChannel = 1 }
            gradientChip(title: "Цвет 2", isActive: activeGradientChannel == 2) { activeGradientChannel = 2 }
        }
        .padding(.vertical, 4)
    }

    private func gradientChip(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(isActive ? .black : .white.opacity(0.8))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(isActive ? Color.white : Color.white.opacity(0.16))
                )
        }
        .buttonStyle(.plain)
    }

    private var photoPlaceholder: some View {
        VStack(spacing: 12) {
            Text(localization.text(.appearanceBackgroundPhoto))
                .font(.headline)
            Text(localization.text(.appearanceBackgroundPhoto))
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
            Button {
                backgroundStyle?.wrappedValue = .photo
                onChange()
                isPresented = false
            } label: {
                Text(localization.text(.appearanceBackgroundPhoto))
                    .font(.system(size: 14, weight: .semibold))
                    .padding(.vertical, 10)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .frame(maxHeight: .infinity)
    }
}

// Общий стилизованный слайдер для hue/opacity
private struct GradientSlider: View {
    @Binding var value: Double
    var gradient: [Color]
    var thumbColor: Color
    var height: CGFloat = 10
    var onChange: (() -> Void)? = nil

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: height / 2, style: .continuous)
                    .fill(LinearGradient(colors: gradient, startPoint: .leading, endPoint: .trailing))
                    .frame(height: height)

                let x = CGFloat(value.clamped) * width
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(Circle().fill(thumbColor))
                    .frame(width: height + 8, height: height + 8)
                    .position(x: x, y: height / 2)
            }
            .frame(height: height + 8)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { updateValue(at: $0.location.x, width: width) }
                    .onEnded { updateValue(at: $0.location.x, width: width) }
            )
        }
        .frame(height: height + 10)
    }

    private func updateValue(at x: CGFloat, width: CGFloat) {
        let newValue = Double(min(max(x / width, 0), 1))
        value = newValue
        onChange?()
    }
}

private extension Double {
    var clamped: Double { min(max(self, 0), 1) }
}

private struct PaletteColorOption: Identifiable {
    let id = UUID()
    let assetName: String

    static let defaultPalette: [PaletteColorOption] = [
        "PaletteYellow", "PaletteYellow2", "PaletteYellow3", "PaletteYellow4",
        "PaletteGreen", "PaletteGreen2", "PaletteGreen3", "PaletteGreen4",
        "PaletteCyan", "PaletteCyan2", "PaletteCyan3", "PaletteCyan4",
        "PaletteTeal", "PaletteTeal2", "PaletteTeal3", "PaletteTeal4",
        "PalettePink", "PalettePink2", "PalettePink3", "PalettePink4",
        "PaletteRed", "PaletteRed2", "PaletteRed3", "PaletteRed4",
        "PaletteGrey", "PaletteGrey2", "PaletteGrey3", "PaletteGrey4",
        "PaletteBlack", "PaletteWhite", "AppYellow"
    ].map { PaletteColorOption(assetName: $0) }
}

private struct ColorWheelControl: View {
    @Binding var color: Color
    @State private var hsb = HSBColor(hue: 0, saturation: 1, brightness: 1, alpha: 1)

    private static let hueGradient: [Color] = [
        .red, .yellow, .green, .cyan, .blue, .purple, .red
    ]

    var body: some View {
        VStack(spacing: 12) {
            // Поле S/B: по горизонтали насыщенность, по вертикали яркость.
            GeometryReader { proxy in
                let size = min(proxy.size.width, proxy.size.height)
                let sat = CGFloat(hsb.saturation)
                let bri = CGFloat(hsb.brightness)

                ZStack {
                    // База: слева белый, справа выбранный цвет по текущему hue.
                    LinearGradient(colors: [.white, hueColor], startPoint: .leading, endPoint: .trailing)
                        .frame(width: size, height: size)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        // Оверлей: сверху прозрачный, снизу чёрный — чтобы получить все яркости.
                        .overlay(
                            LinearGradient(colors: [.clear, .black],
                               startPoint: .top,
                               endPoint: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        )

                    // Маркер выбора внутри квадрата
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(color))
                        .shadow(color: .black.opacity(0.4), radius: 2)
                        .frame(width: 16, height: 16)
                        .position(x: sat * size, y: (1 - bri) * size)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateSaturationBrightness(at: value.location, size: size)
                        }
                        .onEnded { value in
                            updateSaturationBrightness(at: value.location, size: size)
                        }
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .aspectRatio(1, contentMode: .fit)

            // Hue-бар
            GradientSlider(
                value: Binding(
                    get: { hsb.hue },
                    set: { newHue in
                        hsb.hue = newHue
                        color = hsb.color
                    }
                ),
                gradient: Self.hueGradient,
                thumbColor: hueColor
            )
        }
        .onAppear {
            hsb = HSBColor(color: color)
        }
        .onChange(of: color) { _, newValue in
            hsb = HSBColor(color: newValue)
        }
    }

    private var hueColor: Color {
        Color(hue: hsb.hue, saturation: 1, brightness: 1)
    }

    private func updateSaturationBrightness(at point: CGPoint, size: CGFloat) {
        let sat = min(max(Double(point.x / size), 0), 1)
        let bri = min(max(Double(1 - point.y / size), 0), 1)
        hsb = HSBColor(hue: hsb.hue, saturation: sat, brightness: bri, alpha: 1)
        color = hsb.color
    }

    private func updateHue(at x: CGFloat, width: CGFloat) {
        let hue = min(max(Double(x / width), 0), 1)
        hsb.hue = hue
        color = hsb.color
    }
}

private struct HSBColor {
    var hue: Double
    var saturation: Double
    var brightness: Double
    var alpha: Double

    var color: Color {
        Color(hue: hue, saturation: saturation, brightness: brightness, opacity: alpha)
    }

    init(hue: Double, saturation: Double, brightness: Double, alpha: Double) {
        self.hue = hue
        self.saturation = saturation
        self.brightness = brightness
        self.alpha = alpha
    }

    init(color: Color) {
#if os(macOS)
        let native = NSColor(color).usingColorSpace(.sRGB)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        native?.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
#else
        let native = UIColor(color)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0
        native.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
#endif
        self.hue = Double(hue)
        self.saturation = Double(saturation)
        self.brightness = Double(brightness)
        self.alpha = Double(alpha)
    }
}
