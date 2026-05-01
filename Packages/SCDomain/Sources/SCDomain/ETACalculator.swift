import Foundation

/// Estimates driving time to a destination.
public struct ETACalculator {
    /// Estimates driving time in minutes using a simple average-speed heuristic.
    /// For production navigation, replace with an MKDirections call in SCUI.
    /// - Parameters:
    ///   - distanceMetres: The route distance in metres.
    ///   - averageSpeedKmh: Assumed average speed in km/h. Defaults to 80 km/h.
    /// - Returns: Estimated travel time in minutes, rounded up.
    public static func estimate(distanceMetres: Double, averageSpeedKmh: Double = 80) -> Int {
        guard averageSpeedKmh > 0 else { return 0 }
        let hours = (distanceMetres / 1000) / averageSpeedKmh
        let minutes = hours * 60
        return Int(minutes.rounded(.up))
    }
}
