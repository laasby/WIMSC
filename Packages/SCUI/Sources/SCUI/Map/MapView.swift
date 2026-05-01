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
    @State private var navigationPath: [Supercharger] = []
    @State private var showDetailSheet: Bool = false
    @State private var selectedID: String?
    @State private var rangeRingCalculator = RangeRingCalculator()
    @State private var showRangeRing: Bool = false

    @Environment(LiveAvailabilityStore.self) private var liveStore
    @Environment(\.teslaIsAuthenticated) private var isAuthenticated
    @Environment(\.teslaSignIn) private var teslaSignIn

    private let locationService: LocationService
    private let regionBinding: Binding<MKCoordinateRegion>?

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 62, longitude: 10),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 30)
    )

    public init(locationService: LocationService, modelContext: ModelContext, visibleRegion: Binding<MKCoordinateRegion>? = nil) {
        self.locationService = locationService
        self.regionBinding = visibleRegion
        _viewModel = State(initialValue: MapViewModel(
            locationService: locationService,
            modelContext: modelContext
        ))
        _mapCameraPosition = State(initialValue: .region(MapView.defaultRegion))
    }

    public var body: some View {
        NavigationStack(path: $navigationPath) {
            ZStack {
                mapLayer
                overlayLayer
            }
            .navigationDestination(for: Supercharger.self) { site in
                SuperchargerDetailView(supercharger: site, locationService: locationService)
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
                        onNavigate: {
                            navigationPath.append(sc)
                            showDetailSheet = false
                        },
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
            .onAppear {
                Task { await viewModel.loadAnnotations(in: currentRegion) }
            }
        }
    }

    // MARK: - Map layer

    private var mapLayer: some View {
        Map(position: $mapCameraPosition, selection: $selectedID) {
            ForEach(viewModel.clusterItems) { item in
                switch item {
                case .single(let sc):
                    let scCoord = CLLocationCoordinate2D(latitude: sc.latitude, longitude: sc.longitude)
                    let live = liveStore.availabilityFor(sc)
                    if let live = live {
                        Annotation(sc.id, coordinate: scCoord, anchor: .bottom) {
                            AvailabilityPinView(
                                stallCount: sc.stallCount,
                                generation: sc.generation,
                                availableStalls: live.availableStalls,
                                totalStalls: live.totalStalls
                            )
                            .onTapGesture { selectedID = sc.id }
                        }
                        .tag(sc.id)
                    } else {
                        Marker(
                            "⚡ \(sc.stallCount)",
                            systemImage: GenerationPinStyle.systemImage(for: sc.generation),
                            coordinate: scCoord
                        )
                        .tint(GenerationPinStyle.color(for: sc.generation))
                        .tag(sc.id)
                    }

                case .cluster(let id, let count, let coord, let generation):
                    Annotation(id, coordinate: coord, anchor: .center) {
                        ClusterMarkerView(count: count, generation: generation) {
                            let zoomed = MapClusterer.zoomedRegion(centeredOn: coord, current: currentRegion)
                            withAnimation { mapCameraPosition = .region(zoomed) }
                        }
                    }
                }
            }
            UserAnnotation()
            if showRangeRing {
                RangeRingOverlay(calculator: rangeRingCalculator)
            }
        }
        .mapStyle(.standard)
        .onMapCameraChange(frequency: .onEnd) { context in
            currentRegion = context.region
            regionBinding?.wrappedValue = context.region
            if hasMoved(from: lastSearchedRegion, to: context.region) {
                viewModel.isSearchingThisArea = true
            }
            if isAuthenticated {
                let center = context.region.center
                let allSites = viewModel.annotations.map { $0.supercharger }
                Task {
                    await liveStore.refresh(
                        latitude: center.latitude,
                        longitude: center.longitude,
                        allSites: allSites
                    )
                }
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

            // Bottom bar: filter chips + recenter + range ring buttons
            HStack(alignment: .bottom, spacing: 12) {
                filterChipsRow

                VStack(spacing: 8) {
                    rangeRingButton
                    recenterButton
                }
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

    // MARK: - Range ring button

    private var rangeRingButton: some View {
        Button {
            showRangeRing.toggle()
            if showRangeRing, let loc = locationService.currentLocation {
                Task {
                    await rangeRingCalculator.calculate(
                        centre: loc,
                        vehicle: nil,
                        currentSoc: 80,
                        allSuperchargers: viewModel.annotations.map(\.supercharger)
                    )
                }
            } else {
                rangeRingCalculator.clear()
            }
        } label: {
            Image(systemName: "waveform.path.ecg")
                .symbolVariant(showRangeRing ? .fill : .none)
                .font(.system(size: 18, weight: .semibold))
                .padding(12)
                .background(.thinMaterial, in: Circle())
                .shadow(radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Range ring")
        .accessibilityHint(showRangeRing ? "Tap to hide the range ring" : "Tap to show the range ring")
        .accessibilityValue(showRangeRing ? "Range ring on" : "Range ring off")
        .accessibilityAddTraits(.isButton)
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
        .accessibilityLabel("Re-center map on my location")
        .accessibilityHint("Moves the map to your current position")
        .accessibilityAddTraits(.isButton)
    }

    // MARK: - Helpers

    private func hasMoved(from old: MKCoordinateRegion, to new: MKCoordinateRegion) -> Bool {
        let latDiff = abs(old.center.latitude - new.center.latitude)
        let lngDiff = abs(old.center.longitude - new.center.longitude)
        let threshold = min(old.span.latitudeDelta, new.span.latitudeDelta) * 0.3
        return latDiff > threshold || lngDiff > threshold
    }
}
