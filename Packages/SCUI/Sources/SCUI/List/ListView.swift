import SwiftUI
import SwiftData
import MapKit
import CoreLocation
import SCData
import SCDomain

public struct ListView: View {
    // @Query auto-refreshes whenever SwiftData changes (e.g. after remote sync)
    @Query(sort: \Supercharger.name) private var allSites: [Supercharger]

    @State private var searchText: String = ""
    @State private var filterCriteria: FilterCriteria = .default
    @State private var sortOrder: SCDomain.SortOrder = .distance
    @State private var showFilterSheet: Bool = false

    private let locationService: LocationService
    private let visibleRegion: MKCoordinateRegion

    public init(locationService: LocationService, modelContext: ModelContext, visibleRegion: MKCoordinateRegion) {
        self.locationService = locationService
        self.visibleRegion = visibleRegion
    }

    // Sites in the visible map viewport, filtered + sorted
    private var displayedSites: [Supercharger] {
        let latMin = visibleRegion.center.latitude  - visibleRegion.span.latitudeDelta  / 2
        let latMax = visibleRegion.center.latitude  + visibleRegion.span.latitudeDelta  / 2
        let lngMin = visibleRegion.center.longitude - visibleRegion.span.longitudeDelta / 2
        let lngMax = visibleRegion.center.longitude + visibleRegion.span.longitudeDelta / 2

        var inViewport = allSites.filter {
            $0.latitude  >= latMin && $0.latitude  <= latMax &&
            $0.longitude >= lngMin && $0.longitude <= lngMax
        }

        if !searchText.isEmpty {
            inViewport = inViewport.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.city.localizedCaseInsensitiveContains(searchText)
            }
        }

        return SuperchargerFilter.apply(
            inViewport,
            criteria: filterCriteria,
            sortBy: sortOrder,
            userLocation: locationService.currentLocation
        )
    }

    public var body: some View {
        NavigationStack {
            Group {
                if allSites.isEmpty {
                    ProgressView("Loading superchargers…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if displayedSites.isEmpty {
                    ContentUnavailableView(
                        "No Superchargers in View",
                        systemImage: "bolt.slash",
                        description: Text("Pan the map or adjust your filters.")
                    )
                } else {
                    List {
                        Section {
                            ForEach(displayedSites, id: \.id) { site in
                                NavigationLink(value: site) {
                                    SuperchargerRow(
                                        supercharger: site,
                                        userLocation: locationService.currentLocation
                                    )
                                }
                            }
                        } header: {
                            Text("\(displayedSites.count) sites in view")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Superchargers")
            .searchable(text: $searchText, prompt: "Search by name or city")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    SortMenuButton(sortOrder: $sortOrder)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    filterButton
                }
            }
            .sheet(isPresented: $showFilterSheet) {
                FilterSheetView(criteria: $filterCriteria) {
                    showFilterSheet = false
                }
            }
            .navigationDestination(for: Supercharger.self) { site in
                SuperchargerDetailView(supercharger: site, locationService: locationService)
            }
        }
        .background(Color.darkBackground.ignoresSafeArea())
    }

    private var filterButton: some View {
        Button {
            showFilterSheet = true
        } label: {
            Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                .overlay(alignment: .topTrailing) {
                    if filterCriteria != .default {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 8, height: 8)
                            .offset(x: 4, y: -4)
                    }
                }
        }
    }
}
