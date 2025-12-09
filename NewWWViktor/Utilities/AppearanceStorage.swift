import Foundation
#if os(macOS)
import AppKit
#endif

struct AppearanceStorage {
    struct Colors {
        var primaryName: String?
        var secondaryName: String?
        var primaryIntensity: Double
        var secondaryIntensity: Double
    }

    struct Background {
        var style: BackgroundStyle
        var colorName: String?
        var intensity: Double
        var gradientColor1Name: String?
        var gradientColor2Name: String?
        var gradientColor1Opacity: Double
        var gradientColor2Opacity: Double
        var gradientColor1Position: Double
        var gradientColor2Position: Double
        var gradientType: BackgroundGradientType
        var gradientAngle: Double
        var hideBackground: Bool
    }

    static let colorDidChange = Notification.Name("appearance.colors.changed")
    static let backgroundDidChange = Notification.Name("appearance.background.changed")

    private static let primaryColorKey = "appearance.primaryColorName"
    private static let primaryIntensityKey = "appearance.primaryIntensity"
    private static let secondaryColorKey = "appearance.secondaryColorName"
    private static let secondaryIntensityKey = "appearance.secondaryIntensity"
    private static let backgroundStyleKey = "appearance.backgroundStyle"
    private static let backgroundColorKey = "appearance.backgroundColorName"
    private static let backgroundIntensityKey = "appearance.backgroundColorIntensity"
    private static let gradientColor1Key = "appearance.gradient.color1"
    private static let gradientColor2Key = "appearance.gradient.color2"
    private static let gradientColor1OpacityKey = "appearance.gradient.color1.opacity"
    private static let gradientColor2OpacityKey = "appearance.gradient.color2.opacity"
    private static let gradientColor1PositionKey = "appearance.gradient.color1.position"
    private static let gradientColor2PositionKey = "appearance.gradient.color2.position"
    private static let gradientTypeKey = "appearance.gradient.type"
    private static let gradientAngleKey = "appearance.gradient.angle"
    private static let backgroundHideKey = "appearance.background.hide"
    private static let backgroundImageBookmarkKey = "appearance.backgroundImageBookmark"
    private static let backgroundImagePathKey = "appearance.backgroundImagePath"

    static func loadColors(defaults: UserDefaults = .standard) -> Colors {
        Colors(
            primaryName: defaults.string(forKey: primaryColorKey),
            secondaryName: defaults.string(forKey: secondaryColorKey),
            primaryIntensity: defaults.object(forKey: primaryIntensityKey) as? Double ?? 1.0,
            secondaryIntensity: defaults.object(forKey: secondaryIntensityKey) as? Double ?? 1.0
        )
    }

    static func saveColors(_ colors: Colors, defaults: UserDefaults = .standard) {
        defaults.set(colors.primaryName, forKey: primaryColorKey)
        defaults.set(colors.primaryIntensity, forKey: primaryIntensityKey)
        defaults.set(colors.secondaryName, forKey: secondaryColorKey)
        defaults.set(colors.secondaryIntensity, forKey: secondaryIntensityKey)
        NotificationCenter.default.post(name: colorDidChange, object: nil)
    }

    static func loadBackground(defaults: UserDefaults = .standard) -> Background {
        let storedStyle = defaults.string(forKey: backgroundStyleKey) ?? BackgroundStyle.photo.rawValue
        let style = BackgroundStyle(rawValue: storedStyle) ?? .photo
        let typeRaw = defaults.string(forKey: gradientTypeKey) ?? BackgroundGradientType.linear.rawValue
        let gradientType = BackgroundGradientType(rawValue: typeRaw) ?? .linear

        return Background(
            style: style,
            colorName: defaults.string(forKey: backgroundColorKey),
            intensity: defaults.object(forKey: backgroundIntensityKey) as? Double ?? 1.0,
            gradientColor1Name: defaults.string(forKey: gradientColor1Key),
            gradientColor2Name: defaults.string(forKey: gradientColor2Key),
            gradientColor1Opacity: defaults.object(forKey: gradientColor1OpacityKey) as? Double ?? 1.0,
            gradientColor2Opacity: defaults.object(forKey: gradientColor2OpacityKey) as? Double ?? 1.0,
            gradientColor1Position: defaults.object(forKey: gradientColor1PositionKey) as? Double ?? 0.0,
            gradientColor2Position: defaults.object(forKey: gradientColor2PositionKey) as? Double ?? 1.0,
            gradientType: gradientType,
            gradientAngle: defaults.object(forKey: gradientAngleKey) as? Double ?? 0.0,
            hideBackground: defaults.object(forKey: backgroundHideKey) as? Bool ?? false
        )
    }

    static func saveBackground(_ background: Background, defaults: UserDefaults = .standard) {
        defaults.set(background.style.rawValue, forKey: backgroundStyleKey)
        defaults.set(background.colorName, forKey: backgroundColorKey)
        defaults.set(background.intensity, forKey: backgroundIntensityKey)
        defaults.set(background.gradientColor1Name, forKey: gradientColor1Key)
        defaults.set(background.gradientColor2Name, forKey: gradientColor2Key)
        defaults.set(background.gradientColor1Opacity, forKey: gradientColor1OpacityKey)
        defaults.set(background.gradientColor2Opacity, forKey: gradientColor2OpacityKey)
        defaults.set(background.gradientColor1Position, forKey: gradientColor1PositionKey)
        defaults.set(background.gradientColor2Position, forKey: gradientColor2PositionKey)
        defaults.set(background.gradientType.rawValue, forKey: gradientTypeKey)
        defaults.set(background.gradientAngle, forKey: gradientAngleKey)
        defaults.set(background.hideBackground, forKey: backgroundHideKey)
        NotificationCenter.default.post(name: backgroundDidChange, object: nil)
    }

    static func reset(defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: primaryColorKey)
        defaults.removeObject(forKey: primaryIntensityKey)
        defaults.removeObject(forKey: secondaryColorKey)
        defaults.removeObject(forKey: secondaryIntensityKey)
        defaults.removeObject(forKey: backgroundStyleKey)
        defaults.removeObject(forKey: backgroundColorKey)
        defaults.removeObject(forKey: backgroundIntensityKey)
        defaults.removeObject(forKey: gradientColor1Key)
        defaults.removeObject(forKey: gradientColor2Key)
        defaults.removeObject(forKey: gradientColor1OpacityKey)
        defaults.removeObject(forKey: gradientColor2OpacityKey)
        defaults.removeObject(forKey: gradientColor1PositionKey)
        defaults.removeObject(forKey: gradientColor2PositionKey)
        defaults.removeObject(forKey: gradientTypeKey)
        defaults.removeObject(forKey: gradientAngleKey)
        defaults.removeObject(forKey: backgroundHideKey)
        defaults.removeObject(forKey: backgroundImageBookmarkKey)
        defaults.removeObject(forKey: backgroundImagePathKey)
        NotificationCenter.default.post(name: colorDidChange, object: nil)
        NotificationCenter.default.post(name: backgroundDidChange, object: nil)
    }

    #if os(macOS)
    static func loadBackgroundImageURL(defaults: UserDefaults = .standard) -> URL? {
        if let storedPath = defaults.string(forKey: backgroundImagePathKey) {
            let url = URL(fileURLWithPath: storedPath)
            if FileManager.default.fileExists(atPath: url.path) {
                return url
            }
        }

        guard let data = defaults.data(forKey: backgroundImageBookmarkKey) else { return nil }
        var stale = false
        if let url = try? URL(resolvingBookmarkData: data,
                              options: [.withSecurityScope],
                              relativeTo: nil,
                              bookmarkDataIsStale: &stale) {
            if stale, let refreshed = try? url.bookmarkData(options: .withSecurityScope,
                                                            includingResourceValuesForKeys: nil,
                                                            relativeTo: nil) {
                defaults.set(refreshed, forKey: backgroundImageBookmarkKey)
            }
            return url
        }
        return nil
    }

    static func saveBackgroundImage(url: URL, defaults: UserDefaults = .standard) -> URL? {
        guard let copied = copyToAppSupport(url: url) else { return nil }
        defaults.set(copied.path, forKey: backgroundImagePathKey)
        if let bookmark = try? copied.bookmarkData(options: .withSecurityScope,
                                                   includingResourceValuesForKeys: nil,
                                                   relativeTo: nil) {
            defaults.set(bookmark, forKey: backgroundImageBookmarkKey)
        }
        NotificationCenter.default.post(name: backgroundDidChange, object: nil)
        return copied
    }

    private static func copyToAppSupport(url: URL) -> URL? {
        do {
            let fm = FileManager.default
            let base = try fm.url(for: .applicationSupportDirectory,
                                  in: .userDomainMask,
                                  appropriateFor: nil,
                                  create: true)
            let dir = base.appendingPathComponent("NewWWViktorBackgrounds", isDirectory: true)
            if !fm.fileExists(atPath: dir.path) {
                try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            }
            let dest = dir.appendingPathComponent(url.lastPathComponent)
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: url, to: dest)
            return dest
        } catch {
            print("Failed to copy background image: \(error)")
            return nil
        }
    }
    #endif
}
