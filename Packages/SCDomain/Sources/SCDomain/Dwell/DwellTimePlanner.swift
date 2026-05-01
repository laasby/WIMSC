import Foundation
import SCData

/// Answers: "I have N minutes here — what can I actually do?"
public struct DwellActivity: Identifiable {
    public var id: String
    public var name: String
    public var category: DwellCategory
    public var walkingMinutes: Int
    public var isOpen: Bool
    public var closesInMinutes: Int?
    public var distanceMetres: Double
}

public enum DwellCategory: String, CaseIterable {
    case food, coffee, restrooms, shops, lounge, unknown

    public var systemImage: String {
        switch self {
        case .food:      return "fork.knife"
        case .coffee:    return "cup.and.saucer"
        case .restrooms: return "toilet"
        case .shops:     return "bag"
        case .lounge:    return "sofa"
        case .unknown:   return "mappin"
        }
    }
}

public struct DwellPlan {
    public var chargeMinutes: Int
    public var targetSoc: Int
    public var activities: [DwellActivity]
    public var summary: String
}

public enum DwellTimePlanner {

    /// Generate a dwell plan from site amenities + charge time estimate.
    public static func plan(
        supercharger: Supercharger,
        fromSoc: Int = 20,
        toSoc: Int = 80,
        vehicle: UserVehicle? = nil,
        ambientCelsius: Double = 15
    ) -> DwellPlan {
        // 1. Compute base chargeMinutes
        var chargeMinutes: Int
        if let vehicle {
            chargeMinutes = RangeCalculator.estimatedChargeMinutes(
                vehicle: vehicle,
                fromSoc: fromSoc,
                toSoc: toSoc,
                chargerGeneration: supercharger.generation,
                ambientCelsius: ambientCelsius
            )
        } else {
            let generation = supercharger.generation
            let chargerMaxKw = Double(generation.maxKilowatts)
            guard chargerMaxKw > 0 else {
                chargeMinutes = 0
                return buildPlan(chargeMinutes: 0, toSoc: toSoc, supercharger: supercharger)
            }
            let kwhNeeded = 75.0 * Double(toSoc - fromSoc) / 100.0
            chargeMinutes = Int((kwhNeeded / chargerMaxKw * 60).rounded(.up))
        }

        // 2. Cold-soak penalty
        if ambientCelsius < 5 {
            let generation = supercharger.generation
            let nominalKw = Double(generation.maxKilowatts)
            let coldKw = Double(ColdSoakEstimator.estimatedPeakKilowatts(
                ambientCelsius: ambientCelsius,
                generation: generation
            ))
            if coldKw > 0 && nominalKw > 0 {
                let scaledMinutes = Double(chargeMinutes) * (nominalKw / coldKw)
                chargeMinutes = Int(scaledMinutes.rounded(.up))
            }
        }

        return buildPlan(chargeMinutes: chargeMinutes, toSoc: toSoc, supercharger: supercharger)
    }

    /// Converts site amenities to `DwellActivity` list with rough walking times.
    /// Uses 1 min per 80 metres walking estimate.
    public static func activities(from supercharger: Supercharger) -> [DwellActivity] {
        var result: [DwellActivity] = []
        for amenity in supercharger.amenities {
            guard let (name, category, distance) = amenityDetails(amenity) else { continue }
            let walkingMinutes = max(1, Int((distance / 80.0).rounded(.up)))
            result.append(DwellActivity(
                id: amenity.rawValue,
                name: name,
                category: category,
                walkingMinutes: walkingMinutes,
                isOpen: true,
                closesInMinutes: nil,
                distanceMetres: distance
            ))
        }
        return result
    }

    // MARK: - Private helpers

    private static func buildPlan(chargeMinutes: Int, toSoc: Int, supercharger: Supercharger) -> DwellPlan {
        let acts = activities(from: supercharger)
        let summary = buildSummary(chargeMinutes: chargeMinutes, toSoc: toSoc, activities: acts)
        return DwellPlan(
            chargeMinutes: chargeMinutes,
            targetSoc: toSoc,
            activities: acts,
            summary: summary
        )
    }

    private static func buildSummary(chargeMinutes: Int, toSoc: Int, activities: [DwellActivity]) -> String {
        let prefix = "~\(chargeMinutes) min to \(toSoc)%"
        guard !activities.isEmpty else { return prefix }
        let activityList = activities.map { activity -> String in
            let closeStr = activity.closesInMinutes.map { " closes in \($0) min" } ?? ""
            return "\(activity.name) \(activity.walkingMinutes) min walk\(closeStr)"
        }.joined(separator: ", ")
        return "\(prefix) — \(activityList)"
    }

    private static func amenityDetails(_ amenity: Amenity) -> (name: String, category: DwellCategory, distance: Double)? {
        switch amenity {
        case .restrooms:      return ("Restrooms", .restrooms, 50)
        case .food:           return ("Food", .food, 150)
        case .coffee:         return ("Coffee", .coffee, 150)
        case .shops:          return ("Shops", .shops, 200)
        case .lounge:         return ("Lounge", .lounge, 30)
        case .wifi, .coveredParking, .pullThrough:
            return nil
        }
    }
}
