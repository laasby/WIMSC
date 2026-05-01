import Foundation
import CoreLocation
import MapKit
import SCData

// MARK: - Cluster item

/// A single displayable item on the map — either one Supercharger or a cluster of several.
public enum MapClusterItem: Identifiable {
    case single(Supercharger)
    case cluster(id: String, count: Int, coordinate: CLLocationCoordinate2D, generation: ChargerGeneration)

    public var id: String {
        switch self {
        case .single(let sc):               return sc.id
        case .cluster(let id, _, _, _):     return id
        }
    }

    public var coordinate: CLLocationCoordinate2D {
        switch self {
        case .single(let sc):
            return CLLocationCoordinate2D(latitude: sc.latitude, longitude: sc.longitude)
        case .cluster(_, _, let coord, _):
            return coord
        }
    }
}

// MARK: - Clusterer

/// Groups Superchargers into clusters so the map never shows more than `targetMax` items.
public enum MapClusterer {

    /// - Parameters:
    ///   - sites: All Superchargers in the current viewport.
    ///   - region: The current map region (used to compute grid cell sizes).
    ///   - targetMax: Aim for at most this many visible items (default 35).
    public static func cluster(
        sites: [Supercharger],
        region: MKCoordinateRegion,
        targetMax: Int = 35
    ) -> [MapClusterItem] {
        guard !sites.isEmpty else { return [] }

        if sites.count <= targetMax {
            return sites.map { .single($0) }
        }

        let latSpan = region.span.latitudeDelta
        let lngSpan = region.span.longitudeDelta
        let gridN   = max(2, Int(ceil(sqrt(Double(sites.count) / Double(targetMax)))))
        let cellLat = latSpan / Double(gridN)
        let cellLng = lngSpan / Double(gridN)
        let latMin  = region.center.latitude  - latSpan / 2
        let lngMin  = region.center.longitude - lngSpan / 2

        var cells: [String: [Supercharger]] = [:]
        for sc in sites {
            let col = Int((sc.latitude  - latMin) / cellLat)
            let row = Int((sc.longitude - lngMin) / cellLng)
            cells["\(col)_\(row)", default: []].append(sc)
        }

        return cells.flatMap { key, group -> [MapClusterItem] in
            if group.count == 1 { return [.single(group[0])] }
            let avgLat   = group.map(\.latitude ).reduce(0, +) / Double(group.count)
            let avgLng   = group.map(\.longitude).reduce(0, +) / Double(group.count)
            let coord    = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng)
            let dominant = group.max(by: { $0.maxKilowatts < $1.maxKilowatts })?.generation ?? .unknown
            return [.cluster(id: "cluster_\(key)", count: group.count, coordinate: coord, generation: dominant)]
        }
    }

    /// Returns a region zoomed in ~4× centred on `coordinate`.
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
