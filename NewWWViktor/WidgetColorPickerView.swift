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
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .frame(width: 340, height: 460)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12))
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.35), radius: 25, x: 0, y: 20)
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
        VStack(spacing: 14) {
            if let selection {
                ColorChip(colorName: selection, intensity: intensity)
            } else {
                Text(localization.text(.noColorSelected))
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 4)
            }

            ColorWheelControl(color: customColorBinding)
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 8)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

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
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
            .onChange(of: intensity) { _, _ in
                onChange()
            }
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(colors: [
                            WidgetPaletteColor.color(named: selection, intensity: 0.0, fallback: .black),
                            WidgetPaletteColor.color(named: selection, intensity: 1.0, fallback: .primary)
                        ], startPoint: .leading, endPoint: .trailing)
                    )
                    .opacity(0.35)
            )
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
    @State private var hsb = HSBColor(hue: 0, saturation: 0, brightness: 1, alpha: 1)

    private static let hueGradient: [Color] = [
        .red, .yellow, .green, .cyan, .blue, .purple, .red
    ]

    var body: some View {
        GeometryReader { proxy in
            let diameter = min(proxy.size.width, proxy.size.height)
            let radius = diameter / 2
            let center = CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2)
            let indicator = indicatorPosition(center: center, radius: radius)

            ZStack {
                Circle()
                    .fill(
                        AngularGradient(gradient: Gradient(colors: Self.hueGradient),
                                        center: .center)
                    )
                    .overlay(
                        Circle()
                            .fill(
                                RadialGradient(gradient: Gradient(colors: [.white, .clear]),
                                               center: .center,
                                               startRadius: 0,
                                               endRadius: radius)
                            )
                    )
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                updateColor(at: value.location, center: center, radius: radius)
                            }
                            .onEnded { value in
                                updateColor(at: value.location, center: center, radius: radius)
                            }
                    )

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(Circle().fill(color))
                    .shadow(color: .black.opacity(0.4), radius: 2)
                    .frame(width: 18, height: 18)
                    .position(indicator)
            }
            .onAppear {
                hsb = HSBColor(color: color)
            }
            .onChange(of: color) { _, newValue in
                hsb = HSBColor(color: newValue)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func indicatorPosition(center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = 2 * .pi * CGFloat(hsb.hue)
        let distance = CGFloat(hsb.saturation) * radius
        return CGPoint(
            x: center.x + distance * cos(angle),
            y: center.y + distance * sin(angle)
        )
    }

    private func updateColor(at point: CGPoint, center: CGPoint, radius: CGFloat) {
        let dx = Double(point.x - center.x)
        let dy = Double(point.y - center.y)
        var hue = atan2(dy, dx) / (2 * .pi)
        if hue < 0 { hue += 1 }
        let distance = min(max(Double(hypot(dx, dy)), 0), Double(radius))
        let saturation = distance / Double(radius)

        hsb = HSBColor(hue: hue, saturation: saturation, brightness: hsb.brightness, alpha: 1)
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
