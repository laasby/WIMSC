import SwiftUI
import MapKit
import SwiftData
import SCData
import SCDomain

public struct TripPlannerView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var planner: TripPlanner
    @State private var mapCameraPosition: MapCameraPosition = .automatic

    public init() {
        _planner = State(initialValue: TripPlanner(superchargers: []))
    }

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                inputCard

                ZStack(alignment: .bottom) {
                    tripMap
                    if let plan = planner.currentPlan {
                        TripSummaryCard(plan: plan)
                            .padding()
                    }
                }
            }
            .navigationTitle("Trip Planner")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadSites() }
        }
    }

    private var inputCard: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "circle.fill").foregroundStyle(.green).frame(width: 20)
                TextField("Origin", text: $planner.origin)
                    .textFieldStyle(.roundedBorder)
            }
            HStack {
                Image(systemName: "mappin.circle.fill").foregroundStyle(.red).frame(width: 20)
                TextField("Destination", text: $planner.destination)
                    .textFieldStyle(.roundedBorder)
            }
            HStack(spacing: 12) {
                Label("Start: \(planner.startingSoc)%", systemImage: "battery.75")
                    .font(.caption)
                Stepper("", value: $planner.startingSoc, in: 10...100, step: 5)
                    .labelsHidden()
                Spacer()
                Label("Min kW: \(planner.minimumKilowatts == 0 ? "Any" : "\(planner.minimumKilowatts)")", systemImage: "bolt")
                    .font(.caption)
                Menu {
                    Button("Any") { planner.minimumKilowatts = 0 }
                    Button("150 kW+") { planner.minimumKilowatts = 150 }
                    Button("250 kW+") { planner.minimumKilowatts = 250 }
                    Button("325 kW+") { planner.minimumKilowatts = 325 }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                }
            }
            Button {
                Task { await planner.plan() }
            } label: {
                if planner.isPlanning {
                    ProgressView().frame(maxWidth: .infinity)
                } else {
                    Text("Plan Route").frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(planner.origin.isEmpty || planner.destination.isEmpty || planner.isPlanning)
        }
        .padding()
        .background(Color(uiColor: .secondarySystemBackground))
    }

    private var tripMap: some View {
        Map(position: $mapCameraPosition) {
            if let plan = planner.currentPlan {
                ForEach(plan.superchargersNearRoute) { stop in
                    let isRecommended = plan.recommendedStops.contains { $0.id == stop.id }
                    Marker(
                        stop.supercharger.name,
                        systemImage: isRecommended ? "bolt.fill" : "bolt",
                        coordinate: CLLocationCoordinate2D(
                            latitude: stop.supercharger.latitude,
                            longitude: stop.supercharger.longitude
                        )
                    )
                    .tint(isRecommended ? .blue : .gray)
                }
                if let polyline = plan.routePolyline {
                    MapPolyline(polyline)
                        .stroke(.blue, lineWidth: 3)
                }
            }
        }
        .onChange(of: planner.isPlanning) { _, isPlanning in
            if !isPlanning, let polyline = planner.currentPlan?.routePolyline {
                mapCameraPosition = .rect(polyline.boundingMapRect.insetBy(dx: -50000, dy: -50000))
            }
        }
    }

    private func loadSites() async {
        let descriptor = FetchDescriptor<Supercharger>()
        let sites = (try? modelContext.fetch(descriptor)) ?? []
        planner = TripPlanner(superchargers: sites)
    }
}
