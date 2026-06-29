import SwiftUI

/// DialWave brand color palette and hex color initializer.
///
/// All colors are defined as static properties for consistent usage across the UI.
/// Adaptive colors automatically switch between light and dark appearance.
extension Color {

    // MARK: - Brand Colors

    /// Primary brand purple (#6C63FF).
    static let dialwavePrimary = Color(hex: "6C63FF")

    /// Success / active call green (#00D4AA).
    static let dialwaveGreen = Color(hex: "00D4AA")

    /// Destructive / reject / error red (#FF4757).
    static let dialwaveRed = Color(hex: "FF4757")

    /// Warning / connecting orange (#FF6B35).
    static let dialwaveOrange = Color(hex: "FF6B35")

    /// Adaptive background color for cards and containers.
    static let dialwaveBackground = Color(nsColor: .windowBackgroundColor)

    /// Adaptive secondary text and icon color.
    static let dialwaveSecondary = Color(nsColor: .secondaryLabelColor)

    // MARK: - Hex Initializer

    /// Creates a `Color` from a hexadecimal string.
    ///
    /// Supports 6-character (`"FF0000"`) and 8-character with alpha (`"FF0000FF"`) formats.
    /// The leading `#` is stripped if present.
    ///
    /// - Parameter hex: A hex color string.
    init(hex: String) {
        let sanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let red: Double
        let green: Double
        let blue: Double
        let alpha: Double

        if sanitized.count == 8 {
            red = Double((rgb >> 24) & 0xFF) / 255.0
            green = Double((rgb >> 16) & 0xFF) / 255.0
            blue = Double((rgb >> 8) & 0xFF) / 255.0
            alpha = Double(rgb & 0xFF) / 255.0
        } else {
            red = Double((rgb >> 16) & 0xFF) / 255.0
            green = Double((rgb >> 8) & 0xFF) / 255.0
            blue = Double(rgb & 0xFF) / 255.0
            alpha = 1.0
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
    }
}
