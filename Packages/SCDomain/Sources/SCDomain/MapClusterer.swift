import Foundation
import CoreLocation
import MapKit
import SCData

// MARK: - Cluster item

/// A single displayable item on the map — either one Supercharger or a cluster of several.
public enum MapClusterItem: Identifiable {
    case single(SuperchargerAnnotation)
    case cluster(id: String, count: Int, coordinate: CLLocationCoordinate2D, generation: ChargerGeneration)

    public var id: String {
        switch self {
        case .single(let a):           return a.supercharger.id
        case .cluster(let id, _, _, _): return id
        }
    }

    public var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let a):                return a.coordinate
        case .cluster(_, _, let coord, _): return coord
        }
    }
}

// MARK: - Clusterer

/// Groups map annotations into clusters so the map never shows more than `targetMax` items.
/// When the viewport is small enough that all sites fit under `targetMax`, each is shown individually.
public enum MapClusterer {

    /// - Parameters:
    ///   - annotations: All annotations in the current viewport.
    ///   - region: The current map region (used to compute cell sizes).
    ///   - targetMax: Aim for at most this many visible items (default 35).
    public static func cluster(
        annotations: [SuperchargerAnnotation],
        region: MKCoordinateRegion,
        targetMax: Int = 35
    ) -> [MapClusterItem] {
        guard !annotations.isEmpty else { return [] }

        // If we already have fewer than targetMax, show everything individually.
        if annotations.count <= targetMax {
            return annotations.map { .single($0) }
        }

        let latSpan = region.span.latitudeDelta
        let lngSpan = region.span.longitudeDelta

        // Compute grid dimensions so each cell holds ~(count/targetMax) sites on average.
        // Use sqrt to get a roughly square grid.
        let gridN = max(2, Int(ceil(sqrt(Double(annotations.count) / Double(targetMax)))))
        let cellLat = latSpan / Double(gridN)
        let cellLng = lngSpan / Double(gridN)
        let latMin   = region.center.latitude  - latSpan / 2
        let lngMin   = region.center.longitude - lngSpan / 2

        // Group annotations by grid cell.
        var cells: [String: [SuperchargerAnnotation]] = [:]
        for ann in annotations {
            let col = Int((ann.supercharger.latitude  - latMin) / cellLat)
            let row = Int((ann.supercharger.longitude - lngMin) / cellLng)
            let key = "\(col)_\(row)"
            cells[key, default: []].append(ann)
        }

        return cells.flatMap { key, group -> [MapClusterItem] in
            if group.count == 1 {
                return [.single(group[0])]
            }
            // Cluster centroid = average position
            let avgLat = group.map(\.supercharger.latitude ).reduce(0, +) / Double(group.count)
            let avgLng = group.map(\.supercharger.longitude).reduce(0, +) / Double(group.count)
            let coord  = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng)
            // Dominant generation = highest kW in the group
            let dominant = group.max(by: { $0.supercharger.maxKilowatts < $1.supercharger.maxKilowatts })?.supercharger.generation ?? .unknown
            return [.cluster(id: "cluster_\(key)", count: group.count, coordinate: coord, generation: dominant)]
        }
    }

    /// Returns a zoomed-in region centred on `coordinate` that's roughly 1/4 the area of `current`.
    public static func zoomedRegion(centeredOn coordinate: CLLocationCoordinate2D,
                                    current: MKCoordinateRegion) -> MKCoordinateRegion {
        MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(
                latitudeDelta:  max(0.05, current.span.latitudeDelta  / 4),
                longitudeDelta: max(0.05, current.span.longitudeDelta / 4)
            )
        )
    }
}
