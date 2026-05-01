import Foundation

/// Locale-aware formatters used across the app.
public enum Formatters {

    // MARK: - Distance

    /// Returns a localised distance string.
    /// Uses metric (km/m) for most locales, miles for en_US and en_GB.
    public static func distance(_ metres: Double, locale: Locale = .current) -> String {
        let usesImperial = locale.measurementSystem == .us
        if usesImperial {
            let miles = metres / 1609.344
            if miles < 0.1 {
                return String(format: "%.0f ft", metres * 3.28084)
            }
            return String(format: "%.1f mi", miles)
        } else {
            if metres < 1000 {
                return String(format: "%.0f m", metres)
            }
            return String(format: "%.1f km", metres / 1000)
        }
    }

    // MARK: - Currency

    /// Returns a localised price string with currency symbol.
    /// e.g. "2,49 kr" for NOK, "$0.35" for USD
    public static func price(_ amount: Double, currencyCode: String, locale: Locale = .current) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = locale
        return formatter.string(from: NSNumber(value: amount)) ?? "\(amount) \(currencyCode)"
    }

    // MARK: - Relative date

    /// Returns a relative date string like "2 days ago", "just now".
    public static func relativeDate(_ date: Date, relativeTo reference: Date = .now, locale: Locale = .current) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: reference)
    }

    // MARK: - Short date

    /// Returns a short date string like "May 1, 2025".
    public static func shortDate(_ date: Date?, locale: Locale = .current) -> String {
        guard let date else { return NSLocalizedString("date.unknown", bundle: .main, comment: "") }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = locale
        return formatter.string(from: date)
    }

    // MARK: - Temperature

    /// Returns a localised temperature string: "−3 °C" or "27 °F"
    public static func temperature(_ celsius: Double, locale: Locale = .current) -> String {
        let usesF = locale.measurementSystem == .us
        if usesF {
            let f = celsius * 9/5 + 32
            return String(format: "%.0f °F", f)
        }
        return String(format: "%.0f °C", celsius)
    }

    // MARK: - Power

    /// Returns a formatted kilowatt string: "250 kW"
    public static func kilowatts(_ kw: Int) -> String {
        "\(kw) kW"
    }
}
