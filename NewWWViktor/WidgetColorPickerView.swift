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
    let onChange: () -> Void

    @State private var tab: Tab = .palette
    @State private var customColorHex: String = "#FFFFFFFF"

    // Более плотная сетка палитры: больше столбцов, меньше отступы.
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)
    private let palette = PaletteColorOption.defaultPalette

    var body: some View {
        VStack(spacing: 16) {
            header

            Picker("", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(title(for: tab))
                }
            }
            .pickerStyle(.segmented)

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
             //   .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .frame(width: 360, height: 520)
        // Возвращаем материал, но с жёсткой маской, чтобы фон позади панели не выглядывал.
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 36, style: .continuous))
        .mask(RoundedRectangle(cornerRadius: 36, style: .continuous))
        .onAppear {
            syncCustomColorHex(with: selection)
        }
        .onChange(of: selection) { _, newValue in
            syncCustomColorHex(with: newValue)
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
                                    .stroke(Color.white.opacity(selection == option.assetName ? 1 : 0.2),
                                            lineWidth: selection == option.assetName ? 2 : 1)
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
            .foregroundColor(.white.opacity(selection == nil ? 0.4 : 0.9))
            .disabled(selection == nil)
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

            Slider(value: $intensity, in: 0...1.0) {
                Text(localization.text(.opacity))
            }
            .accentColor(.white)
            .labelsHidden()
            .onChange(of: intensity) { _, _ in
                onChange()
            }
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

    private var customColorBinding: Binding<Color> {
        Binding(
            get: {
                HexColor.color(from: customColorHex)
                ?? WidgetPaletteColor.color(named: selection, intensity: 1.0, fallback: .white)
            },
            set: { newColor in
                guard let hex = HexColor.hexString(from: newColor) else { return }
                customColorHex = hex
                selection = hex
                onChange()
            }
        )
    }

    private func select(_ colorName: String?) {
        selection = colorName
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
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    updateSaturationBrightness(at: value.location, size: size)
                                }
                                .onEnded { value in
                                    updateSaturationBrightness(at: value.location, size: size)
                                }
                        )

                    // Маркер выбора внутри квадрата
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(color))
                        .shadow(color: .black.opacity(0.4), radius: 2)
                        .frame(width: 16, height: 16)
                        .position(x: sat * size, y: (1 - bri) * size)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .aspectRatio(1, contentMode: .fit)

            // Hue-бар
            GeometryReader { proxy in
                let width = proxy.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: Self.hueGradient, startPoint: .leading, endPoint: .trailing))

                    let x = CGFloat(hsb.hue) * width
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(hueColor))
                        .frame(width: 18, height: 18)
                        .position(x: x, y: proxy.size.height / 2)
                }
                .frame(height: 18)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            updateHue(at: value.location.x, width: width)
                        }
                        .onEnded { value in
                            updateHue(at: value.location.x, width: width)
                        }
                )
            }
            .frame(height: 22)
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
