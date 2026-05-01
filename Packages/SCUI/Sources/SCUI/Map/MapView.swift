import SwiftUI
import SwiftData
import MapKit
import SCData
import SCDomain

public struct MapView: View {

    @State private var viewModel: MapViewModel
    @State private var mapCameraPosition: MapCameraPosition
    @State private var currentRegion: MKCoordinateRegion = MapView.defaultRegion
    @State private var lastSearchedRegion: MKCoordinateRegion = MapView.defaultRegion
    @State private var showDetailSheet: Bool = false
    @State private var selectedID: String?

    private let locationService: LocationService

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 62, longitude: 10),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 30)
    )

    public init(locationService: LocationService, modelContext: ModelContext) {
        self.locationService = locationService
        _viewModel = State(initialValue: MapViewModel(
            locationService: locationService,
            modelContext: modelContext
        ))
        _mapCameraPosition = State(initialValue: .region(MapView.defaultRegion))
    }

    public var body: some View {
        ZStack {
            mapLayer
            overlayLayer
        }
        // Sync programmatic region changes (e.g. recenter) to camera
        .onChange(of: viewModel.region) { _, newRegion in
            withAnimation { mapCameraPosition = .region(newRegion) }
        }
        // Handle annotation selection
        .onChange(of: selectedID) { _, newID in
            if let id = newID,
               let ann = viewModel.annotations.first(where: { $0.supercharger.id == id }) {
                viewModel.select(ann.supercharger)
                showDetailSheet = true
            }
        }
        .sheet(isPresented: $showDetailSheet, onDismiss: {
            selectedID = nil
            viewModel.clearSelection()
        }) {
            if let sc = viewModel.selectedSupercharger {
                SuperchargerCalloutView(
                    supercharger: sc,
                    userLocation: locationService.currentLocation,
                    onNavigate: { showDetailSheet = false },
                    onDismiss: {
                        showDetailSheet = false
                        selectedID = nil
                        viewModel.clearSelection()
                    }
                )
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
                .presentationBackground(.background)
            }
        }
        .task {
            locationService.requestAuthorisation()
            locationService.startUpdating()
            await viewModel.loadAnnotations(in: currentRegion)
            lastSearchedRegion = currentRegion
        }
    }

    // MARK: - Map layer

    private var mapLayer: some View {
        Map(position: $mapCameraPosition, selection: $selectedID) {
            ForEach(viewModel.annotations, id: \.supercharger.id) { ann in
                Marker(
                    "⚡ \(ann.supercharger.stallCount)",
                    systemImage: GenerationPinStyle.systemImage(for: ann.supercharger.generation),
                    coordinate: ann.coordinate
                )
                .tint(GenerationPinStyle.color(for: ann.supercharger.generation))
                .tag(ann.supercharger.id)
            }
            UserAnnotation()
        }
        .mapStyle(.standard)
        .onMapCameraChange(frequency: .onEnd) { context in
            currentRegion = context.region
            if hasMoved(from: lastSearchedRegion, to: context.region) {
                viewModel.isSearchingThisArea = true
            }
        }
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Overlay layer

    private var overlayLayer: some View {
        VStack(spacing: 0) {
            // "Search this area" pill — top center
            if viewModel.isSearchingThisArea {
                Button {
                    let region = currentRegion
                    Task {
                        await viewModel.searchThisArea(region: region)
                        lastSearchedRegion = region
                    }
                } label: {
                    Label("Search this area", systemImage: "arrow.counterclockwise")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 56)
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(), value: viewModel.isSearchingThisArea)
            }

            Spacer()

            // Bottom bar: filter chips + recenter button
            HStack(alignment: .bottom, spacing: 12) {
                filterChipsRow

                recenterButton
                    .padding(.bottom, 4)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 96) // above tab bar
        }
    }

    // MARK: - Filter chips

    @ViewBuilder
    private var filterChipsRow: some View {
        let hasGenerationFilters = !viewModel.filterCriteria.generations.isEmpty
        let hasStatusFilters = viewModel.filterCriteria.statuses != [.open]
        let hasKwFilter = viewModel.filterCriteria.minimumKilowatts != nil

        if hasGenerationFilters || hasStatusFilters || hasKwFilter {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(
                        Array(viewModel.filterCriteria.generations).sorted(by: { $0.rawValue < $1.rawValue }),
                        id: \.self
                    ) { gen in
                        FilterChip(label: GenerationPinStyle.label(for: gen), isActive: true) {
                            viewModel.filterCriteria.generations.remove(gen)
                            let region = currentRegion
                            Task { await viewModel.loadAnnotations(in: region) }
                        }
                    }

                    if hasStatusFilters {
                        ForEach(
                            Array(viewModel.filterCriteria.statuses).sorted(by: { $0.rawValue < $1.rawValue }),
                            id: \.self
                        ) { status in
                            FilterChip(label: status.rawValue.capitalized, isActive: true) {
                                viewModel.filterCriteria.statuses.remove(status)
                                let region = currentRegion
                                Task { await viewModel.loadAnnotations(in: region) }
                            }
                        }
                    }

                    if let minKw = viewModel.filterCriteria.minimumKilowatts {
                        FilterChip(label: "≥\(minKw) kW", isActive: true) {
                            viewModel.filterCriteria.minimumKilowatts = nil
                            let region = currentRegion
                            Task { await viewModel.loadAnnotations(in: region) }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    // MARK: - Recenter button

    private var recenterButton: some View {
        Button {
            viewModel.recenter()
        } label: {
            Image(systemName: "location.fill")
                .font(.system(size: 18, weight: .semibold))
                .padding(12)
                .background(.regularMaterial, in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func hasMoved(from old: MKCoordinateRegion, to new: MKCoordinateRegion) -> Bool {
        let latDiff = abs(old.center.latitude - new.center.latitude)
        let lngDiff = abs(old.center.longitude - new.center.longitude)
        let threshold = min(old.span.latitudeDelta, new.span.latitudeDelta) * 0.3
        return latDiff > threshold || lngDiff > threshold
    }
}
