import SwiftUI
import SCData

/// Colorblind-safe color scheme and iconography for charger-generation pins.
public enum GenerationPinStyle {

    /// Colorblind-safe palette — avoids red/green reliance.
    ///   V2 → blue  (#0077BB)
    ///   V3 → orange (#EE7733)
    ///   V4 → purple (#AA3377)
    ///   unknown → gray
    public static func color(for generation: ChargerGeneration) -> Color {
        switch generation {
        case .v2:      return Color(red: 0/255,   green: 119/255, blue: 187/255)
        case .v3:      return Color(red: 238/255, green: 119/255, blue: 51/255)
        case .v4:      return Color(red: 170/255, green: 51/255,  blue: 119/255)
        case .unknown: return .gray
        }
    }

    /// Resolved pin tint — construction sites always appear gray.
    public static func pinColor(for generation: ChargerGeneration, status: SiteStatus) -> Color {
        status == .open ? color(for: generation) : .gray
    }

    /// SF Symbol name for the pin marker.
    public static func systemImage(for generation: ChargerGeneration) -> String {
        switch generation {
        case .v4:      return "bolt.fill"
        case .v3:      return "bolt"
        case .v2:      return "bolt.fill"
        case .unknown: return "questionmark.circle"
        }
    }

    /// Resolved pin icon — construction sites show a hammer.
    public static func pinSystemImage(for generation: ChargerGeneration, status: SiteStatus) -> String {
        status == .open ? systemImage(for: generation) : "hammer.fill"
    }

    /// Short display label, e.g. "V4".
    public static func label(for generation: ChargerGeneration) -> String {
        switch generation {
        case .v2:      return "V2"
        case .v3:      return "V3"
        case .v4:      return "V4"
        case .unknown: return "?"
        }
    }
}
