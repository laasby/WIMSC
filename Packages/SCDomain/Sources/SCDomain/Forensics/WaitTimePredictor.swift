import Foundation
import SCData

/// Predicts wait time at a Supercharger based on time-of-day patterns and availability.
public enum WaitTimePredictor {

    /// Predicted wait in minutes at a given site at the current time.
    /// Returns nil if insufficient data.
    public static func predictedWaitMinutes(
        availability: StallAvailability?,
        stallCount: Int,
        visitHistory: [VisitRecord]
    ) -> Int? {
        guard let avail = availability, avail.availableStalls >= 0, avail.totalStalls > 0 else { return nil }
        if avail.availableStalls == 0 { return 10 }
        if Double(avail.availableStalls) > Double(avail.totalStalls) * 0.3 { return 0 }
        return 5
    }

    /// Returns a human-readable wait description.
    public static func waitDescription(
        availability: StallAvailability?,
        stallCount: Int,
        visitHistory: [VisitRecord]
    ) -> String {
        if let avail = availability, avail.availableStalls >= 0, avail.totalStalls > 0 {
            if Double(avail.availableStalls) > Double(avail.totalStalls) * 0.3 {
                return "No wait expected"
            }
            if avail.availableStalls == 0 && avail.totalStalls > 0 {
                return "~10 min wait"
            }
            return "~5 min wait"
        }
        // Fall back to time-of-day heuristic
        let hour = Calendar.current.component(.hour, from: Date())
        let weekday = Calendar.current.component(.weekday, from: Date())
        let isWeekday = (2...6).contains(weekday)
        if isWeekday && ((7...9).contains(hour) || (16...19).contains(hour)) {
            return "Possibly busy"
        }
        return "Usually available"
    }
}
