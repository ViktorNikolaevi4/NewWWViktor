import SwiftUI
#if os(macOS)
import AppKit
typealias NativeColor = NSColor
#else
import UIKit
typealias NativeColor = UIColor
#endif

enum HexColor {
    /// Converts a hexadecimal string (e.g. #RRGGBB or #RRGGBBAA) into a SwiftUI Color.
    static func color(from string: String) -> Color? {
        if let platformColor = platformColor(fromHex: string) {
            return Color(nativeColor: platformColor)
        }
        return nil
    }

    /// Returns a normalized hex string (#RRGGBBAA) if the input describes a valid color.
    static func normalizedHex(from string: String) -> String? {
        guard let components = rgbaValues(fromHex: string) else { return nil }
        return hexString(from: components)
    }

    /// Attempts to resolve a named color stored in the asset catalog and returns its hex representation.
    static func hexStringForNamedColor(_ name: String) -> String? {
        guard let nativeColor = platformColor(named: name) else { return nil }
        return hexString(from: rgbaComponents(from: nativeColor))
    }

    /// Builds a hex string (#RRGGBBAA) from any SwiftUI Color.
    static func hexString(from color: Color) -> String? {
        let native = NativeColor(color)
        return hexString(from: rgbaComponents(from: native))
    }

    /// Creates a platform color (NSColor/UIColor) from a hex string.
    static func platformColor(fromHex string: String) -> NativeColor? {
        guard let components = rgbaValues(fromHex: string) else { return nil }
#if os(macOS)
        return NativeColor(srgbRed: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
#else
        return NativeColor(red: components.red, green: components.green, blue: components.blue, alpha: components.alpha)
#endif
    }

    /// Resolves a platform color stored in the asset catalog.
    static func platformColor(named name: String) -> NativeColor? {
#if os(macOS)
        return NativeColor(named: NativeColor.Name(name))
#else
        return NativeColor(named: name)
#endif
    }

    private static func rgbaValues(fromHex string: String) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
        var hex = string.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if hex.hasPrefix("#") {
            hex.removeFirst()
        }

        guard hex.count == 6 || hex.count == 8 else { return nil }
        if hex.count == 6 {
            hex.append("FF")
        }

        guard let value = UInt64(hex, radix: 16) else { return nil }

        let red = CGFloat((value & 0xFF000000) >> 24) / 255
        let green = CGFloat((value & 0x00FF0000) >> 16) / 255
        let blue = CGFloat((value & 0x0000FF00) >> 8) / 255
        let alpha = CGFloat(value & 0x000000FF) / 255

        return (red, green, blue, alpha)
    }

    private static func rgbaComponents(from color: NativeColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
#if os(macOS)
        guard let rgb = color.usingColorSpace(.sRGB) else { return nil }
        return (rgb.redComponent, rgb.greenComponent, rgb.blueComponent, rgb.alphaComponent)
#else
        guard let cgColor = color.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(),
                                                    intent: .defaultIntent,
                                                    options: nil),
              let components = cgColor.components else { return nil }
        let red = components[0]
        let green = components[1]
        let blue = components[2]
        let alpha = components.count > 3 ? components[3] : 1
        return (red, green, blue, alpha)
#endif
    }

    private static func hexString(from components: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)?) -> String? {
        guard let components else { return nil }
        let r = Int(round(components.red * 255))
        let g = Int(round(components.green * 255))
        let b = Int(round(components.blue * 255))
        let a = Int(round(components.alpha * 255))
        return String(format: "#%02X%02X%02X%02X", r, g, b, a)
    }
}

private extension Color {
    init(nativeColor: NativeColor) {
#if os(macOS)
        self.init(nsColor: nativeColor)
#else
        self.init(uiColor: nativeColor)
#endif
    }
}
