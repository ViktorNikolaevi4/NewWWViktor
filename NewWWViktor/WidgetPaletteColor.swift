import SwiftUI
#if os(macOS)
import AppKit
#else
import UIKit
#endif

enum WidgetPaletteColor {
    static func color(named name: String?, intensity: Double, fallback: Color) -> Color {
        guard let name, !name.isEmpty else {
            return fallback
        }

        #if os(macOS)
        if let nsColor = NSColor(named: NSColor.Name(name)) {
            return Color(nsColor: adjust(nsColor, intensity: intensity))
        } else if let hexColor = HexColor.platformColor(fromHex: name) {
            return Color(nsColor: adjust(hexColor, intensity: intensity))
        }
        #else
        if let uiColor = UIColor(named: name) {
            return Color(uiColor: adjust(uiColor, intensity: intensity))
        } else if let hexColor = HexColor.platformColor(fromHex: name) {
            return Color(uiColor: adjust(hexColor, intensity: intensity))
        }
        #endif
        return fallback
    }

    #if os(macOS)
    private static func adjust(_ color: NSColor, intensity: Double) -> NSColor {
        guard let rgb = color.usingColorSpace(.sRGB) else { return color }
        let clamp = CGFloat(intensity.clamped(to: 0...1))
        return NSColor(srgbRed: rgb.redComponent,
                       green: rgb.greenComponent,
                       blue: rgb.blueComponent,
                       alpha: clamp)
    }
    #else
    private static func adjust(_ color: UIColor, intensity: Double) -> UIColor {
        guard let rgb = color.cgColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil),
              let components = rgb.components else { return color }
        let clamp = CGFloat(intensity.clamped(to: 0...1))
        let r = components[0]
        let g = components[1]
        let b = components[2]
        return UIColor(red: r, green: g, blue: b, alpha: clamp)
    }
    #endif
}

private extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
