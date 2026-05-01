import SwiftUI
import SwiftData
import MapKit
import SCData
import SCUI

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var locationService = LocationService()
    @State private var visibleRegion: MKCoordinateRegion = ContentView.defaultRegion

    private static let defaultRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 62, longitude: 10),
        span: MKCoordinateSpan(latitudeDelta: 20, longitudeDelta: 30)
    )

    var body: some View {
        TabView {
            MapView(
                locationService: locationService,
                modelContext: modelContext,
                visibleRegion: $visibleRegion
            )
                .tabItem { Label("Map", systemImage: "map") }

            ListView(
                locationService: locationService,
                modelContext: modelContext,
                visibleRegion: visibleRegion
            )
                .tabItem { Label("List", systemImage: "list.bullet") }

            TripPlannerView()
                .tabItem { Label("Trip", systemImage: "map.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
