import Foundation
import CoreLocation

/// Formats a distance value into a locale-appropriate human-readable string.
public enum DistanceFormatter {
    /// Returns a localised distance string ("1.2 km", "850 m", "3.4 mi") based on the locale's measurement system.
    /// - Parameters:
    ///   - metres: Distance in metres.
    ///   - locale: The locale to use for unit selection. Defaults to the current locale.
    public static func string(from metres: CLLocationDistance, locale: Locale = .current) -> String {
        let usesMetric = locale.usesMetricSystem
        if usesMetric {
            if metres < 1000 {
                return String(format: "%.0f m", metres)
            } else {
                return String(format: "%.1f km", metres / 1000)
            }
        } else {
            let miles = metres / 1609.344
            if miles < 0.1 {
                let feet = metres * 3.28084
                return String(format: "%.0f ft", feet)
            } else {
                return String(format: "%.1f mi", miles)
            }
        }
    }
}
