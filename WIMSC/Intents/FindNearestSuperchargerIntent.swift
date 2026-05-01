import AppIntents
import SwiftData
import CoreLocation
import SCData
import SCDomain

// MARK: - Generation preference for Siri / Shortcuts

enum SuperchargerGenPreference: String, AppEnum {
    case v2, v3, v4, any

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Charger Generation")
    }

    static var caseDisplayRepresentations: [SuperchargerGenPreference: DisplayRepresentation] {
        [
            .v2: "V2 (up to 150 kW)",
            .v3: "V3 (up to 250 kW)",
            .v4: "V4 (up to 325 kW)",
            .any: "Any generation",
        ]
    }
}

// MARK: - Intent

/// AppIntent that finds the nearest open Supercharger and returns a spoken response.
/// Invoke with: "Hey Siri, nearest V4 Supercharger" via the WIMSC app.
struct FindNearestSuperchargerIntent: AppIntent {
    static var title: LocalizedStringResource = "Find Nearest Supercharger"
    static var description = IntentDescription(
        "Finds the nearest open Tesla Supercharger of the specified generation."
    )

    @Parameter(title: "Generation", default: .v4)
    var generation: SuperchargerGenPreference

    @MainActor
    func perform() async throws -> some ProvidesDialog {
        let container = try ModelContainerFactory.makeContainer()
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Supercharger>()
        let all = try context.fetch(descriptor)

        let open = all.filter { $0.status == .open }

        let filtered: [Supercharger]
        switch generation {
        case .v2: filtered = open.filter { $0.generation == .v2 }
        case .v3: filtered = open.filter { $0.generation == .v3 }
        case .v4: filtered = open.filter { $0.generation == .v4 }
        case .any: filtered = open
        }

        // Sort by distance from last-known user location when available.
        let userLocation = CLLocationManager().location
        let sorted: [Supercharger]
        if let loc = userLocation {
            sorted = filtered.sorted {
                CLLocation(latitude: $0.latitude, longitude: $0.longitude).distance(from: loc) <
                CLLocation(latitude: $1.latitude, longitude: $1.longitude).distance(from: loc)
            }
        } else {
            sorted = filtered.sorted { $0.name < $1.name }
        }

        guard let nearest = sorted.first else {
            let genLabel = generation == .any ? "" : "\(generation.rawValue.uppercased()) "
            return .result(dialog: "No open \(genLabel)Superchargers found.")
        }

        let genLabel = generation == .any ? "" : "\(generation.rawValue.uppercased()) "
        let distanceSuffix: String
        if let loc = userLocation {
            let km = CLLocation(latitude: nearest.latitude, longitude: nearest.longitude)
                .distance(from: loc) / 1_000
            distanceSuffix = ", \(Int(km.rounded())) km away"
        } else {
            distanceSuffix = ""
        }

        return .result(
            dialog: "The nearest \(genLabel)Supercharger is \(nearest.name)\(distanceSuffix)."
        )
    }
}
