import Foundation
import SCData

/// Exports a Supercharger as a GPX 1.1 waypoint string.
public enum GPXExporter {

    /// Returns a valid GPX 1.1 XML string containing a single `<wpt>` element.
    public static func gpx(for supercharger: Supercharger) -> String {
        let name = xmlEscape(supercharger.name)
        let addr = [supercharger.streetAddress, supercharger.city, supercharger.country]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        let desc = xmlEscape("\(addr) · \(supercharger.stallCount) stalls · \(supercharger.maxKilowatts) kW")

        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <gpx version="1.1" creator="WIMSC" xmlns="http://www.topografix.com/GPX/1/1">
          <wpt lat="\(supercharger.latitude)" lon="\(supercharger.longitude)">
            <ele>0</ele>
            <name>\(name)</name>
            <desc>\(desc)</desc>
          </wpt>
        </gpx>
        """
    }

    // MARK: - Private

    private static func xmlEscape(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}
