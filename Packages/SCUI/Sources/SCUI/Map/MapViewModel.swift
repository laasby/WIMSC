import Foundation
import MapKit
import SwiftData
import SCData
import SCDomain

// MARK: - MKCoordinateRegion Equatable (retroactive)

extension MKCoordinateRegion: @retroactive Equatable {
    public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool {
        lhs.center.latitude == rhs.center.latitude
            && lhs.center.longitude == rhs.center.longitude
            && lhs.span.latitudeDelta == rhs.span.latitudeDelta
            && lhs.span.longitudeDelta == rhs.span.longitudeDelta
    }
}

// MARK: - MapViewModel

@Observable
@MainActor
public final class MapViewModel {

    // MARK: Published state

    public var region: MKCoordinateRegion = MapViewModel.defaultRegion
    public var annotations: [SuperchargerAnnotation] = []
    public var selectedSupercharger: Supercharger?
    public var isSearchingThisArea: Bool = false
    public var filterCriteria: FilterCriteria = .default

    // MARK: Dependencies

    private let locationService: LocationService
    private let modelContext: ModelContext

    // MARK: Init

    public init(locationService: LocationService, modelContext: ModelContext) {
        self.locationService = locationService
        self.modelContext = modelContext
    }

    // MARK: Actions

    /// Load annotations filtered to the visible region and active criteria.
    public func loadAnnotations(in region: MKCoordinateRegion) async {
        let latMin = region.center.latitude  - region.span.latitudeDelta  / 2
        let latMax = region.center.latitude  + region.span.latitudeDelta  / 2
        let lngMin = region.center.longitude - region.span.longitudeDelta / 2
        let lngMax = region.center.longitude + region.span.longitudeDelta / 2

        let descriptor = FetchDescriptor<Supercharger>(
            predicate: #Predicate<Supercharger> { sc in
                sc.latitude  >= latMin && sc.latitude  <= latMax
                    && sc.longitude >= lngMin && sc.longitude <= lngMax
            }
        )

        do {
            let fetched = try modelContext.fetch(descriptor)
            let filtered = SuperchargerFilter.apply(
                fetched,
                criteria: filterCriteria,
                sortBy: .name,
                userLocation: locationService.currentLocation
            )
            annotations = filtered.map { SuperchargerAnnotation(supercharger: $0) }
            isSearchingThisArea = false
        } catch {
            // Non-fatal: leave existing annotations in place
        }
    }

    /// Recenter the map on the user's current location.
    public func recenter() {
        guard let loc = locationService.currentLocation else { return }
        region = MKCoordinateRegion(
            center: loc.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        )
    }

    /// Reload annotations for the given region (user tapped "Search this area").
    public func searchThisArea(region: MKCoordinateRegion) async {
        await loadAnnotations(in: region)
    }

    /// Set the selected supercharger.
    public func select(_ supercharger: Supercharger) {
        selectedSupercharger = supercharger
    }

    /// Clear the current selection.
    public func clearSelection() {
        selectedSupercharger = nil
    }

    // MARK: Private

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 62, longitude: 10),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 30)
    )
}
