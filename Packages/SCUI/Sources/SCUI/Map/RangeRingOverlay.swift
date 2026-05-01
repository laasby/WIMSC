import SwiftUI
import MapKit
import SCData
import SCDomain

/// MapContent that renders a range ring polygon and Supercharger classification markers.
public struct RangeRingOverlay: MapContent {
    public let calculator: RangeRingCalculator

    public init(calculator: RangeRingCalculator) {
        self.calculator = calculator
    }

    @MapContentBuilder
    public var body: some MapContent {
        if let polygon = calculator.polygon {
            MapPolygon(polygon)
                .foregroundStyle(Color.blue.opacity(0.12))
                .stroke(.blue.opacity(0.5), lineWidth: 2)
        }

        ForEach(calculator.justOutsideSuperchargers, id: \.id) { site in
            Marker(
                site.name,
                systemImage: "bolt.slash",
                coordinate: CLLocationCoordinate2D(latitude: site.latitude, longitude: site.longitude)
            )
            .tint(.orange)
        }
    }
}
