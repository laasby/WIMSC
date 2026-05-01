import Foundation
import SwiftData
import CoreLocation
import SCData
import SCDomain

@Observable
public final class ListViewModel {

    // MARK: - Public state

    public var sites: [Supercharger] = []
    public var filterCriteria: FilterCriteria = .default
    public var sortOrder: SCDomain.SortOrder = .distance
    public var searchText: String = ""
    public var isLoading: Bool = false

    // MARK: - Dependencies

    public private(set) var locationService: LocationService
    private let modelContext: ModelContext

    // MARK: - Private state

    private var allSites: [Supercharger] = []

    // MARK: - Init

    public init(locationService: LocationService, modelContext: ModelContext) {
        self.locationService = locationService
        self.modelContext = modelContext
    }

    // MARK: - Actions

    /// Fetches all Superchargers from SwiftData then applies current filters/sort.
    public func reload() async {
        isLoading = true
        do {
            let descriptor = FetchDescriptor<Supercharger>()
            allSites = try modelContext.fetch(descriptor)
        } catch {
            allSites = []
        }
        applyFiltersAndSort()
        isLoading = false
    }

    /// Re-applies search text, filter criteria, and sort order to the cached dataset.
    public func applyFiltersAndSort() {
        var results = allSites

        if !searchText.isEmpty {
            results = results.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.city.localizedCaseInsensitiveContains(searchText)
            }
        }

        sites = SuperchargerFilter.apply(
            results,
            criteria: filterCriteria,
            sortBy: sortOrder as SCDomain.SortOrder,
            userLocation: locationService.currentLocation
        )
    }
}
